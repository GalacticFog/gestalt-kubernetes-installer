#!/bin/bash
#
# Removes Gestalt Platform components from the Kubernetes cluster in the current kubectl context
#
# First deletes Gestalt components from the 'gestalt-system' namespace, then prompts user to 
# delete namespaces in UUID format, assuming those namespaces were created as part of the
# Gestalt Platform installation.

# TODO: implement command-line parameters
DEBUG=1
SKIP_ACKNOWLEDGEMENT=1

source ./helpers/tool-functions.sh

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
}

prompt_to_acknowledge(){
  echo
  read -p "Enter the name of the cluster to confirm deletion [`kubectl config current-context`]: " value
  case $value in
      `kubectl config current-context`) return 0  ;;
      *) echo "Aborted" ; exit  1 ;;
  esac
}

prompt_to_remove_namespace(){
  local NS=$1
  [ -z "$NS" ] && return
  echo ""
  echo "Gestalt Platform will be removed the '$NS' namespace from the Kubernetes cluster '`kubectl config current-context`'."
  echo "This cannot be undone."
  echo ""

  while true; do
      read -p "$* Proceed? [y/n]: " yn
      case $yn in
          [Yy]*) do_delete_namespaces "namespace/${NS}"; break;;
          [Nn]*) break;;
      esac
  done
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
check_for_kubectl
check_for_kube

. gestalt.conf

prompt_to_continue
[ $SKIP_ACKNOWLEDGEMENT -eq 0 ] && prompt_to_acknowledge

# TODO handle multiple releases in the same cluster
RELEASE_NAMESPACE=$(find_namespace "${RELEASE_NAMESPACE}")
[ $? -ne 0 ] && exit 1

remove_gestalt_platform

remove_gestalt_cluster_role_bindings

remove_gestalt_namespaces

prompt_to_remove_namespace "${RELEASE_NAMESPACE}"

echo "Done."
