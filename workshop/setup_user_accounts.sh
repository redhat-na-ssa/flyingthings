#!/bin/bash

mkdir scratch
 # Create the htpasswd file for the users and add the admin user
htpasswd -c -B -b scratch/users.htpasswd admin redhatadmin

# Add the workshop users starting from user01 to user10 with the password redhat + the user number
for i in $(seq -w 1 10); do htpasswd -b scratch/users.htpasswd user$i redhat$i; done

# Create the secret with the htpasswd file
oc create secret generic htpasswd-secret --from-file=htpasswd=scratch/users.htpasswd -n openshift-config

# Variables
HTPASSWD_FILE="scratch/users.htpasswd"
SECRET_NAME="htpasswd-secret"
NAMESPACE="openshift-config"

# Create the htpasswd secret (if not created already)
oc create secret generic $SECRET_NAME --from-file=htpasswd=$HTPASSWD_FILE -n $NAMESPACE --dry-run=client -o yaml | oc apply -f -

# Get the current OAuth configuration
OAUTH_CONFIG=$(oc get oauth cluster -o json)

# Check if htpasswd provider already exists
if echo "$OAUTH_CONFIG" | grep -q '"name": "htpasswd"'; then
  echo "htpasswd identity provider already exists in the OAuth configuration."
  exit 0
fi

# Add htpasswd provider to the current configuration
UPDATED_OAUTH_CONFIG=$(echo "$OAUTH_CONFIG" | jq '.spec.identityProviders += [{
    "name": "htpasswd",
    "mappingMethod": "claim",
    "type": "HTPasswd",
    "htpasswd": {
        "fileData": {
            "name": "'$SECRET_NAME'"
        }
    }
}]')

# Apply the updated OAuth configuration
echo "$UPDATED_OAUTH_CONFIG" | oc apply -f -

# Verify the OAuth configuration was updated
oc get oauth cluster -o json | jq '.spec.identityProviders'
