#!/bin/bash
tkn pipeline start app-pipeline \
-w name=shared-workspace,\
volumeClaimTemplateFile=https://raw.githubusercontent.com/openshift/pipelines-tutorial/pipelines-1.8/01_pipeline/03_persistent_volume_claim.yaml \
-p deployment-name=model-server-custom \
-p git-url=https://github.com/davwhite/flyingthings.git \
-p git-revision=develop \
-p BUILD_EXTRA_ARGS='--build-arg WEIGHTS=model_custom.pt --build-arg MODEL_CLASSES=flyingthings.yaml --build-arg BUILD_VER=0.0 --build-arg MINIO_ENDPOINT=minio-flyingthings-standalone.apps.ocp4.davenet.local/flyingthings --build-arg SIMPLEVIS_DATA=/opt/app-root/src/simplevis-data' \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/custom-model \
--use-param-defaults