#!/bin/sh
MINCFG=miniocfg
./mc --config-dir ${MINCFG} mb myminio/$MINIO_BUCKET --insecure
./mc --config-dir ${MINCFG} version enable myminio/$MINIO_BUCKET --insecure

# Create a bucket for the pre-trained model
# ./mc --config-dir ${MINCFG} mb myminio/yolo --insecure
# ./mc --config-dir ${MINCFG} version enable myminio/yolo --insecure
