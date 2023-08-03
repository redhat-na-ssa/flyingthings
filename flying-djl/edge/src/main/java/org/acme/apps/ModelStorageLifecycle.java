package org.acme.apps;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class ModelStorageLifecycle {

    private static Logger log = Logger.getLogger(ModelStorageLifecycle.class);

    @ConfigProperty(name = "org.acme.djl.model.zip.path")
    String modelZipPath;

    @ConfigProperty(name = "org.acme.djl.model.zip.name")
    String modelZipName;

    @PostConstruct
    public void start() {

    }

    public boolean unzipModel(String targetDirToUnzipTo ){
        InputStream fStream = null;
        try {
            File modelZipFile = new File(this.modelZipPath, this.modelZipName);
            fStream = new FileInputStream(modelZipFile);
            return unzipModel(fStream, targetDirToUnzipTo);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean unzipModel(InputStream stream, String targetDirToUnzipTo){
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
