#!/bin/bash
MINIO_ENDPOINT=http://minio:9000
MINIO_BUCKET=flyingthings
MINIO_ACCESSKEY=minioadmin
MINIO_SECRETKEY=minioadmin
MINIO_CLIENT_URL=https://dl.min.io/client/mc/release/linux-amd64
WORKSPACE_DIR=/opt/app-root/src/workspace
MINCFG=$WORKSPACE_DIR/miniocfg
SOURCE_DIR=/workspace/output

RUN mkdir -p ${WORKSPACE_DIR}
cd $SIMPLEVIS_DATA
ls -l $SIMPLEVIS_DATA
curl $MINIO_CLIENT_URL/mc -o mc
chmod +x mc
./mc --config-dir ${MINCFG} config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
./mc --config-dir ${MINCFG} mb myminio/$MINIO_BUCKET --insecure
./mc --config-dir ${MINCFG} version enable myminio/$MINIO_BUCKET --insecure
./mc --config-dir ${MINCFG} cp --recursive $SOURCE_DIR/artifacts myminio/$MINIO_BUCKET --insecure

# List all objects in the bucket
objects=$(./mc ls --recursive $MINIO_BUCKET | awk '{ print $5 }')

# Loop through each object and apply tags
for object in $objects; do
  ./mc cp --attr "build=0.0" $MINIO_BUCKET/$object $MINIO_BUCKET/$object
done