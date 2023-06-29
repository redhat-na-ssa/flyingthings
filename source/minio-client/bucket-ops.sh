#!/bin/bash
MINIO_ENDPOINT=http://minio:9000
MINIO_BUCKET=flyingthings
MINIO_ACCESSKEY=minioadmin
MINIO_SECRETKEY=minioadmin
MINIO_CLIENT_URL=https://dl.min.io/client/mc/release/linux-amd64
WORKSPACE_DIR=/opt/app-root/src/workspace
MINCFG=$WORKSPACE_DIR/miniocfg

RUN mkdir -p ${WORKSPACE_DIR}
cd $SIMPLEVIS_DATA
ls -l $SIMPLEVIS_DATA
curl $MINIO_CLIENT_URL/mc -o mc
chmod +x mc
./mc --config-dir ${MINCFG} config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
./mc --config-dir ${MINCFG} cp $SIMPLEVIS_DATA/runs/training-results.tgz myminio/$MINIO_BUCKET/training-results.tgz --insecure
./mc --config-dir ${MINCFG} cp $SIMPLEVIS_DATA/runs/train/weights/best.pt myminio/$MINIO_BUCKET/model_candidate.pt --insecure