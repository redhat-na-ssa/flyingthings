package org.acme.apps.s3;

import java.util.Date;

public class Record{
    public String eventVersion;
    public String eventSource;
    public String awsRegion;
    public Date eventTime;
    public String eventName;
    public UserIdentity userIdentity;
    public RequestParameters requestParameters;
    public ResponseElements responseElements;
    public S3 s3;
    public Source source;
}
