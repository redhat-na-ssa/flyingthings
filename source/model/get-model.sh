#!/bin/bash
cd /opt/app-root/src/simplevis-data
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
chmod +x mc
./mc --config-dir=/opt/app-root/src/simplevis-data/mconfig config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure

# Check if the file exists in the bucket
file_exists=$(mc ls "myminio/$MINIO_BUCKET/$WEIGHTS" 2>/dev/null)

if [[ -z "${file_exists}" ]]; then
  echo "File not found in the bucket."
  yolo train data=coco128.yaml model=yolov8n.pt epochs=1 lr0=0.01 # TODO: just need to get the yolov8n.pt
  mv yolov8n.pt model_custom.pt
  # copy the pretrained model to the bucket
  ./mc --config-dir=/opt/app-root/src/simplevis-data/mconfig cp model_custom.pt myminio/$MINIO_BUCKET/model_pretrained.pt --insecure
else
  # Pull the file from the bucket
  ./mc --config-dir=/opt/app-root/src/simplevis-data/mconfig cp myminio/$MINIO_BUCKET/$WEIGHTS $WEIGHTS --insecure
  exit_code=$?

  if [[ ${exit_code} -eq 0 ]]; then
    echo "File pulled successfully."
  else
    echo "Failed to pull the file from the bucket."
  fi
fi

rm ./mc
cd /opt/app-root/src
/usr/local/bin/uvicorn main:app --host 0.0.0.0
