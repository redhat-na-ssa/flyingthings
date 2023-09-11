package org.acme.apps;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import org.acme.AppUtils;
import org.apache.commons.io.FileUtils;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class ModelStorageLifecycle {

    private static final String ZIP_SUFFIX=".zip";
    private static final String RETURN_CHAR="\n";
    private static Logger log = Logger.getLogger(ModelStorageLifecycle.class);

    @ConfigProperty(name = "org.acme.djl.model.zip.path", defaultValue = AppUtils.NA)
    String modelZipPath;

    @ConfigProperty(name = "org.acme.djl.model.temp.unzip.path", defaultValue="/tmp/unzippedModels")
    String targetBaseDirToUnzipTo;

    @ConfigProperty(name = "org.acme.djl.model.zip.name", defaultValue = AppUtils.NA)
    String modelZipName;

    @ConfigProperty(name = "org.acme.djl.model.synset.name", defaultValue = "synset.txt")
    String synsetFileName;

    List<String> modelClassesList = new ArrayList<String>();

    @PostConstruct
    public void start() {
    }

    public boolean unzipModelAndRefreshModelClassList(){
        InputStream fStream = null;
        try {
            String zipFilePrefix = modelZipName.substring(0, modelZipName.indexOf(ZIP_SUFFIX));
            String targetDirToUnzipTo = targetBaseDirToUnzipTo+"/"+zipFilePrefix;

            File modelZipFile = new File(this.modelZipPath, this.modelZipName);
            fStream = new FileInputStream(modelZipFile);
            boolean success = unzipModel(fStream, targetDirToUnzipTo );
            
            File classesFile = new File(targetDirToUnzipTo, synsetFileName);
            String classesContent = FileUtils.readFileToString(classesFile, StandardCharsets.UTF_8);
            String[] strSplit = classesContent.split(RETURN_CHAR);
            modelClassesList.clear();
            for(int x= 0; x < strSplit.length; x++){
                modelClassesList.add(strSplit[x]);
            }
            log.infov("unzipModelAndRefreshModelClassList() successfully unzipped model to {0}; # of model classes = {1}", targetDirToUnzipTo, modelClassesList.size());

            return success;
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean modelClassesContains(String className){
        return modelClassesList.contains(className);
    }

    private boolean unzipModel(InputStream stream, String targetDirToUnzipTo){
        ZipInputStream zis = null;
        try {
      
            // Read the input stream and print to the console till EOF.
            // https://www.baeldung.com/java-compress-and-uncompress
            byte[] buffer = new byte[1024];
            zis = new ZipInputStream(stream);
            ZipEntry zipEntry = zis.getNextEntry();
            File destDir = new File(targetDirToUnzipTo);
            while(zipEntry != null){
                File newFile = newFile(destDir, zipEntry);
                if (zipEntry.isDirectory()) {
                    if (!newFile.isDirectory() && !newFile.mkdirs()) {
                        throw new IOException("Failed to create directory " + newFile);
                    }
                } else {
                    // fix for Windows-created archives
                    File parent = newFile.getParentFile();
                    if (!parent.isDirectory() && !parent.mkdirs()) {
                        throw new IOException("Failed to create directory " + parent);
                    }
            
                    // write file content
                    FileOutputStream fos = new FileOutputStream(newFile);
                    int len;
                    while ((len = zis.read(buffer)) > 0) {
                        fos.write(buffer, 0, len);
                    }
                    fos.close();
                }
                zipEntry = zis.getNextEntry();
            }
            log.infov("unzipModel() just refreshed model in {0}", this.modelZipPath);
            return true;
        }catch(Exception x){
            x.printStackTrace();
            return false;
        }finally{
            if(zis != null)
                try {
                    zis.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
        }
    }

    private static File newFile(File destinationDir, ZipEntry zipEntry) throws IOException {
        File destFile = new File(destinationDir, zipEntry.getName());
    
        String destDirPath = destinationDir.getCanonicalPath();
        String destFilePath = destFile.getCanonicalPath();
    
        if (!destFilePath.startsWith(destDirPath + File.separator)) {
            throw new IOException("Entry is outside of the target dir: " + zipEntry.getName());
        }
    
        return destFile;
    }   
    
}
