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

log_debug "Generate Installer Configuration '. ${installer_config}'"
. "${installer_config}"
exit_on_error "Issue during building '${installer_config}'"

log_debug "Generate Installer Spec '. ${installer_spec}'"
. "${installer_spec}"

# TODO: Move this into the installer image
cat config/install-config.yaml | ../gestalt-installer-image/bin/yaml2json > ${conf_install}
exit_on_error "Failed to generate ${conf_install}"

echo
echo "Installer Configurations Generated at '${conf_install}'"