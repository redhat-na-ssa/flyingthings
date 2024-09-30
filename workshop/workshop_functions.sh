#!/bin/bash

# Define the range of${USERNAME}s and the GPU quota values
START=1             # Starting user number (user01, user02, etc.)
END=40              # Ending user number (user10, user11, etc.)
USERNAME=user

workshop_setup_user_assets(){
  START=${START:-1}
  END=${END:-40}

  # Grant access to all the CV training image streams
  for num in $(seq -f "%02g" $START $END); do
    oc adm policy add-role-to-user view ${USERNAME}${num} -n ml-demo
    oc adm policy add-role-to-user system:image-puller ${USERNAME}${num} -n ml-demo
    oc tag ml-demo/yolo-api:latest ${USERNAME}${num}/yolo-api:latest
    oc tag ml-demo/yolo-api:latest ${USERNAME}${num}/model-yolo:latest
  done

  for i in $(seq -f "%02g" $START $END); do
    echo "Current user: ${USERNAME}${num}"
    oc project ${USERNAME}${num}
    workshop/01-setup-pipelines.sh
    oc apply -k gitops/02-workshop-user-components
  done
}

setup_pipelines(){
  # apply pipeline objects
  oc apply -f ../pipelines/tasks
  oc apply -f ../pipelines/manifests
}
