#!/bin/bash

MINIO_ENDPOINT=`oc get route|grep -v console|grep -v NAME|awk '{print $2 }'`
NAMESPACE='flyingthings-standalone'
MINIO_BUCKET='flyingthings'

tkn pipeline start app-pipeline \
-w name=shared-workspace,\
volumeClaimTemplateFile=pretrained-pvc.yaml \
-p deployment-name=model-server-pretrained \
-p git-url=https://github.com/davwhite/flyingthings.git \
-p git-revision=main \
-p BUILD_EXTRA_ARGS='--build-arg WEIGHTS=model_pretrained.pt --build-arg MODEL_CLASSES=flyingthings.yaml --build-arg BUILD_VER=0.0 --build-arg MINIO_ENDPOINT=$MINIO_ENDPOINT/$MINIO_BUCKET --build-arg SIMPLEVIS_DATA=/opt/app-root/src/simplevis-data' \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/$NAMESPACE/pretrained-model \
--use-param-defaults