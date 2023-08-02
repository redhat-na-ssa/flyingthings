#!/bin/bash
cd $SIMPLEVIS_DATA/workspace
# yolo export model=${SIMPLEVIS_DATA}/workspace/runs/train/weights/best.pt format=onnx
python /usr/local/lib/python3.9/site-packages/yolov5/export.py --weights ${SIMPLEVIS_DATA}/workspace/runs/train/weights/best.pt --include onnx
