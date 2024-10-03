#!/bin/bash

TMP_DIR=scratch

DEFAULT_USER=${WORKSHOP_USER:-user}
DEFAULT_PASS=${WORKSHOP_PASS:-openshift}
WORKSHOP_NUM=${WORKSHOP_NUM:-25}
# GROUP_ADMINS=workshop-admins

OBJ_DIR=${TMP_DIR}/workshop
HTPASSWD_FILE=${OBJ_DIR}/htpasswd-workshop

# shellcheck disable=SC2120
genpass(){
  < /dev/urandom LC_ALL=C tr -dc _A-Z-a-z-0-9 | head -c "${1:-32}"
}

htpasswd_add_user(){
  TMP_DIR=${TMP_DIR:-scratch}
  HTPASSWD=${1:-${TMP_DIR}/htpasswd-local}
  USERNAME=${2:-admin}
  PASSWORD=${3:-$(genpass 16)}


  echo "
    USERNAME: ${USERNAME}
    PASSWORD: ${PASSWORD}
  "

  touch "${HTPASSWD}"
  sed '/# '"${USERNAME}"'/d' "${HTPASSWD}.txt"
  echo "# ${USERNAME} - ${PASSWORD}" >> "${HTPASSWD}.txt"
  htpasswd -bB -C 10 "${HTPASSWD}" "${USERNAME}" "${PASSWORD}"
}

htpasswd_get_file(){
  HTPASSWD=${1:-"${TMP_DIR}/htpasswd-local"}

  oc -n openshift-config \
    extract secret/"${HTPASSWD##*/}" \
    --keys=htpasswd \
    --to=- > "${HTPASSWD}"
}

htpasswd_set_file(){
  HTPASSWD=${1:-"${TMP_DIR}/htpasswd-local"}

  oc -n openshift-config \
    set data secret/"${HTPASSWD##*/}" \
    --from-file=htpasswd="${HTPASSWD}"
}

workshop_init(){

  # do not delete empty
  [ "${OBJ_DIR}x" = "x" ] && return
  
  rm -rf "${OBJ_DIR}"
  mkdir -p "${OBJ_DIR}"
}

workshop_create_admin(){
  # get htpasswd file
  htpasswd_get_file "${HTPASSWD_FILE}"

  # setup admin user
  htpasswd_add_user "${HTPASSWD_FILE}" admin
}

workshop_create_users(){
  TOTAL=${1:-25}
  LIST=$(eval echo "{0..${TOTAL}}")

  # setup workshop users
  # shellcheck disable=SC2068
  for num in ${LIST[@]}
  do
    # create login hashes
    htpasswd_add_user "${HTPASSWD_FILE}" "${DEFAULT_USER}${num}" "${DEFAULT_PASS}${num}"
    # workshop_add_user_to_group "${DEFAULT_USER}${num}" "${DEFAULT_GROUP}"

    # create user project from template
    cp -a workshop/instance "${OBJ_DIR}/${DEFAULT_USER}${num}"
    sed -i 's/user0/'"${DEFAULT_USER}${num}"'/g' "${OBJ_DIR}/${DEFAULT_USER}${num}/"*.yaml
    sed -i 's@- ../../components@- ../../../components@g' "${OBJ_DIR}/${DEFAULT_USER}${num}/"kustomization.yaml

    echo "Creating: ${DEFAULT_USER}${num}"
    oc apply -k "${OBJ_DIR}/${DEFAULT_USER}${num}"
  done

  # update htpasswd in cluster
  htpasswd_set_file "${HTPASSWD_FILE}"

}

setup_user_auth(){

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
              "name": "'"$SECRET_NAME"'"
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

workshop_init