#!/bin/bash

oc new-project flyingthings-standalone

oc apply -f ../pipelines/tasks
oc apply -f ../pipelines/manifests

