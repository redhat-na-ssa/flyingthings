#!/bin/bash
oc apply -k minio
MINIO_ROUTE=`oc get route|grep -v console|grep -v NAME|awk '{print $2 }'`
echo $MINIO_ROUTE

oc create configmap flyingthings-configmap --from-literal=AWS_ACCESS_KEY_ID=minioadmin \
    --from-literal=AWS_SECRET_ACCESS_KEY=minioadmin \
    --from-literal=AWS_S3_ENDPOINT=$MINIO_ROUTE \
    --from-literal=AWS_S3_BUCKET=flyingthings

oc apply -k notebook