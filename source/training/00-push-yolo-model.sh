#!/bin/bash

MINCFG=miniocfg
./mc --config-dir ${MINCFG} cp $BASE_MODEL myminio/$PRETRAINED_BUCKET/model_pretrained.pt --insecure
./mc --config-dir ${MINCFG} cp coco128.yaml myminio/$PRETRAINED_BUCKET/model_pretrained_classes.yaml --insecure
