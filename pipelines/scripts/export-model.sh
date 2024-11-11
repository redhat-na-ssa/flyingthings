#!/bin/bash
cd "$SIMPLEVIS_DATA"/workspace || exit
yolo export model="${SIMPLEVIS_DATA}"/workspace/runs/train/weights/best.pt format=torchscript
