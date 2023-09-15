#!/bin/sh

MINIO_CLIENT_URL=https://dl.min.io/client/mc/release/linux-amd64

MINCFG=miniocfg

curl $MINIO_CLIENT_URL/mc -o mc
chmod +x mc
./mc --config-dir ${MINCFG} config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
