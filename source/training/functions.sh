#!/bin/bash
set -x

MINIO_CLIENT_URL="${MINIO_CLIENT_URL:-https://dl.min.io/client/mc/release/linux-amd64}"
MINIO_CFG="${MINIO_CFG:-miniocfg}"
MINIO_REMOTE="${MINIO_REMOTE:-remote}"
MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://minio:9000}"
MINIO_ACCESSKEY="${MINIO_ACCESSKEY:-minioadmin}"
MINIO_SECRETKEY="${MINIO_SECRETKEY:-minioadmin}"
MINIO_BUCKET="${MINIO_BUCKET:-project}"

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

minio_create_bucket(){
  [ ! -d "${MINIO_CFG}" ] && minio_setup_client
  local BUCKET="${1}"
  local REMOTE="${MINIO_REMOTE}"

  ./mc --insecure --config-dir "${MINIO_CFG}" mb "${REMOTE}/${BUCKET}" || true
  ./mc --insecure --config-dir "${MINIO_CFG}" version enable "${REMOTE}/${BUCKET}" || true
}

minio_copy(){
  [ ! -d "${MINIO_CFG}" ] && minio_setup_client
  local SOURCE="${1}"
  local DEST="${2}"
  ./mc --insecure --config-dir "${MINIO_CFG}" cp "${SOURCE}" "${DEST}"
}

minio_tag(){
  [ ! -d "${MINIO_CFG}" ] && minio_setup_client
  local FILE="${1}"
  local TAG="${2}"
  ./mc --insecure --config-dir "${MINIO_CFG}" tag set "${FILE}" "${TAG}"
}

minio_copy_artifacts(){
  minio_copy "${SOURCE_DIR}/artifacts/flyingthings-yolo.zip" "${MINIO_REMOTE}/${MINIO_BUCKET}"
  minio_copy "${SOURCE_DIR}/artifacts/coco128.yaml" "${MINIO_REMOTE}/${MINIO_BUCKET}/pretrained/model_pretrained_classes.yaml"
}

minio_push_results(){
  cd "${SIMPLEVIS_DATA}/workspace" || return

  pwd && find runs && ls -l
  
  echo "*************** Training Run Results*************************"
  cat runs/results.csv
  echo "************************************************************"
  tar vzcf runs/training-results.tgz runs/exp/
  ls -l ../

  minio_setup_client

  PREVIOUS_RUN=0000
  CURRENT_RUN=0000

  # Get previous training run if it exists, otherwise set it to 0
  # First, list all objects with the tag "training-run=latest"
  LATEST_MOD_FILES=$(./mc --insecure --config-dir "${MINIO_CFG}" find "${MINIO_REMOTE}/${MINIO_BUCKET}/models" --tags "training-run=latest")

  # Check if any objects are returned
  if [ -n "${LATEST_MOD_FILES}" ]; then
    first_file="${LATEST_MOD_FILES[0]}"

    # Get the file extension using parameter expansion
    # This will extract everything after the last dot (.) in the filename
    file_extension="${first_file##*_}"
    run_number="${file_extension%.*}"

    echo "First file: $first_file"
    echo "File extension: $file_extension"
    echo "Run number: $run_number"

    PREVIOUS_RUN=$run_number
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
  minio_copy "${SIMPLEVIS_DATA}/workspace/runs/training-results.tgz" "${MINIO_REMOTE}/${MINIO_BUCKET}/training-run-${CURRENT_RUN}/training-results.tgz"
  minio_copy "${SIMPLEVIS_DATA}/workspace/runs/exp/weights/best.pt" "${MINIO_REMOTE}/${MINIO_BUCKET}/training-run-${CURRENT_RUN}/${WEIGHTS}"

  # Push the latest model files to the root of the bucket
  minio_copy "${SIMPLEVIS_DATA}/workspace/runs/exp/weights/best.pt" "${MINIO_REMOTE}/${MINIO_BUCKET}/models/model_custom_${CURRENT_RUN}.pt"
  minio_copy "${SIMPLEVIS_DATA}/workspace/runs/exp/weights/best.onnx" "${MINIO_REMOTE}/${MINIO_BUCKET}/models/model_custom_${CURRENT_RUN}.onnx"
  minio_copy "${SIMPLEVIS_DATA}/workspace/datasets/classes.txt" "${MINIO_REMOTE}/${MINIO_BUCKET}/models/classes_${CURRENT_RUN}.txt"
  minio_copy "${SIMPLEVIS_DATA}/workspace/classes.yaml" "${MINIO_REMOTE}/${MINIO_BUCKET}/models/classes_${CURRENT_RUN}.yaml"

  # Set the training run tag to latest
  minio_tag "${MINIO_REMOTE}/${MINIO_BUCKET}/models/model_custom_${CURRENT_RUN}.pt" "training-run=latest"
  minio_tag "${MINIO_REMOTE}/${MINIO_BUCKET}/models/model_custom_${CURRENT_RUN}.onnx" "training-run=latest"
  minio_tag "${MINIO_REMOTE}/${MINIO_BUCKET}/models/classes_${CURRENT_RUN}.txt" "training-run=latest"
  minio_tag "${MINIO_REMOTE}/${MINIO_BUCKET}/models/classes_${CURRENT_RUN}.yaml" "training-run=latest"
}

minio_get_dataset(){
  pwd
  minio_copy "${MINIO_REMOTE}/${MINIO_BUCKET}/${DATASET_ZIP}" "${DATASET_ZIP}"

  mkdir -p "${SIMPLEVIS_DATA}/workspace/datasets"
  pushd "${SIMPLEVIS_DATA}/workspace/datasets" || exit
    unzip "${SIMPLEVIS_DATA}/workspace/${DATASET_ZIP}"
    ls -l "${SIMPLEVIS_DATA}/workspace/datasets"
  popd || exit
}

minio_copy_yolo_model(){
  minio_copy "${BASE_MODEL}" "${MINIO_REMOTE}/${MINIO_BUCKET}/pretrained/model_pretrained.pt"
  minio_copy coco128.yaml "${MINIO_REMOTE}/${MINIO_BUCKET}/pretrained/model_pretrained_classes.yaml"
}

download_yolo_model(){
  wget https://github.com/ultralytics/yolov5/releases/download/v7.0/yolov5s.pt
  wget https://github.com/ultralytics/yolov5/raw/v7.0/data/coco128.yaml
  # ./mc --config-dir ${MINCFG} cp myminio/$MINIO_BUCKET/pretrained/model_pretrained_classes.yaml coco128.yaml  --insecure
}

model_export(){
  pwd
  mkdir -p "${SIMPLEVIS_DATA}/workspace"
  pushd "${SIMPLEVIS_DATA}/workspace" || exit
    # yolo export model=runs/train/weights/best.pt format=onnx
    python3 /usr/local/lib/python3.9/site-packages/yolov5/export.py --weights runs/exp/weights/best.pt --include onnx
  popd || exit
}

model_training(){
  pwd
  mkdir -p "${SIMPLEVIS_DATA}/workspace"
  pushd "${SIMPLEVIS_DATA}/workspace" || exit
    cp -R datasets/training/* /usr/local/lib/python3.9/site-packages/yolov5/training
    ls -l /usr/local/lib/python3.9/site-packages/yolov5
    ls -l /usr/local/lib/python3.9/site-packages/yolov5/training
    # yolo train model=$BASE_MODEL batch=$BATCH_SIZE epochs=$NUM_EPOCHS data=classes.yaml project=runs exist_ok=True
    python3 /usr/local/lib/python3.9/site-packages/yolov5/train.py \
      --epochs "${NUM_EPOCHS}" \
      --batch-size "${BATCH_SIZE}" \
      --weights "${BASE_MODEL}" \
      --data classes.yaml \
      --project runs \
      --img 640
  popd || exit
}
