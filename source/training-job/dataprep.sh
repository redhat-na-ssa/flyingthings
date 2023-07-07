#!/bin/bash

curl $MINIO_CLIENT_URL/mc -o mc
chmod +x mc
./mc --config-dir miniocfg config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$MODEL_CLASSES $MODEL_CLASSES --insecure
./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$WEIGHTS $WEIGHTS --insecure
./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$DATASET_ZIP $DATASET_ZIP --insecure

# Use the default yolo if no custom base model is specified "yolov8n.pt"
if [ "$BASE_MODEL" == "yolov8n.pt" ]; then
    echo "Using pretrained model 'yolov8n.pt'"
else
    echo "Using supplied custom model $BASE_MODEL"
    ./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$BASE_MODEL $BASE_MODEL --insecure
fi

mkdir -p $SIMPLEVIS_DATA/workspace/datasets
cd $SIMPLEVIS_DATA/workspace/datasets
unzip $SIMPLEVIS_DATA/workspace/$DATASET_ZIP
ls -l $SIMPLEVIS_DATA/workspace/datasets
