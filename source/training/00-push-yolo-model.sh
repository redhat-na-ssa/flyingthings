#!/bin/bash

MINCFG=miniocfg
./mc --config-dir ${MINCFG} cp $BASE_MODEL myminio/$MINIO_BUCKET/model_pretrained.pt --insecure
