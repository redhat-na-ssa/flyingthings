import requests
import json
from aws_requests_auth.aws_auth import AWSRequestsAuth

# MinIO server details
minio_endpoint = "minio-s3-ml-demo.apps.ocp4.davenet.local"
minio_region = "us-east-1"  # MinIO typically uses 'us-east-1' for AWS4 signature
admin_access_key = "minioadmin"  # Replace with your MinIO access key
admin_secret_key = "minioadmin"  # Replace with your MinIO secret key

# Create an AWS V4 auth object for MinIO
auth = AWSRequestsAuth(
    aws_access_key=admin_access_key,
    aws_secret_access_key=admin_secret_key,
    aws_host=minio_endpoint,
    aws_region=minio_region,
    aws_service='s3'  # 's3' for MinIO
)

# Disable SSL warnings for self-signed certificates
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Function to create a user
def create_user(user_id, password):
    url = f"https://{minio_endpoint}/minio/admin/v3/add-user?accessKey={user_id}&secretKey={password}"
    response = requests.put(url, auth=auth, verify=False)
    if response.status_code == 200:
        print(f"User {user_id} created successfully.")
    else:
        print(f"Failed to create user {user_id}. Response: {response.text}")

# Function to create a bucket
def create_bucket(bucket_name):
    url = f"https://{minio_endpoint}/{bucket_name}/"
    response = requests.put(url, auth=auth, verify=False)
    if response.status_code == 200:
        print(f"Bucket {bucket_name} created successfully.")
    else:
        print(f"Failed to create bucket {bucket_name}. Response: {response.text}")

# Function to set bucket policy
def set_bucket_policy(bucket_name, user_id):
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"AWS": [f"arn:aws:iam:::user/{user_id}"]},
                "Action": ["s3:GetObject", "s3:PutObject"],
                "Resource": [f"arn:aws:s3:::{bucket_name}/*"]
            }
        ]
    }
    url = f"https://{minio_endpoint}/minio/admin/v3/set-policy"
    data = {
        "bucket": bucket_name,
        "name": f"{user_id}-policy",
        "policy": json.dumps(policy)
    }
    response = requests.put(url, auth=auth, json=data, verify=False)
    if response.status_code == 200:
        print(f"Policy for bucket {bucket_name} set successfully.")
    else:
        print(f"Failed to set policy for bucket {bucket_name}. Response: {response.text}")

# Create users and corresponding buckets
for i in range(1, 11):
    user_id = f"user{i:02d}"
    password = f"redhat{i:02d}"
    bucket_name = f"{user_id}-bucket"

    # Create the user
    create_user(user_id, password)

    # Create the bucket
    create_bucket(bucket_name)

    # Set the policy for the bucket
    set_bucket_policy(bucket_name, user_id)