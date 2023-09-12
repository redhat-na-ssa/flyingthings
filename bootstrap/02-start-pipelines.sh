#!/bin/bash

select_namespace(){
  if [ $# -eq 0 ]; then
    NAMESPACE=${1:-modemo}
    echo "NOTICE: No namespace / project name provided"
  fi

  echo "NAMESPACE: ${NAMESPACE}"
  oc project "${NAMESPACE}" &>/dev/null || oc new-project "${NAMESPACE}"
}

start_pipelines(){
  
  select_namespace

  # Hosted -p MINIO_CLIENT_URL="https://dl.min.io/client/mc/release/linux-amd64"
  # Local  -p MINIO_CLIENT_URL="http://util02.davenet.local"

  PIPELINE_NAME=flyingthings-images-pipeline
  IMAGE_REGISTRY=image-registry.openshift-image-registry.svc:5000

  echo "Starting pipeline: ${PIPELINE_NAME}"

  tkn pipeline start "${PIPELINE_NAME}" \
    -w name=source,volumeClaimTemplateFile=code-pvc.yaml \
    -w name=shared-workspace,volumeClaimTemplateFile=work-pvc.yaml \
    -p git-url="https://github.com/redhat-na-ssa/flyingthings.git" \
    -p git-revision="main" \
    -p YOLO_IMAGE="${IMAGE_REGISTRY}/${NAMESPACE}/yolo:latest" \
    -p UBI_IMAGE="${IMAGE_REGISTRY}/${NAMESPACE}/base-ubi9:latest" \
    -p MINIMAL_IMAGE="${IMAGE_REGISTRY}/${NAMESPACE}/minimal-notebook:latest" \
    -p CUSTOM_NOTEBOOK_IMAGE="${IMAGE_REGISTRY}/${NAMESPACE}/yolo-notebook:latest" \
    -p MODEL_IMAGE="${IMAGE_REGISTRY}/${NAMESPACE}/custom-model:latest" \
    -p BASE_MODEL="yolov5s.pt" \
    -p MINIMAL_BUILD_ARGS="--build-arg BASE_IMAGE=${IMAGE_REGISTRY}/${NAMESPACE}/base-ubi9:latest" \
    -p MODEL_BUILD_ARGS="--build-arg WEIGHTS=flyingthings.pt --build-arg BASE_IMAGE=${IMAGE_REGISTRY}/${NAMESPACE}/yolo:latest" \
    -p CUSTOM_BUILD_ARGS="--build-arg BASE_IMAGE=${IMAGE_REGISTRY}/${NAMESPACE}/minimal-notebook:latest" \
    -p MINIO_BUCKET="flyingthings" \
    -p PRETRAINED_BUCKET="yolo" \
    -p MINIO_ACCESSKEY="minioadmin" \
    -p MINIO_SECRETKEY="minioadmin" \
    -p MINIO_CLIENT_URL="https://dl.min.io/client/mc/release/linux-amd64" \
    -p ocp-tablespace="${NAMESPACE}" \
    -p DEPLOY_LABELSTUDIO="Y" \
    --use-param-defaults --showlog

  # Exit the script gracefully
}

start_pipelines