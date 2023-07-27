package org.acme.apps.s3;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import org.acme.AppUtils;
import org.apache.commons.io.FileUtils;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

import io.minio.BucketExistsArgs;
import io.minio.GetObjectArgs;
import io.minio.MinioClient;
import io.minio.errors.ErrorResponseException;
import io.minio.errors.InsufficientDataException;
import io.minio.errors.InternalException;
import io.minio.errors.InvalidResponseException;
import io.minio.errors.ServerException;
import io.minio.errors.XmlParserException;
import io.quarkiverse.minio.client.MinioQualifier;
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

@ApplicationScoped
public class S3ModelLifecycle {

    private static Logger log = Logger.getLogger(S3ModelLifecycle.class);

    @Inject
    @MinioQualifier("rht")
    MinioClient mClient;

    @ConfigProperty(name = "com.rht.na.gtm.s3.bucket.name", defaultValue = AppUtils.NA)
    String bucketName;

    @ConfigProperty(name = "org.acme.djl.model.zip.path")
    String modelZipPath;    

    @PostConstruct
    public void start() {
        
        boolean bucketExists;
        try {
            bucketExists = mClient.bucketExists(BucketExistsArgs.builder().bucket(bucketName).build());
            if(!bucketExists) {
                throw new RuntimeException("Following bucket must already be created in: "+bucketName);
            }else {
                log.infov("S3 Bucket already exists: {0}", bucketName);
            }
        } catch (InvalidKeyException | ErrorResponseException | InsufficientDataException | InternalException
                | InvalidResponseException | NoSuchAlgorithmException | ServerException | XmlParserException
                | IllegalArgumentException | IOException e) {
            e.printStackTrace();
        }

    }

    public boolean pullAndSaveModelZip(String modelName){
        FileInputStream fis = null;
        File targetModelZipFile = null;
        try {
            targetModelZipFile = new File(this.modelZipPath, modelName);

            // Get input stream to have content of 'my-objectname' from 'my-bucketname'
            InputStream stream =
                mClient.getObject(GetObjectArgs.builder().bucket(bucketName).object(modelName).build());
                FileUtils.copyInputStreamToFile(stream, targetModelZipFile);

        } catch (IOException | InvalidKeyException | ErrorResponseException | InsufficientDataException | InternalException | InvalidResponseException | NoSuchAlgorithmException | ServerException | XmlParserException | IllegalArgumentException e) {
            log.errorv("pullAndSaveModelZip() unable to write zip to: {0}", targetModelZipFile.getAbsolutePath());
            e.printStackTrace();
            return false;
        }finally{
            if(fis != null)
                try {
                    fis.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
        }
        return true;
    }

    /*
     * given a modelName, retrieves a model zip file and unpacks onto file system.
     * returns boolean success or failure
     */
    public boolean pullAndUnzipModel(String modelName){

        ZipInputStream zis = null;
        try {
            // Get input stream to have content of 'my-objectname' from 'my-bucketname'
            InputStream stream =
                mClient.getObject(GetObjectArgs.builder().bucket(bucketName).object(modelName).build());
      
            // Read the input stream and print to the console till EOF.
            // https://www.baeldung.com/java-compress-and-uncompress
            byte[] buffer = new byte[1024];
            zis = new ZipInputStream(stream);
            ZipEntry zipEntry = zis.getNextEntry();
            File destDir = new File(this.modelZipPath);
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
            log.infov("pullAndSaveModel() just refreshed model in {0}", this.modelZipPath);
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

    public static File newFile(File destinationDir, ZipEntry zipEntry) throws IOException {
        File destFile = new File(destinationDir, zipEntry.getName());
    
        String destDirPath = destinationDir.getCanonicalPath();
        String destFilePath = destFile.getCanonicalPath();
    
        if (!destFilePath.startsWith(destDirPath + File.separator)) {
            throw new IOException("Entry is outside of the target dir: " + zipEntry.getName());
        }
    
        return destFile;
    }   
    
}
