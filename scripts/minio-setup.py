import requests
import datetime
import hashlib
import hmac

# MinIO server details
minio_endpoint = "https://minio-cvdemo.apps.ocpbare.davenet.local"
minio_access_key = "minioadmin"
minio_secret_key = "minioadmin"

# Bucket name
bucket_name = "mybucket"

# Construct the endpoint URL
url = f"{minio_endpoint}/{bucket_name}?versioning"

# Current time in UTC
now = datetime.datetime.utcnow()
date = now.strftime("%Y%m%d")
time = now.strftime("%H%M%S")
timestamp = now.strftime("%Y%m%dT%H%M%SZ")

# Headers
headers = {
    "Host": minio_endpoint.split("//")[1],
    "X-Amz-Date": timestamp,
    "Content-Type": "application/xml"
}

# XML payload to enable versioning
xml_payload = """
<VersioningConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Status>Enabled</Status>
</VersioningConfiguration>
"""

# Calculate signature
payload_hash = hashlib.sha256(xml_payload.encode()).hexdigest()
canonical_request = f"PUT\n/{bucket_name}?versioning\n\nhost:{headers['Host']}\nx-amz-date:{headers['X-Amz-Date']}\n\nhost;x-amz-date\n{payload_hash}"
algorithm = "AWS4-HMAC-SHA256"
credential_scope = f"{date}/s3/aws4_request"
string_to_sign = f"{algorithm}\n{timestamp}\n{credential_scope}\n{hashlib.sha256(canonical_request.encode()).hexdigest()}"
signing_key = hmac.new(
    f"AWS4{minio_secret_key}".encode(),
    date.encode(),
    hashlib.sha256
).digest()
signing_key = hmac.new(
    signing_key,
    "s3".encode(),
    hashlib.sha256
).digest()
signing_key = hmac.new(
    signing_key,
    "aws4_request".encode(),
    hashlib.sha256
).digest()
signature = hmac.new(
    signing_key,
    string_to_sign.encode(),
    hashlib.sha256
).hexdigest()

# Authorization header
authorization_header = f"{algorithm} Credential={minio_access_key}/{credential_scope}, SignedHeaders=host;x-amz-date, Signature={signature}"
headers["Authorization"] = authorization_header

# Send the PUT request to enable versioning for the bucket
response = requests.put(url, headers=headers, data=xml_payload)

# Check the response status code
if response.status_code == 200:
    print(f"Bucket '{bucket_name}' created with versioning enabled.")
else:
    print(f"Failed to create bucket '{bucket_name}': {response.text}")
