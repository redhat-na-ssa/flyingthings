#!/bin/bash

cd ../pipelines/manifests

# tkn pipeline start run-training-pipeline \
# -w name=workspace,\
# volumeClaimTemplateFile=custom-pvc.yaml \
# -p IMAGE=image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/training-job:latest \
# -p BATCH_SIZE="2" \
# -p NUM_EPOCHS="1" \
# -p WEIGHTS=flyingthings.pt \
# -p BASE_MODEL=model_pretrained.pt \
# -p MODEL_CLASSES=flyingthings.yaml \
# -p MINIO_ENDPOINT=http://minio:9000 \
# -p DATASET_ZIP=flyingthings-yolo.zip \
# -p SIMPLEVIS_DATA=/opt/app-root/src/simplevis-data \
# -p BASEDIR=/opt/app-root/src \
# -p MINIO_BUCKET=flyingthings \
# -p MINIO_ACCESSKEY=minioadmin \
# -p MINIO_SECRETKEY=minioadmin \
# -p MINIO_CLIENT_URL=https://dl.min.io/client/mc/release/linux-amd64 \
# --use-param-defaults --showlog

tkn pipeline start run-training \
-p BATCH_SIZE="32" \
-p NUM_EPOCHS="50" \
--use-param-defaults --showlog

