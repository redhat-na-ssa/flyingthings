#!/bin/bash

MINCFG=miniocfg
./mc --config-dir ${MINCFG} cp $BASE_MODEL myminio/$MINIO_BUCKET/model_pretrained.pt --insecure
./mc --config-dir ${MINCFG} cp coco128.yaml myminio/$MINIO_BUCKET/model_pretrained_classes.yaml --insecure
