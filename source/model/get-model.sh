#!/bin/bash
set -x
cd /opt/app-root/src/simplevis-data
curl $MINIO_CLIENT_URL/mc -o mc
chmod +x mc
MCONFIG=/opt/app-root/src/simplevis-data/mconfig
./mc --config-dir=$MCONFIG config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure

# If BASE_MODEL is pretrained, use the pretrained pytorch model file
allowed_models=("yolov8n.pt" "yolov5su.pt")
if [[ " ${allowed_models[@]} " =~ " ${BASE_MODEL} " ]]; then
  echo "Using pretrained model..."
  ./mc --config-dir=$MCONFIG cp  myminio/$MINIO_BUCKET/model_pretrained.pt $WEIGHTS --insecure
else
  echo "Using custom model..."

  # Get all model files from the latest training run
  LATEST_MOD_FILES=$(./mc --config-dir $MCONFIG find myminio/$MINIO_BUCKET/models --tags "training-run=latest" --insecure)
  echo "Latest model files: $LATEST_MOD_FILES"
  
  # Loop through the file list and check for the pytorch model file
  for file in $LATEST_MOD_FILES; do
      echo "$COMMAND $file"
          if [[ "$file" == *.pt ]]; then
              echo "Using pytorch model file: $file"
              ./mc --config-dir=$MCONFIG cp $file $WEIGHTS --insecure
          fi
  done
fi

rm ./mc
cd /opt/app-root/src
/usr/local/bin/uvicorn main:app --host 0.0.0.0