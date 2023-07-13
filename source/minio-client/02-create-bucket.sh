#!/bin/bash
WORKSPACE_DIR=/opt/app-root/src/workspace
MINCFG=$WORKSPACE_DIR/miniocfg
# SOURCE_DIR=/workspace/workspace
cd $SIMPLEVIS_DATA
./mc --config-dir ${MINCFG} mb myminio/$MINIO_BUCKET --insecure
./mc --config-dir ${MINCFG} version enable myminio/$MINIO_BUCKET --insecure
