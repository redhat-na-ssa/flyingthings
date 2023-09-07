#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Warning: No project provided. Please provide a target project name."
    exit 1
fi

# Assign the first argument to the TABLESPACE variable
TABLESPACE=$1

oc new-project $TABLESPACE

oc create -f ../pipelines/tasks
oc create -f ../pipelines/manifests


# Exit the script gracefully
exit 0

