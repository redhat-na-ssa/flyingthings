#!/bin/sh

wget https://github.com/ultralytics/yolov5/releases/download/v7.0/yolov5s.pt

MINCFG=miniocfg
./mc --config-dir ${MINCFG} cp myminio/$PRETRAINED_BUCKET/model_pretrained_classes.yaml coco128.yaml  --insecure
