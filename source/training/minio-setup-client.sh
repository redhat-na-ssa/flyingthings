#!/bin/sh

MINCFG=miniocfg

curl $MINIO_CLIENT_URL/mc -o mc
chmod +x mc
./mc --config-dir ${MINCFG} config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
