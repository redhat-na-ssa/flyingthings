package org.acme.apps.s3;

import com.fasterxml.jackson.annotation.JsonProperty;

public class ResponseElements{


    @JsonProperty("content-length") 
    public String contentlength;

    @JsonProperty("x-amz-id-2") 
    public String xamzid2;

    @JsonProperty("x-amz-request-id") 
    public String xamzrequestid;

    @JsonProperty("x-minio-deployment-id") 
    public String xminiodeploymentid;
    
    @JsonProperty("x-minio-origin-endpoint") 
    public String xminiooriginendpoint;
}
