#!/usr/bin/python3

import sys
from minio import Minio
import urllib3

# Check if the required number of arguments is provided
if len(sys.argv) < 3:
    print("Usage: python 01-create-bucket.py minio_endpoint minio_access_key minio_secret_key")
    sys.exit(1)

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# MinIO server details
minio_endpoint = sys.argv[1]
minio_access_key = sys.argv[2]
minio_secret_key = sys.argv[3]

# Create a Minio client object
minio_client = Minio(minio_endpoint,
                     access_key=minio_access_key,
                     secret_key=minio_secret_key,
                     secure=True,
                     http_client=urllib3.PoolManager(cert_reqs="CERT_NONE"))

# Bucket name
bucket_name = "flyingthings"

try:
    # Check if the bucket already exists
    if minio_client.bucket_exists(bucket_name):
        print(f"Bucket '{bucket_name}' already exists.")
    else:
        # Create the bucket
        minio_client.make_bucket(bucket_name)
        print(f"Bucket '{bucket_name}' created successfully.")
except Exception as err:
    print(f"Failed to create bucket '{bucket_name}': {err}")
