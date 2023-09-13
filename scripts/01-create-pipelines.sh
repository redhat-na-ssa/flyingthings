#!/bin/sh

select_namespace(){
  if [ $# -eq 0 ]; then
    NAMESPACE=${1:-modemo}
    echo "NOTICE: No namespace / project name provided"
  fi

  echo "NAMESPACE: ${NAMESPACE}"
  oc project "${NAMESPACE}" &>/dev/null || oc new-project "${NAMESPACE}"
}

create_pipelines(){
  
  select_namespace

  # apply pipeline objects
  oc apply -f pipelines/tasks
  oc apply -f pipelines/manifests
}

create_pipelines
