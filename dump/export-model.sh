#!/bin/sh

SIMPLEVIS_DATA=/opt/app-root/src/simplevis-data

cd $SIMPLEVIS_DATA/workspace
# yolo export model=${SIMPLEVIS_DATA}/workspace/runs/train/weights/best.pt format=onnx
python3 /usr/local/lib/python3.9/site-packages/yolov5/export.py --weights ${SIMPLEVIS_DATA}/workspace/runs/exp/weights/best.pt --include onnx
