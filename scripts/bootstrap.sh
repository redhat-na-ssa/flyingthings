#!/bin/bash
# shellcheck disable=SC2015,SC1091

debug(){
echo "PWD:  $(pwd)"
echo "PATH: ${PATH}"
}

# get functions
get_functions(){
  echo -e "functions:\n"
  sed -n '/(){/ s/(){$//p' "$(dirname "$0")/$(basename "$0")"
}

usage(){
  echo "
  usage: source scripts/funtions.sh
  "
  # get_functions
}

is_sourced() {
  if [ -n "$ZSH_VERSION" ]; then
      case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else  # Add additional POSIX-compatible shell names here, if needed.
      case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1  # NOT sourced.
}

setup_venv(){
  python3 -m venv venv
  source venv/bin/activate
  pip install -q -U pip

  check_venv || usage
}

check_venv(){
  # activate python venv
  [ -d venv ] && . venv/bin/activate || setup_venv
  [ -e requirements.txt ] && pip install -q -r requirements.txt
}

# check login
check_oc_login(){
  oc cluster-info | head -n1
  oc whoami || exit 1
  echo
  sleep 3
}

wait_for_crd(){
  CRD=${1}
  until oc get crd "${CRD}" >/dev/null 2>&1
    do sleep 1
  done
}

aws_create_gpu_machineset(){
  # https://aws.amazon.com/ec2/instance-types/g4
  # single gpu: g4dn.{2,4,8,16}xlarge
  # multi gpu: g4dn.12xlarge
  # cheapest: g4ad.4xlarge
  INSTANCE_TYPE=${1:-g4dn.4xlarge}
  MACHINE_SET=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep worker | head -n1)

  oc -n openshift-machine-api get "${MACHINE_SET}" -o yaml | \
    sed '/machine/ s/-worker/-gpu/g
      /name/ s/-worker/-gpu/g
      s/instanceType.*/instanceType: '"${INSTANCE_TYPE}"'/
      s/replicas.*/replicas: 0/' | \
    oc apply -f -

  MACHINE_SET_GPU=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep gpu | head -n1)

  oc -n openshift-machine-api \
    patch ${MACHINE_SET_GPU} \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"cluster-api/accelerator":"nvidia-gpu"}}}}}}'
  
    oc -n openshift-machine-api \
    patch ${MACHINE_SET_GPU} \
    --type=merge --patch '{"metadata":{"labels":{"cluster-api/accelerator":"nvidia-gpu"}}}'

}

ocp_create_machineset_autoscale(){
  MACHINE_MIN=${1:-0}
  MACHINE_MAX=${2:-4}
  MACHINE_SETS=${3:-$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | sed 's@.*/@@' )}

  for set in ${MACHINE_SETS}
  do
cat << YAML | oc apply -f -
apiVersion: "autoscaling.openshift.io/v1beta1"
kind: "MachineAutoscaler"
metadata:
  name: "${set}"
  namespace: "openshift-machine-api"
spec:
  minReplicas: ${MACHINE_MIN}
  maxReplicas: ${MACHINE_MAX}
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: "${set}"
YAML
  done
}

setup_cluster_autoscaling(){
  # setup cluster autoscaling
  oc apply -k components/configs/autoscale/overlays/default

  aws_create_gpu_machineset
  ocp_create_machineset_autoscale
}

setup_operator_devspaces(){
  # setup devspaces
  oc apply -k components/operators/devspaces/operator/overlays/stable
  wait_for_crd checlusters.org.eclipse.che
  oc apply -k components/operators/devspaces/instance/overlays/default
}

setup_operator_nfd(){
  # setup nfd operator
  oc apply -k components/operators/nfd/operator/overlays/stable
  wait_for_crd nodefeaturediscoveries.nfd.openshift.io
  oc apply -k components/operators/nfd/instance/overlays/default
}

setup_operator_nvidia(){
  # setup nvidia gpu operator
  oc apply -k components/operators/gpu-operator-certified/operator/overlays/stable
  wait_for_crd clusterpolicies.nvidia.com
  oc apply -k components/operators/gpu-operator-certified/instance/overlays/default
}

setup_operator_pipelines(){
  # setup tekton operator
  oc apply -k components/operators/openshift-pipelines-operator-rh/operator/overlays/latest
  wait_for_crd pipelines.tekton.dev
}

setup_namespaces(){
  # setup namespaces
  oc apply -k components/configs/namespaces/overlays/default
}

setup_demo(){
  setup_namespaces
  setup_operator_pipelines
  setup_operator_nfd
  setup_operator_nvidia
  setup_operator_devspaces
}

is_sourced && return 0

check_oc_login

setup_demo
