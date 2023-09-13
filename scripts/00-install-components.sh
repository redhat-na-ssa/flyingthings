#!/bin/sh

check_namespace(){
  NAMESPACE=$(oc project -q)
  echo "NAMESPACE: ${NAMESPACE}"
  echo ""
  echo "NOTICE: Verify you are working in the correct namespace"
  echo "Use CTRL + C to cancel"
  sleep 8
}

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
  check_namespace
  
  oc apply -k components/demo/minio
}

setup_minio
