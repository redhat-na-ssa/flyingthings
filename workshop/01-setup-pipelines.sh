#!/bin/bash

setup_pipelines(){
  # apply pipeline objects
  oc apply -f pipelines/tasks
  oc apply -f pipelines/manifests
}

setup_pipelines
