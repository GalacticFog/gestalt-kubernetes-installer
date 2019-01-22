#!/bin/bash

############################################
# Utilities: Index
############################################

# kube_check_for_required_namespace - Validates whether specified kubernetes namespace exists

############################################
# Utilities: START
############################################

kube_check_for_required_namespace() {

  [[ $# -ne 1 ]] && echo && exit_with_error "[${FUNCNAME[0]}] Function expects 1 parameter ($# provided) [$@], aborting."
  f_namespace_name=$1 

  # # TODO: Make debug echo "Checking for existing Kubernetes namespace '$install_namespace'..."
  kubectl get namespace ${f_namespace_name} > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo ""
    echo "Kubernetes namespace '${f_namespace_name}' doesn't exist, aborting.  To create the namespace, run the following command:"
    echo ""
    echo "  kubectl create namespace ${f_namespace_name}"
    echo ""
    echo "Then ensure that 'Full Control' grants are provided for the '${f_namespace_name}/default' service account."
    echo ""
    exit_with_error "Kubernetes namespace '${f_namespace_name}' doesn't exist, aborting."
  fi
  echo "OK - Kubernetes namespace '${f_namespace_name}' is present."
}


kube_copy_secret () {

  [[ $# -ne 4 ]] && echo && exit_with_error "[${FUNCNAME[0]}] Function expects 4 parameter(-s) ($# provided) [$@], aborting."
  f_source_namespace_name=$1 
  f_source_secret_name=$2
  f_target_namespace_name=$3 
  f_target_secret_name=$4

  kubectl get secret -n ${f_source_namespace_name} ${f_source_secret_name} -oyaml > secret-${f_source_secret_name}.yaml
  exit_on_error "Unable obtain secret 'kubectl get secret -n ${f_source_namespace_name} ${f_source_secret_name} -oyaml' , aborting."

  # Strip out and rename
  cat secret-${f_source_secret_name}.yaml | sed "s/name: ${f_source_secret_name}/name: ${f_target_secret_name}/" | grep -v 'creationTimestamp:' | grep -v 'namespace:' | grep -v 'resourceVersion:' | grep -v 'selfLink:' | grep -v 'uid:' > secret-${f_target_secret_name}.yaml
  exit_on_error "Unable manipulate source secret '${f_source_namespace_name}:${f_source_secret_name}' , aborting."

  kubectl apply -f secret-${f_target_secret_name}.yaml -n ${f_target_namespace_name}
  exit_on_error "Unable create target secret '${f_target_namespace_name}:${f_target_secret_name}' , aborting."

  echo "OK - Secret Copied to '${f_target_namespace_name}:${f_target_secret_name}'"

}

############################################
# Utilities: END
############################################
