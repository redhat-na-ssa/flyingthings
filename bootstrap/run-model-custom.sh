#!/bin/bash

MINIO_ENDPOINT=`oc get route|grep -v console|grep -v NAME|awk '{print $2 }'`
NAMESPACE='flyingthings-standalone'
MINIO_BUCKET='flyingthings'

tkn pipeline start model-serv-pipeline \
-w name=shared-workspace,\
volumeClaimTemplateFile=custom-pvc.yaml \
-p deployment-name=model-server-custom \
-p git-url=https://github.com/redhat-na-ssa/flyingthings.git \
-p git-revision=develop \
-p BUILD_EXTRA_ARGS='--build-arg WEIGHTS=model_custom.pt --build-arg MINIO_ENDPOINT=http://minio:9000 --build-arg MINIO_BUCKET=flyingthings --build-arg SIMPLEVIS_DATA=/opt/app-root/src/simplevis-data' \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/custom-model \
--use-param-defaults \
--use-param-defaults --showlog