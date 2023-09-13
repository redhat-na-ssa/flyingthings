#!/bin/sh
set -x

df -h

cd $SIMPLEVIS_DATA/workspace
cp -R datasets/training/* /usr/local/lib/python3.9/site-packages/yolov5/training
ls -l /usr/local/lib/python3.9/site-packages/yolov5
ls -l /usr/local/lib/python3.9/site-packages/yolov5/training
# yolo train model=${SIMPLEVIS_DATA}/workspace/$BASE_MODEL batch=$BATCH_SIZE epochs=$NUM_EPOCHS data=classes.yaml project=${SIMPLEVIS_DATA}/workspace/runs exist_ok=True
python3 /usr/local/lib/python3.9/site-packages/yolov5/train.py --img 640 --epochs $NUM_EPOCHS --batch-size $BATCH_SIZE --data classes.yaml --weights ${SIMPLEVIS_DATA}/workspace/$BASE_MODEL --project ${SIMPLEVIS_DATA}/workspace/runs