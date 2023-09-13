#!/bin/sh

select_namespace(){
  if [ $# -eq 0 ]; then
    NAMESPACE=${1:-modemo}
    echo "NOTICE: No namespace / project name provided"
  fi

  echo "NAMESPACE: ${NAMESPACE}"
  oc project "${NAMESPACE}" &>/dev/null || oc new-project "${NAMESPACE}"
}

setup_minio(){
  
  select_namespace
  oc apply -k components/demo/minio
}

setup_minio
