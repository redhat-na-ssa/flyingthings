#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Warning: No tablespace provided. Please provide a target TABLESPACE name."
    exit 1
fi

# Assign the first argument to the TABLESPACE variable
TABLESPACE=$1

oc new-project $TABLESPACE

oc apply -f ../pipelines/tasks
oc apply -f ../pipelines/manifests


# Exit the script gracefully
exit 0

