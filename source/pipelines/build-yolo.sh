#!/bin/bash
tkn pipeline start app-pipeline \
-w name=shared-workspace,\
volumeClaimTemplateFile=https://raw.githubusercontent.com/openshift/pipelines-tutorial/pipelines-1.8/01_pipeline/03_persistent_volume_claim.yaml \
-p deployment-name=app-flyingthings \
-p git-url=https://github.com/davwhite/flyingthings.git \
-p git-revision=main \
-p BUILD_EXTRA_ARGS='--build-arg TRAINING_NAME=flyingthings' \
-p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/yolo \
--use-param-defaults