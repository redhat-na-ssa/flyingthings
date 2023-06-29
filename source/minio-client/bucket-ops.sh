#!/bin/bash
cd $SIMPLEVIS_DATA
ls -l $SIMPLEVIS_DATA
curl $MINIO_CLIENT_URL/mc -o mc
chmod +x mc
./mc --config-dir ${MINCFG} config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
./mc --config-dir ${MINCFG} cp $SIMPLEVIS_DATA/runs/training-results.tgz myminio/flyingthings/training-results.tgz --insecure
./mc --config-dir ${MINCFG} cp $SIMPLEVIS_DATA/runs/train/weights/best.pt myminio/flyingthings/model_candidate.pt --insecure