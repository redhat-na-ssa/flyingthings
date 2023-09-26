#!/bin/bash
# shellcheck disable=SC2015,SC1091,SC2119,SC2120

set -e

check_shell(){
  [ "${SHELL}" = "/bin/bash" ] && return
  echo "Please verify you are running this script in bash shell"
}

# check_tkn(){
#   return
# }

check_shell


debug(){
echo "PWD:  $(pwd)"
echo "PATH: ${PATH}"
}

usage(){
  echo "
  If you want to setup autoscaling in AWS run the following:
  
    . scripts/bootstrap.sh && setup_aws_cluster_autoscaling

  "
}

is_sourced() {
  if [ -n "$ZSH_VERSION" ]; then
      case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else  # Add additional POSIX-compatible shell names here, if needed.
      case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1  # NOT sourced.
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

ocp_aws_create_gpu_machineset(){
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

  # cosmetic
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_GPU}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"node-role.kubernetes.io/gpu":""}}}}}}'

  # should help auto provisioner
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_GPU}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"cluster-api/accelerator":"nvidia-gpu"}}}}}}'
  
    oc -n openshift-machine-api \
    patch "${MACHINE_SET_GPU}" \
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

ocp_scale_all_machineset(){
  REPLICAS=${1:-1}
  MACHINE_SETS=${2:-$(oc -n openshift-machine-api get machineset -o name)}

  # scale workers
  echo "${MACHINE_SETS}" | \
    xargs \
      oc -n openshift-machine-api \
      scale --replicas="${REPLICAS}"

}

setup_dashboard_nvidia_monitor(){
  curl -sLfO https://github.com/NVIDIA/dcgm-exporter/raw/main/grafana/dcgm-exporter-dashboard.json
  oc create configmap nvidia-dcgm-exporter-dashboard -n openshift-config-managed --from-file=dcgm-exporter-dashboard.json || true
  oc label configmap nvidia-dcgm-exporter-dashboard -n openshift-config-managed "console.openshift.io/dashboard=true" --overwrite
  oc label configmap nvidia-dcgm-exporter-dashboard -n openshift-config-managed "console.openshift.io/odc-dashboard=true" --overwrite
  oc -n openshift-config-managed get cm nvidia-dcgm-exporter-dashboard --show-labels
}

setup_dashboard_nvidia_admin(){
  helm repo add rh-ecosystem-edge https://rh-ecosystem-edge.github.io/console-plugin-nvidia-gpu || true
  helm repo update
  helm upgrade --install -n nvidia-gpu-operator console-plugin-nvidia-gpu rh-ecosystem-edge/console-plugin-nvidia-gpu

  oc get consoles.operator.openshift.io cluster --output=jsonpath="{.spec.plugins}" || true
  oc patch consoles.operator.openshift.io cluster --patch '{ "spec": { "plugins": ["console-plugin-nvidia-gpu"] } }' --type=merge || true
  oc patch consoles.operator.openshift.io cluster --patch '[{"op": "add", "path": "/spec/plugins/-", "value": "console-plugin-nvidia-gpu" }]' --type=json || true
  oc patch clusterpolicies.nvidia.com gpu-cluster-policy --patch '{ "spec": { "dcgmExporter": { "config": { "name": "console-plugin-nvidia-gpu" } } } }' --type=merge || true
  oc -n nvidia-gpu-operator get all -l app.kubernetes.io/name=console-plugin-nvidia-gpu
}

setup_aws_cluster_autoscaling(){
  # setup cluster autoscaling
  oc apply -k components/configs/autoscale/overlays/gpus

  ocp_aws_create_gpu_machineset g4ad.4xlarge
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
  oc apply -k components/operators/nfd/instance/overlays/only-nvidia
}

setup_operator_nvidia(){
  # setup nvidia gpu operator
  oc apply -k components/operators/gpu-operator-certified/operator/overlays/stable
  wait_for_crd clusterpolicies.nvidia.com
  oc apply -k components/operators/gpu-operator-certified/instance/overlays/time-slicing
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

check_cluster_version(){
  OCP_VERSION=$(oc version | sed -n '/Server Version: / s/Server Version: //p')
  AVOID_VERSIONS=("4.12.12")
  TESTED_VERSIONS=("4.12.32" "4.12.33")

  echo "Current OCP version: ${OCP_VERSION}"
  echo "Tested OCP version(s): ${TESTED_VERSIONS[*]}"
  echo ""

  # shellcheck disable=SC2076
  if [[ " ${AVOID_VERSIONS[*]} " =~ " ${OCP_VERSION} " ]]; then
    echo "OCP version ${OCP_VERSION} is known to have issues with this demo"
    echo ""
    echo 'Recommend: "oc adm upgrade --to-latest=true"'
    echo ""
  fi
}

setup_demo(){
  check_cluster_version
  setup_namespaces
  
  setup_operator_pipelines
  setup_operator_nfd
  
  setup_operator_nvidia
  setup_dashboard_nvidia_monitor
  setup_dashboard_nvidia_admin

  setup_operator_devspaces
  usage
}

is_sourced && check_shell && return

check_oc_login

setup_demo
