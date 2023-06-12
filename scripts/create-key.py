from minio import Minio
import urllib3
# from minio.error import ResponseError

endpoint="minio-djw.apps.cluster-lkpkw.lkpkw.sandbox2673.opentlc.com"
access_key="minioadmin"
secret_key="minioadmin"

# New access key details
new_access_key = 'new-access-key'
new_secret_key = 'new-secret-key'
new_password = 'new-password'

try:
    # Initialize MinIO client
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    client = Minio(endpoint, access_key=access_key, secret_key=secret_key, secure=False)

    # Create new access key
    client.add_user(new_access_key, new_secret_key)

    # Set user password
    client.set_user(new_access_key, new_password)

    print(f"Access Key: {new_access_key}")
    print(f"Secret Key: {new_secret_key}")

except:
    print(f"Error creating access key: ")
