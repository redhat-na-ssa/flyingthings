#!/bin/bash

oc new-project flyingthings-standalone
cd ../pipelines
oc apply -f .