#!/bin/bash

# Grant access to all the CV training image streams
for i in $(seq -w 1 10); do
  oc adm policy add-role-to-user view user$i -n ml-demo
  oc adm policy add-role-to-user system:image-puller user$i -n ml-demo
done


for i in $(seq -w 1 10); do
  echo "Current user: user$i"
  oc project user$i
  workshop/01-setup-pipelines.sh
done