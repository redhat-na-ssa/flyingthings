from minio import Minio
from minio.error import S3Error
import os
import urllib3

# MinIO server details
minio_endpoint = "min-mytest.apps.ocpbare.davenet.local"
minio_access_key = "minioadmin"
minio_secret_key = "minioadmin"

# Initialize MinIO client
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
minio_client = Minio(minio_endpoint, access_key=minio_access_key, secret_key=minio_secret_key, secure=False)

# Bucket name
bucket_name = "flyingthangz"

# Check if bucket exists
bucket_exists = minio_client.bucket_exists(bucket_name)

if bucket_exists:
    print(f"Bucket '{bucket_name}' already exists.")
else:
    # Create bucket
    try:
        minio_client.make_bucket(bucket_name)
        print(f"Bucket '{bucket_name}' created successfully.")
    except S3Error as e:
        print(f"Error creating bucket '{bucket_name}': {e}")