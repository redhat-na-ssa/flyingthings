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

# Upload files from the 'artifacts' directory
artifacts_directory = "artifacts"

for root, dirs, files in os.walk(artifacts_directory):
    for file in files:
        local_path = os.path.join(root, file)
        object_name = os.path.relpath(local_path, artifacts_directory)

        try:
            minio_client.fput_object(bucket_name, object_name, local_path)
            print(f"Uploaded '{object_name}' to bucket '{bucket_name}'.")
        except S3Error as e:
            print(f"Error uploading '{object_name}' to bucket '{bucket_name}': {e}")
