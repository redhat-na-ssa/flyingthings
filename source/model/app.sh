#!/bin/sh
set -x

MINIO_CLIENT_URL="${MINIO_CLIENT_URL:-https://dl.min.io/client/mc/release/linux-amd64}"
MINIO_CFG="${MINIO_CFG:-miniocfg}"
MINIO_REMOTE="${MINIO_REMOTE:-remote}"
MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://minio:9000}"
MINIO_ACCESSKEY="${MINIO_ACCESSKEY:-minioadmin}"
MINIO_SECRETKEY="${MINIO_SECRETKEY:-minioadmin}"
MINIO_BUCKET="${MINIO_BUCKET:-project}"

WEIGHTS="${WEIGHTS:-flyingthings.pt}"
SIMPLEVIS_DATA="${SIMPLEVIS_DATA:-/opt/app-root/src/simplevis-data}"

download_mc(){
  curl "${MINIO_CLIENT_URL}/mc" -o ./mc
  chmod +x ./mc
}

minio_setup_client(){
  [ ! -x ./mc ] && download_mc
  ./mc --insecure --config-dir "${MINIO_CFG}" config host \
    add "${MINIO_REMOTE}" "${MINIO_ENDPOINT}" "${MINIO_ACCESSKEY}" "${MINIO_SECRETKEY}"
}

minio_copy(){
  [ ! -d "${MINIO_CFG}" ] && minio_setup_client
  local SOURCE="${1}"
  local DEST="${2}"
  ./mc --insecure --config-dir "${MINIO_CFG}" cp "${SOURCE}" "${DEST}"
}

cd $SIMPLEVIS_DATA

minio_setup_client

# If BASE_MODEL is pretrained, use the pretrained pytorch model file
allowed_models=("yolov8n.pt" "yolov5s.pt")
if [[ " ${allowed_models[@]} " =~ " ${BASE_MODEL} " ]]; then
  echo "Using pretrained model..."
  minio_copy "${MINIO_REMOTE}/${MINIO_BUCKET}/pretrained/model_pretrained.pt" "${WEIGHTS}"
  minio_copy "${MINIO_REMOTE}/${MINIO_BUCKET}/pretrained/model_pretrained_classes.yaml" data.yaml
else
  echo "Using custom model..."

  # Get all model files from the latest training run
  LATEST_MOD_FILES=$(./mc --insecure --config-dir "${MINIO_CFG}" find "${MINIO_REMOTE}/${MINIO_BUCKET}/models" --tags "training-run=latest")
  echo "Latest model files: ${LATEST_MOD_FILES}"
  
  # Loop through the file list and check for the pytorch model file
  for file in ${LATEST_MOD_FILES}; do
    echo "${file}"

    if [[ "${file}" == *.pt ]]; then
      echo "Using pytorch model file: ${file}"
      minio_copy "${file}" "${WEIGHTS}"
    fi
    if [[ "${file}" == *.yaml ]]; then
      echo "Using pytorch model file: ${file}"
      minio_copy "${file}" data.yaml
    fi

  done
fi

cd /opt/app-root/src
/usr/local/bin/uvicorn main:app --host 0.0.0.0
