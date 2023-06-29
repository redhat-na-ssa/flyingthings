#!/bin/bash

# MINIO_ENDPOINT=`oc get route|grep -v console|grep -v NAME|awk '{print $2 }'`
# NAMESPACE='flyingthings-standalone'
# MINIO_BUCKET='flyingthings'

tkn pipeline start minio-server-setup \
-w name=shared-workspace,\
volumeClaimTemplateFile=custom-pvc.yaml \
-p git-url=https://github.com/redhat-na-ssa/flyingthings.git \
-p git-revision=main \
--use-param-defaults