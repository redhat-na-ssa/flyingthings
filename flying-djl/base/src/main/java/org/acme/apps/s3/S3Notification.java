package org.acme.apps.s3; 
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.ArrayList;

public class S3Notification {

    @JsonProperty("EventName") 
    public String eventName;
    @JsonProperty("Key") 
    public String key;
    @JsonProperty("Records") 
    public ArrayList<Record> records;
}
