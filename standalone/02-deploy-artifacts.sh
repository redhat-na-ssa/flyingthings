#!/bin/bash
MINIO_ROUTE=`oc get route|grep -v console|grep -v NAME|awk '{print $2 }'`
python ../scripts/01-create-bucket.py $MINIO_ROUTE minioadmin minioadmin
python ../scripts/02-enable-versioning.py $MINIO_ROUTE minioadmin minioadmin
python ../scripts/03-upload-artifacts.py $MINIO_ROUTE minioadmin minioadmin
python ../scripts/04-tag-objects.py $MINIO_ROUTE minioadmin minioadmin
