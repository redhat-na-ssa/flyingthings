#!/bin/bash
oc apply -k minio
MINIO_ROUTE=`oc get route|grep -v console|grep -v NAME|awk '{print $2 }'`
# echo $MINIO_ROUTE

oc create configmap flyingthings-configmap --from-literal=AWS_ACCESS_KEY_ID=minioadmin \
    --from-literal=AWS_SECRET_ACCESS_KEY=minioadmin \
    --from-literal=AWS_S3_ENDPOINT=$MINIO_ROUTE \
    --from-literal=AWS_S3_BUCKET=flyingthings

SLEEP 13
python ../scripts/01-create-bucket.py $MINIO_ROUTE minioadmin minioadmin
python ../scripts/02-enable-versioning.py $MINIO_ROUTE minioadmin minioadmin
python ../scripts/03-upload-artifacts.py $MINIO_ROUTE minioadmin minioadmin
python ../scripts/04-tag-objects.py $MINIO_ROUTE minioadmin minioadmin

oc apply -k notebook
