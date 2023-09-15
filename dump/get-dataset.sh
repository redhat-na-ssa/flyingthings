#!/bin/sh -v
MINIO_CLIENT_URL=https://dl.min.io/client/mc/release/linux-amd64

curl $MINIO_CLIENT_URL/mc -o mc
chmod +x mc
./mc --config-dir miniocfg config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$DATASET_ZIP $DATASET_ZIP --insecure

mkdir -p $SIMPLEVIS_DATA/workspace/datasets
cd $SIMPLEVIS_DATA/workspace/datasets
unzip $SIMPLEVIS_DATA/workspace/$DATASET_ZIP
ls -l $SIMPLEVIS_DATA/workspace/datasets