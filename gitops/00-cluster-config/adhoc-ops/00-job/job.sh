#!/bin/bash

# shellcheck disable=SC1091
. /scripts/ocp.sh

ocp_allow_router_on_control_plane(){
  oc -n openshift-ingress-operator \
    patch ingresscontroller default \
    --type=merge --patch '{"spec":{"nodePlacement":{"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Exists","effect":"NoSchedule"}]}}}'
}

ocp_allow_registry_on_control_plane(){
  oc patch configs.imageregistry.operator.openshift.io/cluster \
    --type=merge --patch '{"spec":{"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Exists","effect":"NoSchedule"}]}}'
}

ocp_aws_cluster || exit 0
ocp_clean_install_pods
ocp_scale_machineset 1
ocp_control_nodes_not_schedulable
# ocp_set_scheduler_profile HighNodeUtilization
ocp_allow_router_on_control_plane
ocp_allow_registry_on_control_plane
