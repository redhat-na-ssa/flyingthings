#!/bin/bash

oc new-project flyingthings-standalone

cd ../pipelines/manifests
oc apply -f 00-flyingthings-images-pipeline.yaml
