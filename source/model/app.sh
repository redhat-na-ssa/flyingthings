#!/bin/sh
set -x

MINIO_CLIENT_URL="${MINIO_CLIENT_URL:-https://dl.min.io/client/mc/release/linux-amd64}"
MINIO_CFG="${MINIO_CFG:-.mc}"
MINIO_REMOTE="${MINIO_REMOTE:-remote}"
MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://minio:9000}"
MINIO_ACCESSKEY="${MINIO_ACCESSKEY:-minioadmin}"
MINIO_SECRETKEY="${MINIO_SECRETKEY:-minioadmin}"
MINIO_BUCKET="${MINIO_BUCKET:-flyingthings}"

SIMPLEVIS_DATA="${SIMPLEVIS_DATA:-scratch}"

MODEL_WEIGHTS=weights.pt
MODEL_CLASSES=classes.yaml
BASE_MODEL="${BASE_MODEL:-yolov5s.pt}"

BASEDIR=/opt/app-root/src

[ -d $SIMPLEVIS_DATA ] || mkdir -p $SIMPLEVIS_DATA
pushd $SIMPLEVIS_DATA || exit

BIN_PATH=bin
[ -d "${BIN_PATH}" ] || mkdir -p "${BIN_PATH}"
PATH=$(pwd)/bin:${PATH}


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
  ./mc --insecure --config-dir "${MINIO_CFG}" cp "${SOURCE}" "${DEST}"
}

download_yolo_model(){
  YOLOv5_VERSION="${YOLOv5_VERSION:-v7.0}"  

  curl -L -o "${MODEL_WEIGHTS}" "https://github.com/ultralytics/yolov5/releases/download/${YOLOv5_VERSION}/yolov5s.pt"
  curl -L -o "${MODEL_CLASSES}" "https://github.com/ultralytics/yolov5/raw/${YOLOv5_VERSION}/data/coco128.yaml"
}

load_model(){

  # If BASE_MODEL is pretrained, use the pretrained pytorch model file
  allowed_models=("yolov8n.pt" "yolov5s.pt")

  if [[ " ${allowed_models[@]} " =~ " ${BASE_MODEL} " ]]; then
    
    [ -e "${MODEL_WEIGHTS}" ] && [ -e "${MODEL_CLASSES}" ] && return

    minio_setup_client
    
    minio_copy "${MINIO_REMOTE}/${MINIO_BUCKET}/pretrained/model_pretrained.pt" "${MODEL_WEIGHTS}"
    minio_copy "${MINIO_REMOTE}/${MINIO_BUCKET}/pretrained/model_pretrained_classes.yaml" "${MODEL_CLASSES}"
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
        minio_copy "${file}" "${MODEL_WEIGHTS}"
      fi
      if [[ "${file}" == *.yaml ]]; then
        echo "Using pytorch model file: ${file}"
        minio_copy "${file}" data.yaml
      fi

    done
  fi
}

download_yolo_model
load_model

popd || exit

python3 app.py
