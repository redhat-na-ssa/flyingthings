#!/bin/bash
cd $SIMPLEVIS_DATA/workspace
yolo train model=${SIMPLEVIS_DATA}/workspace/$BASE_MODEL batch=$BATCH_SIZE epochs=$NUM_EPOCHS data=classes.yaml project=${SIMPLEVIS_DATA}/workspace/runs exist_ok=True
