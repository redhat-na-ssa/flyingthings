#!/bin/bash
cd $SIMPLEVIS_DATA
echo "*************** Training Run Results*************************"
cat $SIMPLEVIS_DATA/runs/train/results.csv
echo "************************************************************"
tar czf $SIMPLEVIS_DATA/runs/training-results.tgz $SIMPLEVIS_DATA/runs/train/
ls -l $SIMPLEVIS_DATA
# TODO fix issue with reusing minio config from earlier
./mc --config-dir $SIMPLEVIS_DATA/runs/miniocfg config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
./mc --config-dir $SIMPLEVIS_DATA/runs/miniocfg cp $SIMPLEVIS_DATA/runs/training-results.tgz myminio/flyingthings/training-results.tgz --insecure
./mc --config-dir $SIMPLEVIS_DATA/runs/miniocfg cp $SIMPLEVIS_DATA/runs/train/weights/best.pt myminio/flyingthings/model_candidate.pt --insecure