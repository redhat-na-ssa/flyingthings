#!/usr/bin/python3

import urllib3
import sys
from urllib3.exceptions import InsecureRequestWarning
from minio import Minio
from minio.commonconfig import Tags

# Check if the required number of arguments is provided
if len(sys.argv) < 4:
    print("Usage: python 01-enable-versioning.py minio_endpoint minio_access_key minio_secret_key")
    sys.exit(1)

# MinIO server details
minio_endpoint = sys.argv[1]
minio_access_key = sys.argv[2]
minio_secret_key = sys.argv[3]

# Disable SSL verification warning
urllib3.disable_warnings(InsecureRequestWarning)

# MinIO bucket information
bucket_name = 'flyingthings'
tag_key = 'build'
tag_value = '0.0'

# Initialize MinIO client with SSL verification disabled
client = Minio(minio_endpoint, access_key=minio_access_key, secret_key=minio_secret_key, secure=True, http_client=urllib3.PoolManager(cert_reqs='CERT_NONE'))

# Get all objects in the bucket
objects = client.list_objects(bucket_name, recursive=True)


# Loop through each object and set tags
for obj in objects:
    object_name = obj.object_name
    tags = Tags(for_object=True)
    tags[tag_key] = tag_value    
    client.set_object_tags(bucket_name, object_name, tags)

print("Tags applied to all objects in the bucket.")
