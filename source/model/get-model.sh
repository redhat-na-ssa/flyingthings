#!/bin/bash
cd /opt/app-root/src/simplevis-data
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
chmod +x mc
./mc --config-dir=/opt/app-root/src/simplevis-data/mconfig config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
./mc --config-dir=/opt/app-root/src/simplevis-data/mconfig cp myminio/$MINIO_BUCKET/$WEIGHTS $WEIGHTS --insecure
rm ./mc
cd /opt/app-root/src
/usr/local/bin/uvicorn main:app --host 0.0.0.0