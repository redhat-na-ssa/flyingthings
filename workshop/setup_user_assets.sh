#!/bin/bash

# Define the range of users and the GPU quota values
START=1      # Starting user number (user01, user02, etc.)
END=2       # Ending user number (user10, user11, etc.)

# Grant access to all the CV training image streams
for i in $(seq -f "%02g" $START $END); do
  oc adm policy add-role-to-user view user$i -n ml-demo
  oc adm policy add-role-to-user system:image-puller user$i -n ml-demo
  oc tag ml-demo/yolo-api:latest user$i/yolo-api:latest
  oc tag ml-demo/yolo-api:latest user$i/model-yolo:latest
done


for i in $(seq -f "%02g" $START $END); do
  echo "Current user: user$i"
  oc project user$i
  workshop/01-setup-pipelines.sh
  oc apply -k gitops/02-workshop-user-components
done