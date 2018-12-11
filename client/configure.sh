#!/bin/bash

# Source common project configuration and utilities
utility_file='./scripts/utilities/utility-project-check.sh'
if [ -f ${utility_file} ]; then
  . ${utility_file}
else
  echo "[ERROR] Project initialization script '${utility_file}' can not be located, aborting. "
  exit 1
fi

#Check for required tools
check_for_required_tools_gestalt_installer

log_debug "" && log_debug "[Info] Obtain current context 'kubectl config current-context' ..."
kubectl_context=$(kubectl config current-context)
exit_on_error "Unable determine current context '${kubectl} config current-context', aborting."

# check_for_kube

# TODO - Remove dependency on kubeconfig
kube_process_kubeconfig
exit_on_error "Failed to process kubeconfig, aborting."

## CACERTS file
echo "Checking for custom cacerts..."

# First, delete the original file so it won't be staged
[ -f ./stage/cacerts ] && \
  rm ./stage/cacerts

# Copy the file
if [ ! -z "$gestalt_security_cacerts_file" ]; then
  echo "Copying $gestalt_security_cacerts_file to ./stage/cacerts ..."
  cp $gestalt_security_cacerts_file ./stage/cacerts
  exit_on_error "Failed to copy $gestalt_security_cacerts_file"
else
  echo "No cacerts file"
fi

log_debug "Generate Installer Spec '. ${installer_spec}'"
. "${installer_spec}"

echo "$installer_spec generated."

echo
echo "Installer configuration succeeded."