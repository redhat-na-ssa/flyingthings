#!/bin/bash

# MINIO_ENDPOINT=`oc get route|grep -v console|grep -v NAME|awk '{print $2 }'`
# NAMESPACE='flyingthings-standalone'
# MINIO_BUCKET='flyingthings'

cd ../pipelines

tkn pipeline start flyingthings-ubi9-pipeline \
-w name=shared-workspace,\
volumeClaimTemplateFile=custom-pvc.yaml \
-p git-url=https://github.com/redhat-na-ssa/flyingthings.git \
-p git-revision=develop \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/yolo:latest \
-p DOCKERFILE_PATH=source/yolo \
--use-param-defaults --showlog

tkn pipeline start flyingthings-ubi9-pipeline \
-w name=shared-workspace,\
volumeClaimTemplateFile=custom-pvc.yaml \
-p git-url=https://github.com/redhat-na-ssa/flyingthings.git \
-p git-revision=develop \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/base-ubi9:latest \
-p DOCKERFILE_PATH=source/ubi9 \
--use-param-defaults --showlog

tkn pipeline start flyingthings-minimal-pipeline \
-w name=shared-workspace,\
volumeClaimTemplateFile=custom-pvc.yaml \
-p git-url=https://github.com/redhat-na-ssa/flyingthings.git \
-p git-revision=develop \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/minimal-notebook:latest \
-p DOCKERFILE_PATH=source/minimal/py39 \
-p BUILD_EXTRA_ARGS='--build-arg BASE_IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/base-ubi9:latest' \
--use-param-defaults --showlog

tkn pipeline start flyingthings-minimal-pipeline \
-w name=shared-workspace,\
volumeClaimTemplateFile=custom-pvc.yaml \
-p git-url=https://github.com/redhat-na-ssa/flyingthings.git \
-p git-revision=develop \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/yolo-notebook:latest \
-p DOCKERFILE_PATH=source/custom \
-p BUILD_EXTRA_ARGS='--build-arg BASE_IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/minimal-notebook:latest' \
--use-param-defaults --showlog