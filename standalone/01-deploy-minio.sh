#!/bin/bash
oc apply -k minio
MINIO_ROUTE=`oc get route|grep -v console|grep -v NAME|awk '{print $2 }'`
oc create configmap flyingthings-config --from-literal=MINIO_ROUTE=$MINIO_ROUTE
