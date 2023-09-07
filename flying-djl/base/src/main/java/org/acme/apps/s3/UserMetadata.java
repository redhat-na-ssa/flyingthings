package org.acme.apps.s3;

import com.fasterxml.jackson.annotation.JsonProperty;

public class UserMetadata {

    @JsonProperty("content-type") 
    public String contentype;
}
