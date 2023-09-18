#!/bin/sh

check_namespace(){
  DEFAULT_NAMESPACE=ml-demo
  NAMESPACE=${1:-$(oc project -q 2>/dev/null || echo "${DEFAULT_NAMESPACE}")}
  
  echo "Deploying in NAMESPACE: ${NAMESPACE}"
  echo ""
  echo "NOTICE: Verify the information above is correct"
  echo "Use CTRL + C to cancel"
  
  sleep 8

  oc project "${NAMESPACE}" >/dev/null 2>&1 || oc new-project "${NAMESPACE}"
}

setup_minio(){
  oc apply -k components/demo/minio
}

setup_label_studio(){
  oc apply -k components/demo/label-studio/overlays/flyingthings
}

check_namespace "$@"
setup_minio
setup_label_studio
