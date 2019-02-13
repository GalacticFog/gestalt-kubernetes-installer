#!/bin/bash
#
# Removes Gestalt Platform components from the Kubernetes cluster in the current kubectl context
#
# First deletes Gestalt components from the 'gestalt-system' namespace, then prompts user to 
# delete namespaces in UUID format, assuming those namespaces were created as part of the
# Gestalt Platform installation.

# TODO: implement command-line parameters
DEBUG=0

log_debug() {
  [[ $DEBUG -ne 0 ]] && echo "$@"
}

exit_with_error() {
  echo "[Error] $@"
  exit 1
}

exit_on_error() {
  if [ $? -ne 0 ]; then
    exit_with_error $1
  fi
}

check_for_required_tools() {
  which kubectl   >/dev/null 2>&1 ; exit_on_error "'kubectl' command not found, aborting."
}

check_for_kube() {
  echo "Checking for Kubernetes..."
  local kubecontext="`kubectl config current-context`"

  if [ ! -z "$target_kube_context" ]; then
      if [ "$kubecontext" != "$target_kube_context" ]; then
      do_prompt_to_continue \
        "Warning - The current Kubernetes context name '$kubecontext' does not match the expected value, '$target_kube_context'" \
        "Proceed anyway?"
      fi
  fi

  kube_cluster_info=$(kubectl cluster-info)
  exit_on_error "Kubernetes cluster not accessible, aborting."

  echo "OK - Kubernetes cluster '$kubecontext' is accessible."
}

prompt_to_continue(){
  echo ""
  echo "Gestalt Platform will be removed from Kubernetes cluster '`kubectl config current-context`'."
  echo "This cannot be undone."
  echo ""

  while true; do
      read -p "$* Proceed? [y/n]: " yn
      case $yn in
          [Yy]*) break;;
          [Nn]*) echo "Aborted" ; exit  1 ;;
      esac
  done
  
  echo
#  read -p "Enter the name of the cluster to confirm deletion [`kubectl config current-context`]: " value
#  case $value in
#      `kubectl config current-context`) return 0  ;;
#      *) echo "Aborted" ; exit  1 ;;
#  esac
}

remove_gestalt_platform() {

  # First, check if the namespace is even present

  kubectl get namespace $RELEASE_NAMESPACE > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Nothing to do - Kubernetes namespace '$RELEASE_NAMESPACE' isn't present."
    return 0
  fi

  # Remove the Gestalt Platform application manifest if the cluster has the Applications API installed.
  # Send all output to /dev/null and ignore failures in case the Application API isn't installed.
  kubectl delete applications --timeout=60s --all --namespace $RELEASE_NAMESPACE 2>&1 1>/dev/null

  # The echo statement resets the value of $? and prints some space to the console...
  echo ""

  # Remove all the Gestalt Platform standard resources and display output.
  echo "Removing Gestalt Platform components from '$RELEASE_NAMESPACE' namespace..."
  kubectl delete daemonsets,replicasets,statefulsets,services,deployments,jobs,pods,rc,secrets,configmaps,pvc,ingresses \
    --timeout=30s --all --namespace $RELEASE_NAMESPACE

  if [ $? -ne 0 ]; then
  
    # Removal was unsuccessful, try force removal

    echo ""
    echo "Warning: 'kubectl delete' failed, re-attempting with forceful delete..."
    echo ""
    
    # The --force flag helps clean up pods stuck in the 'Terminating' state
    kubectl delete daemonsets,replicasets,statefulsets,services,deployments,jobs,pods,rc,secrets,configmaps,pvc,ingresses \
      --grace-period=0 --force --all --namespace $RELEASE_NAMESPACE
  fi
}

remove_gestalt_cluster_role_bindings() {
  echo "Removing gestalt cluster role bindings..."
  kubectl get clusterrolebinding -l meta/fqon -o name | xargs kubectl delete
}

get_release_namespace() {
  # local service=${1:-gestalt-meta}
  # kubectl get svc --all-namespaces -o json | jq -r --arg SVC ${service} '.items[].metadata | select(.name==$SVC) | .namespace'

  . gestalt.conf
  echo $RELEASE_NAMESPACE
}


remove_gestalt_namespaces() {
  local namespaces=$(kubectl get namespace -l meta/fqon -o name)
  if [ $? -eq 0 ] && [ ! -z "$namespaces" ]; then
    echo ""
    echo "Warning: There are existing namespaces that appear to be from a prior install:"
    echo "$namespaces"
    echo ""

    while true; do
        read -p "$* Delete these namespaces? [y/n]: " yn
        case $yn in
            [Yy]*) do_delete_namespaces $namespaces ; break ;;
            [Nn]*) break ;;
        esac
    done
  else
    echo "No gestalt namespaces found"
  fi
}

do_delete_namespaces() {
  kubectl delete $@
  echo "Done deleting namespaces."
}

# Check for pre-reqs
check_for_required_tools
check_for_kube

prompt_to_continue

RELEASE_NAMESPACE=$(get_release_namespace)
remove_gestalt_platform

remove_gestalt_cluster_role_bindings

remove_gestalt_namespaces

echo "Done."
