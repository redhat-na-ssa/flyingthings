#!/bin/bash

check_namespace(){
  DEFAULT_NAMESPACE=ml-demo
  NAMESPACE=${1:-${DEFAULT_NAMESPACE}}
  
  echo "Deploying in NAMESPACE: ${NAMESPACE}"
  echo ""
  echo "NOTICE: Verify the information above is correct"
  echo "Use CTRL + C to cancel"
  
  sleep 8

  oc project "${NAMESPACE}" >/dev/null 2>&1 || oc new-project "${NAMESPACE}"
}

setup_pipelines(){
  # apply pipeline objects
  oc apply -f pipelines/tasks
  oc apply -f pipelines/manifests
}

check_namespace "$@"
setup_pipelines
