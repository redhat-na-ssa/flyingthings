#!/bin/bash
cd $SIMPLEVIS_DATA/workspace
yolo export model=${SIMPLEVIS_DATA}/workspace/$BASE_MODEL format=torchscript
