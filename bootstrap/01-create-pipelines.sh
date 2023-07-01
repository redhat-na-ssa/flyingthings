#!/bin/bash

oc new-project flyingthings-standalone

cd ../pipelines/manifests
oc apply -f .

cd ../pipelines/runs
oc apply -f .