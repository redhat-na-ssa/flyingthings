#!/bin/bash
WORKSPACE_DIR=/opt/app-root/src/workspace
MINCFG=$WORKSPACE_DIR/miniocfg
# SOURCE_DIR=/workspace/workspace

mkdir -p ${WORKSPACE_DIR}
cd $SIMPLEVIS_DATA
ls -l $SIMPLEVIS_DATA
curl $MINIO_CLIENT_URL/mc -o mc
chmod +x mc
./mc --config-dir ${MINCFG} config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
