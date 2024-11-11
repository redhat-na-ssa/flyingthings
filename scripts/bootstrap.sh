#!/bin/bash
# shellcheck disable=SC2015,SC1091,SC2119,SC2120
# set -e

################# standard init #################

check_shell(){
  [ -n "$BASH_VERSION" ] && return
  echo "Please verify you are running in bash shell"
  sleep 10
}

check_git_root(){
  if [ -d .git ] && [ -d scripts ]; then
    GIT_ROOT=$(pwd)
    export GIT_ROOT
    echo "GIT_ROOT: ${GIT_ROOT}"
  else
    echo "Please run this script from the root of the git repo"
    exit
  fi
}

get_script_path(){
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  echo "SCRIPT_DIR: ${SCRIPT_DIR}"
}


check_shell
check_git_root
get_script_path


is_sourced() {
  if [ -n "$ZSH_VERSION" ]; then
      case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else  # Add additional POSIX-compatible shell names here, if needed.
      case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1  # NOT sourced.
}

################# misc fucntions ################

ocp_check_login(){
  oc whoami || return 1
  oc cluster-info | head -n1
  echo
}

ocp_check_info(){
  ocp_check_login || return 1

  echo "NAMESPACE: $(oc project -q)"
  sleep "${SLEEP_SECONDS:-8}"
}

apply_firmly(){
  if [ ! -f "${1}/kustomization.yaml" ]; then
    echo "Please provide a dir with \"kustomization.yaml\""
    return 1
  fi

  until_true oc apply -k "${1}" 2>/dev/null
}

until_true(){
  echo "Running:" "${@}"
  until "${@}" 1>&2
  do
    echo "again..."
    sleep 20
  done

  echo "[OK]"
}

check_cluster_version(){
  OCP_VERSION=$(oc version | sed -n '/Server Version: / s/Server Version: //p')
  AVOID_VERSIONS=()
  TESTED_VERSIONS=("4.12.12" "4.12.33" "4.14.37")

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

################ demo functions ################

usage(){
  check_shell

  echo "
  You can run individual functions!

  example:
    setup_demo
    delete_demo
  "
}

setup_demo(){
  ocp_check_login
  check_cluster_version
  # apply_firmly gitops/cluster-default
  apply_firmly gitops
}

delete_demo(){
  echo "WARNING: This will remove operators and other compoents!"
  echo "WARNING: Manually clean up on a cluster that is not a default install"
  echo "Hit <CTRL> + C to abort"
  sleep "${SLEEP_SECONDS:-8}"

  # misc demo uninstall
  # oc delete --wait -k gitops/03-namespaces
  oc delete --wait --all checluster -A
  oc delete --wait -l operators.coreos.com/devspaces.openshift-operators csv -A
  oc delete --wait -l operators.coreos.com/openshift-pipelines-operator-rh.openshift-operators csv -A

  # standard demo uninstall
  oc delete --wait -k gitops/02-components
  oc delete --wait -k gitops/01-operator-configs
  oc delete --wait -k gitops/00-operators
  oc delete --wait -k gitops
}

is_sourced && usage || setup_demo
