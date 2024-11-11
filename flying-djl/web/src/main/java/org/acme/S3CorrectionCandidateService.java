package org.acme;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

import io.minio.BucketExistsArgs;
import io.minio.MinioClient;
import io.minio.ObjectWriteResponse;
import io.minio.ObjectWriteArgs.Builder;
import io.minio.PutObjectArgs;
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
public class S3CorrectionCandidateService {

    private static Logger log = Logger.getLogger(S3CorrectionCandidateService.class);

    @Inject
    @MinioQualifier("rht")
    MinioClient mClient;

    @ConfigProperty(name = "com.rht.na.gtm.s3.bucket.name")
    String bucketName;

    @ConfigProperty(name = "com.rht.na.gtm.s3.correction.candidate.subfolder.name", defaultValue = AppUtils.MODELS_CORRECTIVE_CANDIDATES)
    String correctiveCandidateSubFolderName;

    @ConfigProperty(name = "com.rht.na.gtm.s3.putWithTags", defaultValue="True")
    private boolean putWithTags;

    @ConfigProperty(name = "com.rht.na.gtm.s3.minIOobjectTags")
    protected String minIOobjectTags;

    @ConfigProperty(name = "com.rht.na.gtm.s3.printMinIOresponseHeaders", defaultValue="False")
    protected boolean printResponseHeaders;

    boolean bucketExists;

    @PostConstruct
    public void start() {
        
        
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

    public boolean doesBucketExist() {
        return bucketExists;
    }


    public boolean postToBucket(String body, String objectName){
        ObjectWriteResponse owResponse = null;
        InputStream iStream = null;
        boolean response = true;
        try {

            // https://min.io/docs/minio/linux/developers/java/API.html#putobject-putobjectargs-args
            // Upload input stream with headers and user metadata.
            Map<String, String> headers = new HashMap<>();
            Map<String, String> userMetadata = new HashMap<>();
            iStream = new ByteArrayInputStream(body.getBytes());

            Builder bObj = PutObjectArgs.builder().bucket(bucketName).object(correctiveCandidateSubFolderName+"/"+objectName).stream(iStream, body.getBytes().length, -1)
            .headers(headers)
            .userMetadata(userMetadata);

            PutObjectArgs pOArgs;
            if(putWithTags) {
                Map<String, String> tags = new HashMap<String, String>();
                String[] tagsArray = minIOobjectTags.split(",");
                for(String pairs : tagsArray){
                    String[] pair = pairs.split(":");
                    tags.put(pair[0], pair[1]);
                }
                log.infov("uploading {0} to S3 bucket {1} with # of tags: {2}", objectName, correctiveCandidateSubFolderName, tags.size());
                pOArgs = (PutObjectArgs) bObj.tags(tags).build();
            } else {
                log.infov("uploading {0} object to S3 bucket {1} with zero tags", objectName, correctiveCandidateSubFolderName);
                pOArgs = (PutObjectArgs) bObj.build();
            }

            owResponse = mClient.putObject( pOArgs);
            
        } catch (InvalidKeyException | ErrorResponseException | InsufficientDataException | InternalException
        | IllegalArgumentException | IOException | InvalidResponseException | NoSuchAlgorithmException | ServerException | XmlParserException e1) {
            e1.printStackTrace();
            response = false;
        }finally{
            if(iStream != null)
            try {
                iStream.close();
            } catch (IOException e1) {
                e1.printStackTrace();
            }
        }
        
        if(printResponseHeaders && (owResponse != null)){
            Set<String> hNames = owResponse.headers().names();
            for(String key : hNames){
                log.infov("return header = {0} , {1}", key, owResponse.headers().get(key));
            }
        }
        return response;

    }
    
}
