#!/bin/bash

check_namespace(){
  NAMESPACE=$(oc project -q)
  echo "NAMESPACE: ${NAMESPACE}"
  echo ""
  echo "NOTICE: Verify you are working in the correct namespace"
  echo "Use CTRL + C to cancel"
  sleep 8
}


debug_pipeline(){

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
    -p NAMESPACE="${NAMESPACE}" \
    -p DEPLOY_LABELSTUDIO="Y" \
    --use-param-defaults --showlog
}

start_pipelines(){
  
  check_namespace

  # Hosted -p MINIO_CLIENT_URL="https://dl.min.io/client/mc/release/linux-amd64"
  # Local  -p MINIO_CLIENT_URL="http://util02.davenet.local"

  PIPELINE_NAME=flyingthings-images-pipeline
  IMAGE_REGISTRY=image-registry.openshift-image-registry.svc:5000
  GIT_URL=https://github.com/redhat-na-ssa/flyingthings.git
  GIT_REVISION=main

  # check for pipeline in current namespace
  if oc get pipeline "${PIPELINE_NAME}" -o name; then
    echo "PIPELINE: ${PIPELINE_NAME} exists"
  else
    echo "PIPELINE: ${PIPELINE_NAME} missing"
    exit 0
  fi

  echo "Starting pipeline: ${PIPELINE_NAME}"

  # kludge
  [ "${PWD##*/}" != "bootstrap" ] && pushd bootstrap

  # debug_pipeline; exit 0

  tkn pipeline start "${PIPELINE_NAME}" \
    -p git-url="${GIT_URL}" \
    -p git-revision="${GIT_REVISION}" \
    -p NAMESPACE="${NAMESPACE}" \
    -p BASE_MODEL="yolov5s.pt" \
    -w name=source,volumeClaimTemplateFile=code-pvc.yaml \
    -w name=shared-workspace,volumeClaimTemplateFile=work-pvc.yaml \
    --use-param-defaults --showlog

}

start_pipelines
