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

    public boolean pullAndSaveModelZip(String fullModelPathAndName){
        FileInputStream fis = null;
        File targetModelZipFile = null;
        String modelName = fullModelPathAndName;
        if(fullModelPathAndName.contains("/")){
          modelName=fullModelPathAndName.substring(fullModelPathAndName.indexOf("/"));
        }
        try {
            targetModelZipFile = new File(this.modelZipPath, modelName);

            InputStream stream =
                mClient.getObject(GetObjectArgs.builder().bucket(bucketName).object(fullModelPathAndName).build());
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
    
}
