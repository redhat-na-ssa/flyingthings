# minio_endpoint = "minio-djw.apps.cluster-lkpkw.lkpkw.sandbox2673.opentlc.com"

from minio import Minio
from minio.error import S3Error
import os
import urllib3

# MinIO server details
minio_endpoint = "minio-djw.apps.cluster-lkpkw.lkpkw.sandbox2673.opentlc.com"
minio_access_key = "minioadmin"
minio_secret_key = "minioadmin"

# Initialize MinIO client
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
minio_client = Minio(minio_endpoint, access_key=minio_access_key, secret_key=minio_secret_key, secure=True)

# Bucket name
bucket_name = "flyingthings"

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

    # Enable versioning for the bucket
    versioning_config = {
        "Status": "Enabled"
    }

    try:
        minio_client.set_bucket_versioning(bucket_name, versioning_config)
        print(f"Versioning enabled for bucket '{bucket_name}'.")
    except S3Error as e:
        print(f"Error enabling versioning for bucket '{bucket_name}': {e}")

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

# # Create new access key and secret
# access_key = "JREIgskWZouMuWI4ZAf4"
# secret_key = "abc-123333"

# try:
#     minio_client.set_user(access_key, secret_key)
#     print(f"Access key '{access_key}' created successfully.")
# except:
#     print(f"Error creating access key '{access_key}': {e}")