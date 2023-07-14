#!/bin/bash
MINCFG=miniocfg
./mc --config-dir ${MINCFG} mb myminio/$MINIO_BUCKET --insecure
./mc --config-dir ${MINCFG} version enable myminio/$MINIO_BUCKET --insecure
