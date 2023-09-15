#!/bin/sh

YOLOv5_VERSION="${YOLOv5_VERSION:-v7.0}"

wget "https://github.com/ultralytics/yolov5/releases/download/${YOLOv5_VERSION}/yolov5s.pt"

MINCFG=miniocfg
./mc --config-dir ${MINCFG} cp myminio/$MINIO_BUCKET/pretrained/model_pretrained_classes.yaml coco128.yaml  --insecure
