#!/bin/bash

TIMEOUT=8

check_namespace(){
  DEFAULT_NAMESPACE=ml-demo
  NAMESPACE=${1:-${DEFAULT_NAMESPACE}}
  
  echo "Deploying in NAMESPACE: ${NAMESPACE}"
  echo ""
  echo "NOTICE: Verify the information above is correct"
  echo "Use CTRL + C to cancel"
  
  # [ -n "${1}" ] && TIMEOUT=0
  sleep "${TIMEOUT}"

  oc project "${NAMESPACE}" >/dev/null 2>&1 || oc new-project "${NAMESPACE}"
}

setup_pipelines(){
  # apply pipeline objects
  oc apply -k pipelines/tasks
  oc apply -k pipelines/manifests
}

check_namespace "$@"
setup_pipelines
