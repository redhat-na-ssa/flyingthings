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

start_pipelines(){

  get_namespace

  IMAGE_REGISTRY=image-registry.openshift-image-registry.svc:5000
  GIT_URL=https://github.com/redhat-na-ssa/flyingthings.git
  GIT_REVISION=cory-review

  # kludge
  [ "${PWD##*/}" != "scripts" ] && pushd scripts

  # debug_pipeline; exit 0

  check_pipeline model-retraining
  tkn pipeline start "${PIPELINE_NAME}" \
    -w name=source,volumeClaimTemplateFile=code-pvc.yaml \
    -w name=shared-workspace,volumeClaimTemplateFile=work-pvc.yaml \
    -p GIT_URL="${GIT_URL}" \
    -p GIT_REVISION="${GIT_REVISION}" \
    -p NAMESPACE="${NAMESPACE}" \
    -p BASE_MODEL="yolov5s.pt" \
    -p BATCH_SIZE="-1" \
    -p NUM_EPOCHS="100" \
    -p IMG_RESIZE="Y" \
    -p MAX_WIDTH="200" \
    -p WEIGHTS=flyingthings.pt \
    -p DATASET_ZIP=flyingthings-yolo.zip \
    -p MODEL_NAME=model-flyingthings \
    --use-param-defaults --showlog

}

start_pipelines
