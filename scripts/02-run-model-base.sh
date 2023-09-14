#!/bin/sh

get_namespace(){
  NAMESPACE=$(oc project -q 2>/dev/null)
  echo "NAMESPACE: ${NAMESPACE}"
  echo ""
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

debug_pipeline(){

  tkn pipeline start "${PIPELINE_NAME}" \
    -w name=source,volumeClaimTemplateFile=code-pvc.yaml \
    -w name=shared-workspace,volumeClaimTemplateFile=work-pvc.yaml \
    -p GIT_URL="https://github.com/redhat-na-ssa/flyingthings.git" \
    -p GIT_REVISION="main" \
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

  get_namespace

  # Hosted -p MINIO_CLIENT_URL="https://dl.min.io/client/mc/release/linux-amd64"
  # Local  -p MINIO_CLIENT_URL="http://util02.davenet.local"

  IMAGE_REGISTRY=image-registry.openshift-image-registry.svc:5000
  GIT_URL=https://github.com/redhat-na-ssa/flyingthings.git
  GIT_REVISION=cory-review

  # kludge
  [ "${PWD##*/}" != "scripts" ] && pushd scripts

  # debug_pipeline; exit 0

  # check_pipeline deploy-label-studio
  
  # tkn pipeline start "${PIPELINE_NAME}" \
  #   -p GIT_URL="${GIT_URL}" \
  #   -p GIT_REVISION="${GIT_REVISION}" \
  #   -p NAMESPACE="${NAMESPACE}" \
  #   -w name=source,volumeClaimTemplateFile=code-pvc.yaml \
  #   --use-param-defaults

  check_pipeline model-base
 
  tkn pipeline start "${PIPELINE_NAME}" \
    -p GIT_URL="${GIT_URL}" \
    -p GIT_REVISION="${GIT_REVISION}" \
    -p NAMESPACE="${NAMESPACE}" \
    -p BASE_MODEL="yolov5s.pt" \
    -w name=source,volumeClaimTemplateFile=code-pvc.yaml \
    -w name=shared-workspace,volumeClaimTemplateFile=work-pvc.yaml \
    --use-param-defaults --showlog

}

start_pipelines
