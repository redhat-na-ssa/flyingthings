#!/bin/bash
cd $SIMPLEVIS_DATA/workspace
yolo predict model=yolov8n.pt
curl $MINIO_CLIENT_URL/mc -o mc
chmod +x mc
./mc --config-dir miniocfg config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
./mc --config-dir miniocfg cp /workspace/yolov8n.py myminio/flyingthings/model_pretrained.pt --insecure
./mc --config-dir miniocfg cp /workspace/yolov8n.py myminio/flyingthings/model_custom.pt --insecure
