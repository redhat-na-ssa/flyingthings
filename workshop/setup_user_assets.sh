#!/bin/bash

# create assets in each user's project
for i in $(seq -w 1 10); do
  echo "Current user: user$i"
  oc project user$i
  workshop/00-user-components.sh
done

for i in $(seq -w 1 10); do
  echo "Current user: user$i"
  oc project user$i
  workshop/01-setup-pipelines.sh
done