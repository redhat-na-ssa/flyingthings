#!/bin/bash
cd $SIMPLEVIS_DATA/workspace
$SIMPLEVIS_DATA/dataprep.sh
tree -d $SIMPLEVIS_DATA
ls -l ${SIMPLEVIS_DATA}/
cd $SIMPLEVIS_DATA/workspace
$SIMPLEVIS_DATA/distribute-files.py
yolo train model=${SIMPLEVIS_DATA}/workspace/$BASE_MODEL batch=$BATCH_SIZE epochs=$NUM_EPOCHS data=$MODEL_CLASSES project=${SIMPLEVIS_DATA}/workspace/runs exist_ok=True
$SIMPLEVIS_DATA/push-results.sh