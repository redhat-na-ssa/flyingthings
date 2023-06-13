import botocore.session
import json

# Set the MinIO server URL and access credentials
minio_url = "http://min-mytest.apps.ocpbare.davenet.local"
access_key = "minioadmin"
secret_key = "minioadmin"

# Set the name of the bucket you want to enable versioning for
bucket_name = "flyingthangz"

# Set the versioning configuration
versioning_config = {
    "Status": "Enabled"  # Possible values: "Enabled" or "Suspended"
}

# Create a botocore session and set the access credentials
session = botocore.session.Session()
session.set_credentials(access_key, secret_key)

# Create a client using the session and the MinIO server URL
client = session.create_client('s3', region_name='us-east-1', endpoint_url=minio_url)

# Enable versioning for the bucket
response = client.put_bucket_versioning(Bucket=bucket_name, VersioningConfiguration=versioning_config)

# Check the response status
if response['ResponseMetadata']['HTTPStatusCode'] == 200:
    print("Versioning enabled for the bucket.")
else:
    print(f"Failed to enable versioning. Response: {response}")
