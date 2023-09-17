#!/bin/bash
# set -x

MINIO_CLIENT_URL="${MINIO_CLIENT_URL:-https://dl.min.io/client/mc/release/linux-amd64}"
MINIO_CFG="${MINIO_CFG:-.mc}"
MINIO_REMOTE="${MINIO_REMOTE:-remote}"
MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://minio:9000}"
MINIO_ACCESSKEY="${MINIO_ACCESSKEY:-minioadmin}"
MINIO_SECRETKEY="${MINIO_SECRETKEY:-minioadmin}"
MINIO_BUCKET="${MINIO_BUCKET:-project}"

SOURCE_DIR="${SOURCE_DIR:-/source}"

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

minio_create_bucket(){
  [ ! -d "${MINIO_CFG}" ] && minio_setup_client
  local BUCKET="${1}"
  local REMOTE="${MINIO_REMOTE}"

  mc --insecure --config-dir "${MINIO_CFG}" mb "${REMOTE}/${BUCKET}" || true
  mc --insecure --config-dir "${MINIO_CFG}" version enable "${REMOTE}/${BUCKET}" || true
}

minio_copy(){
  [ ! -d "${MINIO_CFG}" ] && minio_setup_client
  local SOURCE="${1}"
  local DEST="${2}"
  mc --insecure --config-dir "${MINIO_CFG}" cp "${SOURCE}" "${DEST}"
}

minio_tag(){
  [ ! -d "${MINIO_CFG}" ] && minio_setup_client
  local FILE="${1}"
  local TAG="${2}"
  mc --insecure --config-dir "${MINIO_CFG}" tag set "${FILE}" "${TAG}"
}

minio_copy_artifacts(){
  minio_copy "artifacts/flyingthings-yolo.zip" "${MINIO_REMOTE}/${MINIO_BUCKET}"
  # minio_copy "artifacts/coco128.yaml" "${MINIO_REMOTE}/${MINIO_BUCKET}/pretrained/model_pretrained_classes.yaml"
}

minio_push_results(){
  echo "*************** Training Run Results*************************"
  cat runs/exp/results.csv
  echo "************************************************************"
  tar vzcf runs/training-results.tgz runs/exp/
  ls -l ../

  minio_setup_client

  PREVIOUS_RUN=0000
  CURRENT_RUN=0000

  # Get previous training run if it exists, otherwise set it to 0
  # First, list all objects with the tag "training-run=latest"
  LATEST_MOD_FILES=$(mc --insecure --config-dir "${MINIO_CFG}" find "${MINIO_REMOTE}/${MINIO_BUCKET}/models" --tags "training-run=latest")

  # Check if any objects are returned
  if [ -n "${LATEST_MOD_FILES}" ]; then
    last_file="${LATEST_MOD_FILES[0]}"

    # Get the file extension using parameter expansion
    # This will extract everything after the last dot (.) in the filename
    file_extension="${last_file##*_}"
    run_number="${file_extension%.*}"

    echo "Latest file: ${last_file}"
    echo "File extension: ${file_extension}"
    echo "Run number: ${run_number}"

    PREVIOUS_RUN=${run_number}
    RUN_VALUE=$((run_number + 1))
    CURRENT_RUN=$(printf "%04d" "${RUN_VALUE}")

    # Tag the previous run files with the previous run number
    for file in ${LATEST_MOD_FILES}; do
    echo "latest file: ${file}"
      minio_tag "${file}" "training-run=${PREVIOUS_RUN}"
    done
  else
    echo "files not found"
  fi

  echo "current run: ${CURRENT_RUN}"

  # Push the results to minio
  # Push the training results to a training run folder
  minio_copy "runs/training-results.tgz" "${MINIO_REMOTE}/${MINIO_BUCKET}/training-run-${CURRENT_RUN}/training-results.tgz"
  minio_copy "runs/exp/weights/best.pt" "${MINIO_REMOTE}/${MINIO_BUCKET}/training-run-${CURRENT_RUN}/${WEIGHTS}"

  # Push the latest model files to the root of the bucket
  minio_copy "runs/exp/weights/best.pt" "${MINIO_REMOTE}/${MINIO_BUCKET}/models/model_custom_${CURRENT_RUN}.pt"
  minio_copy "runs/exp/weights/best.onnx" "${MINIO_REMOTE}/${MINIO_BUCKET}/models/model_custom_${CURRENT_RUN}.onnx"
  minio_copy "datasets/classes.txt" "${MINIO_REMOTE}/${MINIO_BUCKET}/models/classes_${CURRENT_RUN}.txt"
  minio_copy "classes.yaml" "${MINIO_REMOTE}/${MINIO_BUCKET}/models/classes_${CURRENT_RUN}.yaml"

  # Set the training run tag to latest
  minio_tag "${MINIO_REMOTE}/${MINIO_BUCKET}/models/model_custom_${CURRENT_RUN}.pt" "training-run=latest"
  minio_tag "${MINIO_REMOTE}/${MINIO_BUCKET}/models/model_custom_${CURRENT_RUN}.onnx" "training-run=latest"
  minio_tag "${MINIO_REMOTE}/${MINIO_BUCKET}/models/classes_${CURRENT_RUN}.txt" "training-run=latest"
  minio_tag "${MINIO_REMOTE}/${MINIO_BUCKET}/models/classes_${CURRENT_RUN}.yaml" "training-run=latest"
}

minio_get_dataset(){
  minio_copy "${MINIO_REMOTE}/${MINIO_BUCKET}/${DATASET_ZIP}" "${DATASET_ZIP}"
  unzip -d datasets "${DATASET_ZIP}"
  rm "${DATASET_ZIP}"
}

minio_copy_yolo_model(){
  minio_copy "${BASE_MODEL}" "${MINIO_REMOTE}/${MINIO_BUCKET}/pretrained/model_pretrained.pt"
  minio_copy coco128.yaml "${MINIO_REMOTE}/${MINIO_BUCKET}/pretrained/model_pretrained_classes.yaml"
}

download_yolo_model(){
  YOLOv5_VERSION="${YOLOv5_VERSION:-v7.0}"  
  BASE_MODEL="${BASE_MODEL:-yolov5s.pt}"

  curl -s -LO "https://github.com/ultralytics/yolov5/releases/download/${YOLOv5_VERSION}/${BASE_MODEL}"
  curl -s -LO "https://github.com/ultralytics/yolov5/raw/${YOLOv5_VERSION}/data/coco128.yaml"
}

model_export(){
  # yolo export model=runs/train/weights/best.pt format=onnx
  python3 /usr/local/lib/python3.9/site-packages/yolov5/export.py --weights runs/exp/weights/best.pt --include onnx
}

model_training(){
  cp -R datasets/training/* /usr/local/lib/python3.9/site-packages/yolov5/training
  # ls -l /usr/local/lib/python3.9/site-packages/yolov5
  # ls -l /usr/local/lib/python3.9/site-packages/yolov5/training

  # yolo train model=$BASE_MODEL batch=$BATCH_SIZE epochs=$NUM_EPOCHS data=classes.yaml project=runs exist_ok=True
  python3 /usr/local/lib/python3.9/site-packages/yolov5/train.py \
    --epochs "${NUM_EPOCHS}" \
    --batch-size "${BATCH_SIZE}" \
    --weights "${BASE_MODEL}" \
    --data classes.yaml \
    --project runs \
    --img 640
}

images_resize(){
  IMG_SRC=${1:-images}
  IMG_WIDTH=${2:-200}

  # backup original images
  mv "${IMG_SRC}" "${IMG_SRC}-orig" && \
  python3 "${SOURCE_DIR}/source/training/images-resize.py" \
    "${IMG_SRC}-orig" \
    "${IMG_SRC}" \
    "${IMG_WIDTH}"
}

images_distribute(){
  pushd datasets || return
    python3 "${SOURCE_DIR}/source/training/images-distribute.py"
  popd || return
}

# df -h; pwd; ls -lsa
