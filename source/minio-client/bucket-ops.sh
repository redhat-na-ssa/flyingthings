#!/bin/bash
MINIO_ENDPOINT=http://minio:9000
MINIO_BUCKET=flyingthings
MINIO_ACCESSKEY=minioadmin
MINIO_SECRETKEY=minioadmin
MINIO_CLIENT_URL=https://dl.min.io/client/mc/release/linux-amd64
WORKSPACE_DIR=/opt/app-root/src/workspace
MINCFG=$WORKSPACE_DIR/miniocfg
SOURCE_DIR=/workspace/workspace

mkdir -p ${WORKSPACE_DIR}
cd $SIMPLEVIS_DATA
ls -l $SIMPLEVIS_DATA
curl $MINIO_CLIENT_URL/mc -o mc
chmod +x mc
./mc --config-dir ${MINCFG} config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
./mc --config-dir ${MINCFG} mb myminio/$MINIO_BUCKET --insecure
./mc --config-dir ${MINCFG} version enable myminio/$MINIO_BUCKET --insecure
./mc --config-dir ${MINCFG} cp $SOURCE_DIR/artifacts/flyingthings.yaml myminio/$MINIO_BUCKET --insecure
./mc --config-dir ${MINCFG} cp $SOURCE_DIR/artifacts/flyingthings-yolo.zip myminio/$MINIO_BUCKET --insecure
./mc --config-dir ${MINCFG} cp $SOURCE_DIR/notebooks/01-training-prep.ipynb myminio/$MINIO_BUCKET --insecure
./mc --config-dir ${MINCFG} cp $SOURCE_DIR/notebooks/02-object-detect-train.ipynb myminio/$MINIO_BUCKET --insecure
./mc --config-dir ${MINCFG} cp $SOURCE_DIR/notebooks/99-utils.ipynb myminio/$MINIO_BUCKET --insecure