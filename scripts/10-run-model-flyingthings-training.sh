#!/bin/sh

if [ $# -eq 0 ]; then
    echo Warning: No namespace provided. Please provide a target namespace.
    exit 1
fi

# Assign the first argument to the TABLESPACE variable
TABLESPACE=$1

oc project $1

# Execute your code here using the TABLESPACE variable
# NOTE: if not hosting the minio client binary ommit MINIO_CLIENT_URL to use the hosted file
# Official minio client https://dl.min.io/client/mc/release/linux-amd64
echo "Run model training"
tkn pipeline start training-x-pipeline \
  -w name=sourcecode,volumeClaimTemplateFile=code-pvc.yaml \
  -w name=shared-workspace,volumeClaimTemplateFile=work-pvc.yaml \
  -p NAMESPACE="$TABLESPACE" \
  -p GIT_URL=https://github.com/davwhite/flyingthings.git \
  -p GIT_REVISION=main \
  -p GPU="Y" \
  -p BASE_MODEL="yolov5s.pt" \
  -p BATCH_SIZE="-1" \
  -p NUM_EPOCHS="100" \
  -p IMG_RESIZE="Y" \
  -p MAX_WIDTH="200" \
  -p WEIGHTS=flyingthings.pt \
  -p DATASET_ZIP=flyingthings-yolo.zip \
  -p MINIO_ENDPOINT=http://minio:9000 \
  -p MINIO_ACCESSKEY=minioadmin \
  -p MINIO_SECRETKEY=minioadmin \
  -p MINIO_BUCKET=flyingthings \
  -p MODEL_NAME=model-flyingthings \
  -p MINIO_CLIENT_URL=https://dl.min.io/client/mc/release/linux-amd64 \
  -p DEPLOY="Y" \
  --use-param-defaults --showlog

# Exit the script gracefully
exit 0
