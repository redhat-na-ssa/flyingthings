#!/bin/bash
WORKSPACE_DIR=/opt/app-root/src/workspace
MINCFG=$WORKSPACE_DIR/miniocfg
cd $SIMPLEVIS_DATA/workspace
./mc --config-dir ${MINCFG} cp $SOURCE_DIR/artifacts/flyingthings-yolo.zip myminio/$MINIO_BUCKET --insecure
./mc --config-dir ${MINCFG} cp $SOURCE_DIR/notebooks/01-training-prep.ipynb myminio/$MINIO_BUCKET --insecure
./mc --config-dir ${MINCFG} cp $SOURCE_DIR/notebooks/02-object-detect-train.ipynb myminio/$MINIO_BUCKET --insecure
./mc --config-dir ${MINCFG} cp $SOURCE_DIR/notebooks/99-utils.ipynb myminio/$MINIO_BUCKET --insecure