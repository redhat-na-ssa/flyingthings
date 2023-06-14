import sys
import boto3
from botocore.exceptions import ClientError
import urllib3

# Check if the required number of arguments is provided
if len(sys.argv) < 4:
    print("Usage: python 01-enable-versioning.py minio_endpoint minio_access_key minio_secret_key")
    sys.exit(1)

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# MinIO server details
minio_endpoint = sys.argv[1]
minio_access_key = sys.argv[2]
minio_secret_key = sys.argv[3]

# Bucket name
bucket_name = "flyingthings"

# Create a session using the MinIO access key and secret key
session = boto3.Session(
    aws_access_key_id=minio_access_key,
    aws_secret_access_key=minio_secret_key
)

# Create a client for the MinIO server
minio_client = session.client(
    "s3",
    endpoint_url="https://" + minio_endpoint,
    verify=False
)

try:
    # Enable versioning for the bucket
    minio_client.put_bucket_versioning(
        Bucket=bucket_name,
        VersioningConfiguration={
            "Status": "Enabled"
        }
    )
    print(f"Versioning enabled for bucket '{bucket_name}'.")
except ClientError as e:
    print(f"Failed to enable versioning for bucket '{bucket_name}': {e}")