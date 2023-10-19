#!/bin/sh
oc project flyingthings-standalone
nbpod=`oc get po|grep -v NAME|grep flyingthings-notebook|awk '{ print $1 }'`
oc cp ../notebooks/01-training-prep.ipynb $nbpod:/opt/app-root/src/
oc cp ../notebooks/02-object-detect-train.ipynb $nbpod:/opt/app-root/src/
oc cp ../notebooks/99-utils.ipynb $nbpod:/opt/app-root/src/
oc cp ../pipelines/scripts/classes.yaml.j2 $nbpod:/opt/app-root/src/
