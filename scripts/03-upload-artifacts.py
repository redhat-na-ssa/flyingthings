#!/usr/bin/python3
from minio import Minio
import sys
import os
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

# Directory path
directory_path = "../artifacts"

# Create a Minio client object
minio_client = Minio(minio_endpoint,
                     access_key=minio_access_key,
                     secret_key=minio_secret_key,
                     secure=True,
                     http_client=urllib3.PoolManager(cert_reqs="CERT_NONE"))

try:
    # Check if the bucket already exists
    if not minio_client.bucket_exists(bucket_name):
        minio_client.make_bucket(bucket_name)
        print(f"Bucket '{bucket_name}' created successfully.")

    # Upload files in the directory to the bucket
    for file_name in os.listdir(directory_path):
        file_path = os.path.join(directory_path, file_name)
        with open(file_path, "rb") as file_data:
            minio_client.put_object(bucket_name, file_name, file_data, length=os.stat(file_path).st_size)
            print(f"File '{file_name}' uploaded successfully to bucket '{bucket_name}'.")
except Exception as err:
    print(f"Failed to upload files to bucket '{bucket_name}': {err}")
