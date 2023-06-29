#!/bin/bash

tkn pipeline start minio-server-setup \
-w name=shared-workspace,\
volumeClaimTemplateFile=../source/pipelines/custom-pvc.yaml \
-p git-url=https://github.com/redhat-na-ssa/flyingthings.git \
-p git-revision=main \
--use-param-defaults