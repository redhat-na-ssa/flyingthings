#!/bin/bash
set -x
cd /opt/app-root/src/simplevis-data
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
chmod +x mc
./mc --config-dir=/opt/app-root/src/simplevis-data/mconfig config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure

# Get all model files from the latest training run
LATEST_MOD_FILES=$(./mc --config-dir miniocfg find myminio/$MINIO_BUCKET/models --tags "training-run=latest" --insecure)
echo "Latest model files: $LATEST_MOD_FILES"

# Loop through the file list and check for the pytorch model file
for file in $LATEST_MOD_FILES; do
    echo "$COMMAND $file"
        if [[ "$file" == *.pt ]]; then
            echo "Using pytorch model file: $file"
            ./mc --config-dir=/opt/app-root/src/simplevis-data/mconfig cp $file $WEIGHTS --insecure
        fi
    
done

rm ./mc
cd /opt/app-root/src
/usr/local/bin/uvicorn main:app --host 0.0.0.0