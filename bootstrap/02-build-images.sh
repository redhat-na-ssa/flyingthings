#!/bin/bash

# MINIO_ENDPOINT=`oc get route|grep -v console|grep -v NAME|awk '{print $2 }'`
# NAMESPACE='flyingthings-standalone'
# MINIO_BUCKET='flyingthings'

cd ../pipelines/manifests

# Build yolo image
tkn pipeline start flyingthings-ubi9-pipeline \
-w name=shared-workspace,\
volumeClaimTemplateFile=custom-pvc.yaml \
-p git-url=https://github.com/redhat-na-ssa/flyingthings.git \
-p git-revision=develop \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/yolo:latest \
-p DOCKERFILE_PATH=source/yolo \
--use-param-defaults --showlog

# Build ubi9 base image
tkn pipeline start flyingthings-ubi9-pipeline \
-w name=shared-workspace,\
volumeClaimTemplateFile=custom-pvc.yaml \
-p git-url=https://github.com/redhat-na-ssa/flyingthings.git \
-p git-revision=develop \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/base-ubi9:latest \
-p DOCKERFILE_PATH=source/ubi9 \
--use-param-defaults --showlog

# Build minimal notebook image
tkn pipeline start flyingthings-minimal-pipeline \
-w name=shared-workspace,\
volumeClaimTemplateFile=custom-pvc.yaml \
-p git-url=https://github.com/redhat-na-ssa/flyingthings.git \
-p git-revision=develop \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/minimal-notebook:latest \
-p DOCKERFILE_PATH=source/minimal/py39 \
-p BUILD_EXTRA_ARGS='--build-arg BASE_IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/base-ubi9:latest' \
--use-param-defaults --showlog

# Build custom notebook image for yolo
tkn pipeline start flyingthings-minimal-pipeline \
-w name=shared-workspace,\
volumeClaimTemplateFile=custom-pvc.yaml \
-p git-url=https://github.com/redhat-na-ssa/flyingthings.git \
-p git-revision=develop \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/yolo-notebook:latest \
-p DOCKERFILE_PATH=source/custom \
-p BUILD_EXTRA_ARGS='--build-arg BASE_IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/minimal-notebook:latest' \
--use-param-defaults --showlog

# Build image for training
tkn pipeline start flyingthings-training-image-pipeline \
-w name=shared-workspace,\
volumeClaimTemplateFile=custom-pvc.yaml \
-p git-url=https://github.com/redhat-na-ssa/flyingthings.git \
-p git-revision=develop \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/training-job:latest \
-p DOCKERFILE_PATH=source/training-job \
-p BUILD_EXTRA_ARGS='--build-arg BASE_IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/yolo:latest \
--build-arg BATCH_SIZE=2 \
--build-arg NUM_EPOCHS=1 \
--build-arg WEIGHTS=flyingthings.pt \
--build-arg BASE_MODEL=model_pretrained.pt \
--build-arg MODEL_CLASSES=flyingthings.yaml \
--build-arg MINIO_ENDPOINT=http://minio:9000 \
--build-arg DATASET_ZIP=flyingthings-yolo.zip \
--build-arg SIMPLEVIS_DATA=/opt/app-root/src/simplevis-data \
--build-arg BASEDIR=/opt/app-root/src \
--build-arg MINIO_BUCKET=flyingthings \
--build-arg MINIO_ACCESSKEY=minioadmin \
--build-arg MINIO_SECRETKEY=minioadmin \
--build-arg MINIO_CLIENT_URL=https://dl.min.io/client/mc/release/linux-amd64' \
--use-param-defaults --showlog

# Build image for model serving
tkn pipeline start model-serv-pipeline \
-w name=workspace,\
volumeClaimTemplateFile=custom-pvc.yaml \
-p GIT_REPO=https://github.com/redhat-na-ssa/flyingthings.git \
-p GIT_REVISION=develop \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/custom-model:latest \
-p DOCKERFILE_PATH=source/model \
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
