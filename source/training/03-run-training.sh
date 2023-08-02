#!/bin/bash
git config --global --add safe.directory /usr/local/lib/python3.9/site-packages/yolov5
cd $SIMPLEVIS_DATA/workspace
# yolo train model=${SIMPLEVIS_DATA}/workspace/$BASE_MODEL batch=$BATCH_SIZE epochs=$NUM_EPOCHS data=classes.yaml project=${SIMPLEVIS_DATA}/workspace/runs exist_ok=True
python3 /usr/local/lib/python3.9/site-packages/yolov5/train.py --img 640 --epochs 3 --data classes.yaml --weights ${SIMPLEVIS_DATA}/workspace/$BASE_MODEL --project ${SIMPLEVIS_DATA}/workspace