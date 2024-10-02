#!/bin/bash

TMP_DIR=scratch

DEFAULT_USER=${WORKSHOP_USER:-user}
DEFAULT_PASS=${WORKSHOP_PASS:-openshift}

WORKSHOP_NUM=${WORKSHOP_NUM:-25}
WORKSHOP_HTPASSWD=htpasswd-workshop

GROUP_ADMINS=workshop-admins

OBJ_DIR=${TMP_DIR}/workshop

HTPASSWD_FILE=${OBJ_DIR}/htpasswd-workshop

mkdir -p "${OBJ_DIR}"

workshop_create_users(){
  TOTAL=${1:-25}
  LIST=$(eval echo "{0..${TOTAL}}")

  for num in ${LIST[@]}
  do

    # create login things
    # htpasswd_add_user "${DEFAULT_USER}${num}" "${DEFAULT_PASS}${num}" "${HTPASSWD_FILE}"
    # workshop_add_user_to_group "${DEFAULT_USER}${num}" "${DEFAULT_GROUP}"

    # create users objs from template
    cp -a workshop/instance "${OBJ_DIR}/${DEFAULT_USER}${num}"
    sed -i 's/user0/'"${DEFAULT_USER}${num}"'/g' "${OBJ_DIR}/${DEFAULT_USER}${num}/"*.yaml
    sed -i 's@- ../../components@- ../../../components@g' "${OBJ_DIR}/${DEFAULT_USER}${num}/"kustomization.yaml

    echo "Creating: ${USERNAME}${num}"
    oc apply -k "${OBJ_DIR}/${DEFAULT_USER}${num}"
  done

  # update htpasswd in cluster
  # htpasswd_set_file "${HTPASSWD_FILE}"

}

workshop_setup_user_assets(){
  START=${START:-1}
  END=${END:-10}

  # Grant access to all the CV training image streams
  for num in $(seq -f "%02g" $START $END); do
    oc adm policy add-role-to-user view ${USERNAME}${num} -n ml-demo
    oc adm policy add-role-to-user system:image-puller ${USERNAME}${num} -n ml-demo
    oc tag ml-demo/yolo-api:latest ${USERNAME}${num}/yolo-api:latest
    oc tag ml-demo/yolo-api:latest ${USERNAME}${num}/model-yolo:latest
  done

  for i in $(seq -f "%02g" $START $END); do
    echo "Current user: ${USERNAME}${num}"
    oc project ${USERNAME}${num}
    workshop/01-setup-pipelines.sh
    oc apply -k gitops/02-workshop-user-components
  done
}

setup_pipelines(){
  # apply pipeline objects
  oc apply -f ../pipelines/tasks
  oc apply -f ../pipelines/manifests
}

setup_user_project(){
  # Loop through the range of users
  for i in $(seq -f "%02g" $START $END)
  do
      USERNAME="user${num}"

      echo "Creating project for ${USERNAME}..."
      
      # Create a new project/namespace for the user
      oc new-project ${USERNAME}

      # Assign admin role to the user for their project
      oc adm policy add-role-to-user admin ${USERNAME} -n ${USERNAME}

  done

  echo "All users and quotas have been successfully created."
}

setup_user_auth(){

  # Create the htpasswd file for the users and add the admin user
  htpasswd -c -B -b scratch/users.htpasswd admin redhatadmin

  # Add the workshop users starting from user01 to user10 with the password redhat + the user number
  for i in $(seq -f "%02g" $START $END); do htpasswd -b scratch/users.htpasswd user$i redhat$i; done

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

}

workshop_clean(){
  oc delete project -l owner=workshop
}
