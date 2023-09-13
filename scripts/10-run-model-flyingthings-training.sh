#!/bin/sh

select_namespace(){
  if [ $# -eq 0 ]; then
    NAMESPACE=${1:-modemo}
    echo "NOTICE: No namespace / project name provided"
  fi

  echo "NAMESPACE: ${NAMESPACE}"
  oc project "${NAMESPACE}" &>/dev/null || oc new-project "${NAMESPACE}"
}

check_pipeline(){
  PIPELINE_NAME="${1}"

  # check for pipeline in current namespace
  if oc get pipeline "${PIPELINE_NAME}" -o name; then
    echo "PIPELINE: ${PIPELINE_NAME} exists"
  else
    echo "PIPELINE: ${PIPELINE_NAME} missing"
    exit 0
  fi
  echo "Starting pipeline: ${PIPELINE_NAME}"
}

start_pipelines(){

  select_namespace

  # Hosted -p MINIO_CLIENT_URL="https://dl.min.io/client/mc/release/linux-amd64"
  # Local  -p MINIO_CLIENT_URL="http://util02.davenet.local"

  IMAGE_REGISTRY=image-registry.openshift-image-registry.svc:5000
  GIT_URL=https://github.com/redhat-na-ssa/flyingthings.git
  GIT_REVISION=cory-review

  # kludge
  [ "${PWD##*/}" != "scripts" ] && pushd scripts

  # debug_pipeline; exit 0

  check_pipeline model-retraining
  tkn pipeline start "${PIPELINE_NAME}" \
    -w name=sourcecode,volumeClaimTemplateFile=code-pvc.yaml \
    -w name=shared-workspace,volumeClaimTemplateFile=work-pvc.yaml \
    -p GIT_URL="${GIT_URL}" \
    -p GIT_REVISION="${GIT_REVISION}" \
    -p NAMESPACE="${NAMESPACE}" \
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

}

start_pipelines
