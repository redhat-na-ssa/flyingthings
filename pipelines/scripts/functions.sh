#!/bin/bash
# set -x

# kludges: everywhere

MINIO_CFG="${MINIO_CFG:-.mc}"
MINIO_REMOTE="${MINIO_REMOTE:-remote}"
MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://minio:9000}"
MINIO_ACCESSKEY="${MINIO_ACCESSKEY:-minioadmin}"
MINIO_SECRETKEY="${MINIO_SECRETKEY:-minioadmin}"
MINIO_BUCKET="${MINIO_BUCKET:-project}"

SCRATCH_DIR="${SCRATCH_DIR:-$(pwd)/scratch}"
BIN_DIR="${SCRATCH_DIR}/bin"

# kludge due to different storage types
umask 0002

create_bin(){
  echo "Creating ${BIN_DIR}..."
  mkdir -p "${BIN_DIR}"
  chmod g+w "${SCRATCH_DIR}" "${BIN_DIR}"
}

[ -d "${BIN_DIR}" ] || create_bin
PATH="${BIN_DIR}:${PATH}"

cd_to_scratch(){
  echo "Changing to ${SCRATCH_DIR}..."
  pushd "${SCRATCH_DIR}" || return
}

download_mc(){
  echo "Downloading MinIO Client..."
  MINIO_CLIENT_URL="${MINIO_CLIENT_URL:-https://dl.min.io/client/mc/release/linux-amd64}"
  curl -s -L "${MINIO_CLIENT_URL}/mc" -o "${BIN_DIR}/mc" && \
    chmod +x "${BIN_DIR}/mc"
}

minio_setup_client(){
  echo "Setting up MinIO Client..."
  which mc 2>/dev/null || download_mc || return
  mc --insecure --config-dir "${MINIO_CFG}" config host \
    add "${MINIO_REMOTE}" "${MINIO_ENDPOINT}" "${MINIO_ACCESSKEY}" "${MINIO_SECRETKEY}"
  chmod g+rwx -R "${MINIO_CFG}"
}

minio_create_bucket(){
  echo "Creating MinIO Bucket..."
  [ ! -d "${MINIO_CFG}" ] && minio_setup_client
  local BUCKET="${1}"
  local REMOTE="${MINIO_REMOTE}"

  mc --insecure --config-dir "${MINIO_CFG}" mb "${REMOTE}/${BUCKET}" || true
  mc --insecure --config-dir "${MINIO_CFG}" version enable "${REMOTE}/${BUCKET}" || true
}

minio_copy(){
  echo "Copying ${SOURCE} to MinIO..."
  [ ! -d "${MINIO_CFG}" ] && minio_setup_client
  local SOURCE="${1}"
  local DEST="${2}"
  echo 'mc --insecure --config-dir "${MINIO_CFG}" cp "${SOURCE}" "${DEST}"'
  mc --insecure --config-dir "${MINIO_CFG}" cp "${SOURCE}" "${DEST}"
}

minio_tag(){
  echo "Tagging MinIO Object..."
  [ ! -d "${MINIO_CFG}" ] && minio_setup_client
  local FILE="${1}"
  local TAG="${2}"
  mc --insecure --config-dir "${MINIO_CFG}" tag set "${FILE}" "${TAG}"
}

copy_artifacts(){
  echo "Copying artifacts to MinIO..."
  minio_create_bucket "${MINIO_BUCKET}"
  minio_copy "artifacts/flyingthings-yolo.zip" "${MINIO_REMOTE}/${MINIO_BUCKET}"
}

push_results(){
  echo "*************** Training Run Results*************************"
  cat runs/exp/results.csv
  echo "************************************************************"
  tar vzcf training-results.tgz runs/exp/
  ls -lsa

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
  minio_copy "training-results.tgz" "${MINIO_REMOTE}/${MINIO_BUCKET}/training-run-${CURRENT_RUN}/training-results.tgz"
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

get_dataset(){
  echo "Getting dataset from MinIO..."
  minio_copy "${MINIO_REMOTE}/${MINIO_BUCKET}/${DATASET_ZIP}" "${DATASET_ZIP}"
  unzip -d datasets "${DATASET_ZIP}"
  rm "${DATASET_ZIP}"
}

minio_copy_yolo_model(){
  echo "Copying YOLO model to MinIO..."
  minio_copy "${MODEL_BASE}" "${MINIO_REMOTE}/${MINIO_BUCKET}/pretrained/model_pretrained.pt"
  minio_copy coco128.yaml "${MINIO_REMOTE}/${MINIO_BUCKET}/pretrained/model_pretrained_classes.yaml"
}

download_yolo_model(){
  echo "Downloading YOLO model..."
  YOLOv5_VERSION="${YOLOv5_VERSION:-v7.0}"  
  MODEL_BASE="${MODEL_BASE:-yolov5s.pt}"

  curl -s -LO "https://github.com/ultralytics/yolov5/releases/download/${YOLOv5_VERSION}/${MODEL_BASE}"
  curl -s -LO "https://github.com/ultralytics/yolov5/raw/${YOLOv5_VERSION}/data/coco128.yaml"

  [ -d source/model/scratch ] || mkdir -p source/model/scratch
  cp "${MODEL_BASE}" source/model/scratch
  cp coco128.yaml source/model/scratch
}

model_training(){
  echo "Training model..."
  YOLO_DIR="${YOLO_DIR:-/opt/app-root/lib/python3.9/site-packages/yolov5}"
  TRAINING_DIR="${TRAINING_DIR:-${YOLO_DIR}/training}"

  # python debug
  # python -m site

  [ -d "${TRAINING_DIR}" ] || mkdir -p "${TRAINING_DIR}"
  cp -R datasets/training/* "${TRAINING_DIR}/"

  # yolov8
  # yolo checks && \
  # yolo train model=$MODEL_BASE batch=$BATCH_SIZE epochs=$NUM_EPOCHS data=classes.yaml project=runs exist_ok=True
  
  # yologv5
  yolov5 train \
    --source "${DATA_DIR:-datasets/training}" \
    --weights "${MODEL_BASE:-yolov5s.pt}" \
    --epochs "${NUM_EPOCHS:-2}" \
    --batch-size "${BATCH_SIZE:--1}" \
    --data "${MODEL_FILE:-classes.yaml}" \
    --project runs \
    --img 640

  # yolo export model=runs/train/weights/best.pt format=onnx
  python3 "${YOLO_DIR}/export.py" --weights runs/exp/weights/best.pt --include onnx

}

resize_images(){
  echo "Resizing images..."
  IMG_SRC=${1:-images}
  IMG_WIDTH=${2:-200}

  # backup original images
  mv "${IMG_SRC}" "${IMG_SRC}-orig" && \
  python3 "/source/pipelines/scripts/images-resize.py" \
    "${IMG_SRC}-orig" \
    "${IMG_SRC}" \
    "${IMG_WIDTH}"
}

distribute_dataset(){
  pushd datasets || return
  echo "Distributing dataset..."
    python3 "/source/pipelines/scripts/images-distribute.py"
  popd || return
}

check_base_image(){
  echo "Checking base image..."
  IS_TAG="${1}"
  echo "Waiting for ${IS_TAG}..."
  READY=true
  while [ -z "${READY}" ]
  do
    oc get istag "${IS_TAG}" -n ml-demo -o name 2>/dev/null && \
    READY=true && continue
    sleep 10
  done

  echo "[ OK ]"
  unset READY
}

create_json_array(){
  NAMES=$( printf "'%s'," "${LIST[@]}" )
  NAMES="[${NAMES: : -1}]"
  # echo "${NAMES}"
}

create_names_array(){
  LIST=()

  local IFS=''
  while read -r ITEM
  do
    LIST+=("${ITEM}")
  done < classes.txt
}

create_classes_file(){
  pushd datasets || exit 1
  
  NC=$( wc -l < classes.txt )

  create_names_array
  create_json_array

cat > ../classes.yaml <<YAML
path: training
train: train/images
val: valid/images
test: test/images

nc: ${NC}
names: ${NAMES}
YAML

  cat ../classes.yaml

  popd || return
}

# debug
id; umask
# df -h; pwd; ls -lsa
