#!/bin/bash

# Check the number of arguments
if [ "$#" -ne 3 ]; then
  echo "Error: Expected 3 arguments, but received $# arguments."
  echo "Usage: $0 NAMESPACE MINIO_ENDPOINT MINIO_BUCKET"
  exit 1
fi

NAMESPACE=$1
MINIO_ENDPOINT=$2
MINIO_BUCKET=$3

tkn pipeline start app-pipeline \
-w name=shared-workspace,\
volumeClaimTemplateFile=pretrained-pvc.yaml \
-p deployment-name=model-server-pretrained \
-p git-url=https://github.com/davwhite/flyingthings.git \
-p git-revision=develop \
-p BUILD_EXTRA_ARGS='--build-arg WEIGHTS=model_pretrained.pt --build-arg MODEL_CLASSES=flyingthings.yaml --build-arg BUILD_VER=0.0 --build-arg MINIO_ENDPOINT=$MINIO_ENDPOINT/$MINIO_BUCKET --build-arg SIMPLEVIS_DATA=/opt/app-root/src/simplevis-data' \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/$NAMESPACE/pretrained-model \
--use-param-defaults