#!/bin/bash

MINCFG=miniocfg
./mc --config-dir ${MINCFG} cp yolov8n.pt myminio/$MINIO_BUCKET/model_pretrained.pt --insecure
