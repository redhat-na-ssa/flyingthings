#!/bin/bash
cd $SIMPLEVIS_DATA/workspace
echo "*************** Training Run Results*************************"
cat $SIMPLEVIS_DATA/workspace/runs/train/results.csv
echo "************************************************************"
tar czf $SIMPLEVIS_DATA/workspace/runs/training-results.tgz $SIMPLEVIS_DATA/runs/train/
ls -l $SIMPLEVIS_DATA

./mc --config-dir miniocfg config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/runs/training-results.tgz myminio/flyingthings/training-results.tgz --insecure
./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/runs/train/weights/best.pt myminio/flyingthings/model_candidate.pt --insecure