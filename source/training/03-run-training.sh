#!/bin/bash
cd $SIMPLEVIS_DATA/workspace
yolo train model=${SIMPLEVIS_DATA}/workspace/$BASE_MODEL batch=$BATCH_SIZE epochs=$NUM_EPOCHS data=$MODEL_CLASSES project=${SIMPLEVIS_DATA}/workspace/runs exist_ok=True
