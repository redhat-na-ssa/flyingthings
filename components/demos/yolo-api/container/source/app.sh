#!/bin/bash
set -x

MINIO_CLIENT_URL="${MINIO_CLIENT_URL:-https://dl.min.io/client/mc/release/linux-amd64}"
MINIO_CFG="${MINIO_CFG:-.mc}"
MINIO_REMOTE="${MINIO_REMOTE:-remote}"
MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://minio:9000}"
MINIO_ACCESSKEY="${MINIO_ACCESSKEY:-minioadmin}"
MINIO_SECRETKEY="${MINIO_SECRETKEY:-minioadmin}"
MINIO_BUCKET="${MINIO_BUCKET:-flyingthings}"

DATA_PATH="${DATA_PATH:-scratch}"

MODEL_BASE="${MODEL_BASE:-yolov5s.pt}"

MODEL_WEIGHTS=weights.pt
MODEL_CLASSES=classes.yaml


[ -d "${DATA_PATH}" ] || mkdir -p "${DATA_PATH}"
pushd "${DATA_PATH}" || exit

BIN_PATH=$(pwd)/bin
[ -d "${BIN_PATH}" ] || mkdir -p "${BIN_PATH}"
PATH="${BIN_PATH}:${PATH}"


download_mc(){
  curl -s -L "${MINIO_CLIENT_URL}/mc" -o ./bin/mc
  chmod +x ./bin/mc
}

minio_setup_client(){
  which mc 2>/dev/null || download_mc
  mc --insecure --config-dir "${MINIO_CFG}" config host \
    add "${MINIO_REMOTE}" "${MINIO_ENDPOINT}" "${MINIO_ACCESSKEY}" "${MINIO_SECRETKEY}"
}

minio_copy(){
  [ ! -d "${MINIO_CFG}" ] && minio_setup_client
  local SOURCE="${1}"
  local DEST="${2}"
  mc --insecure --config-dir "${MINIO_CFG}" cp "${SOURCE}" "${DEST}"
}

download_yolo_model(){
  yolov5 detect
}

load_model_from_minio(){
  echo "attempting to load custom model..."
  
  minio_setup_client

  # Get all model files from the latest training run
  LATEST_MOD_FILES=$(mc --insecure --config-dir "${MINIO_CFG}" find "${MINIO_REMOTE}/${MINIO_BUCKET}/models" --tags "training-run=latest")
  echo "Latest model files: ${LATEST_MOD_FILES}"
  
  # Loop through the file list and check for the pytorch model file
  for file in ${LATEST_MOD_FILES}; do
    echo "${file}"

    if [[ "${file}" == *.pt ]]; then
      echo "Using pytorch model file: ${file}"
      minio_copy "${file}" "${MODEL_WEIGHTS}" || return
    fi
    if [[ "${file}" == *.yaml ]]; then
      echo "Using pytorch model file: ${file}"
      minio_copy "${file}" "${MODEL_CLASSES}" || return
    fi

  done

  [ -e "${MODEL_WEIGHTS}" ] || return 1
  [ -e "${MODEL_CLASSES}" ] || return 1

}

load_model(){

  if load_model_from_minio; then
    echo "model loaded from minio"
  else

    SITE_PATH=$(python -m site | grep -v -E 'lib64|USER' | grep site-packages | sed "s/[ ,\']*//g")

    export MODEL_WEIGHTS=yolov5s.pt
    export MODEL_CLASSES="${SITE_PATH}/yolov5/data/coco128.yaml"

    [ -e "${MODEL_WEIGHTS}" ] || download_yolo_model || return
    [ -e "${MODEL_CLASSES}" ] || return
    echo "model loaded from container"
  fi
}

# download_yolo_model
load_model || echo "model failed to load"

popd || exit

python3 app.py
