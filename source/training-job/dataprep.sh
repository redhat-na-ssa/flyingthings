#!/bin/bash

curl $MINIO_CLIENT_URL/mc -o mc
chmod +x mc
./mc --config-dir miniocfg config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$MODEL_CLASSES $MODEL_CLASSES --insecure
./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$WEIGHTS $WEIGHTS --insecure
./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$BASE_MODEL $BASE_MODEL --insecure
./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$DATASET_ZIP $DATASET_ZIP --insecure

mkdir -p $SIMPLEVIS_DATA/datasets
cd $SIMPLEVIS_DATA/datasets
unzip $SIMPLEVIS_DATA/$DATASET_ZIP
ls -l $SIMPLEVIS_DATA/datasets
