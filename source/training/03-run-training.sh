#!/bin/bash
set -x
cd $SIMPLEVIS_DATA/workspace
cp -R datasets/* /usr/local/lib/python3.9/site-packages/yolov5/datasets
ls -l /usr/local/lib/python3.9/site-packages/yolov5
ls -l /usr/local/lib/python3.9/site-packages/yolov5/datasets
# yolo train model=${SIMPLEVIS_DATA}/workspace/$BASE_MODEL batch=$BATCH_SIZE epochs=$NUM_EPOCHS data=classes.yaml project=${SIMPLEVIS_DATA}/workspace/runs exist_ok=True
python3 /usr/local/lib/python3.9/site-packages/yolov5/train.py --img 640 --epochs 3 --data classes.yaml --weights ${SIMPLEVIS_DATA}/workspace/$BASE_MODEL --project ${SIMPLEVIS_DATA}/workspace/runs