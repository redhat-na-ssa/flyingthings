#!/bin/bash

cd ../pipelines/runs

tkn pipeline start deploy-model-server \
-w name=workspace,\
volumeClaimTemplateFile=custom-pvc.yaml \
-p GIT_REPO=https://github.com/redhat-na-ssa/flyingthings.git \
-p GIT_REVISION=develop \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/custom-model:latest \
-p DOCKERFILE_PATH=source \
-p BUILD_EXTRA_ARGS='--build-arg WEIGHTS=flyingthings.pt \
--build-arg BUILD_VER=0.0 \
--build-arg MODEL_CLASSES=flyingthings.yaml \
--build-arg SIMPLEVIS_DATA=/opt/app-root/src/simplevis-data \
--build-arg BASEDIR=/opt/app-root/src \
--build-arg MINIO_ENDPOINT=http://minio:9000 \
--build-arg MINIO_BUCKET=flyingthings \
--build-arg MINIO_ACCESSKEY=minioadmin \
--build-arg MINIO_SECRETKEY=minioadmin' \
--use-param-defaults --showlog
