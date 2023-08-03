package org.acme.apps.s3;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import org.acme.AppUtils;
import org.acme.apps.ModelStorageLifecycle;
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

/* Related:  DJL Serving has an S3CacheEngine:
 *      https://github.com/deepjavalibrary/djl-serving/blob/master/plugins/cache/src/main/java/ai/djl/serving/cache/S3CacheEngine.java
 */
@ApplicationScoped
public class S3ModelLifecycle {

    private static Logger log = Logger.getLogger(S3ModelLifecycle.class);

    @Inject
    @MinioQualifier("rht")
    MinioClient mClient;

    @Inject
    ModelStorageLifecycle modelSL;

    @ConfigProperty(name = "com.rht.na.gtm.s3.bucket.name", defaultValue = AppUtils.NA)
    String bucketName;

    @ConfigProperty(name = "org.acme.djl.model.zip.path")
    String modelZipPath;

    @ConfigProperty(name = "org.acme.djl.model.temp.unzip.path", defaultValue="/tmp/unzippedModels")
    String tempUnzippedModelPath;

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

            String tempUnzippedModelPath = ""+modelName;
            boolean success = modelSL.unzipModel(stream, tempUnzippedModelPath);
            log.infov("pullAndSaveModelZip() successfully unzipped model to {0} = {1}", tempUnzippedModelPath, success);

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

        // Get input stream to have content of 'my-objectname' from 'my-bucketname'
        InputStream stream;
        try {
            stream = mClient.getObject(GetObjectArgs.builder().bucket(bucketName).object(modelName).build());
            return modelSL.unzipModel(stream, null);
        } catch (InvalidKeyException | ErrorResponseException | InsufficientDataException | InternalException
                | InvalidResponseException | NoSuchAlgorithmException | ServerException | XmlParserException
                | IllegalArgumentException | IOException e) {
            e.printStackTrace();
            return false;
        }
    }  
    
}
