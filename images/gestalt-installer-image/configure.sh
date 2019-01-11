#!/bin/bash

############################################
# General Settings and References
############################################

  # Credentials and Configs
  conf_gestalt_conf="./gestalt.conf"
  conf_gestalt_creds="./credentials.conf"

  # Scripts and Utilities
  conf_script_folder="./conf-scripts"
  installer_config="${conf_script_folder}/build-config.sh"
  installer_spec="${conf_script_folder}/build-installer-spec.sh"

  utility_folder="${conf_script_folder}/utilities"
  utility_bash="./scripts/utility-bash.sh"
  utility_gestalt_install="${utility_folder}/utility-gestalt-installer-run.sh"
  utility_kubectl="${utility_folder}/utility-kubectl.sh"

  #Generated Files
  conf_install="./install-config.json"
  kube_install="./installer.yaml"

############################################
# Main base utility script
############################################

  if [ ! -f "${utility_bash}" ]; then
    echo "[ERROR] Utility file '${utility_bash}' not found, aborting."
    exit 1
  else
    . "${utility_bash}"
    exit_on_error "Unable to source utility file '${utility_bash}', aborting."
    log_debug "Sourced '${utility_bash}'"
  fi

############################################
# Other common configurations and utilities / scripts
############################################

source_required_files "${utility_gestalt_install} ${utility_kubectl} ${conf_gestalt_conf} ${conf_gestalt_creds}"

########################################################################################
# Create install scripts and configs
########################################################################################

#Check for required tools
check_for_required_tools_gestalt_installer

kubectl_version=$(kubectl version --client)
>&2 echo "kubectl version = ${kubectl_version}"
log_debug "" && log_debug "[Info] Obtain current context 'kubectl config current-context' ..."
kubectl_context=$(kubectl config current-context)
exit_on_error "Unable determine current context 'kubectl config current-context', aborting."

check_for_kube

kube_process_kubeconfig
exit_on_error "Failed to process kubeconfig, aborting."

log_debug "Generate Installer Configuration '. ${installer_config}'"
. "${installer_config}" "${conf_install}"
exit_on_error "Issue during building '${installer_config}'"
log_debug "Generated Installer Configuration: `cat ${conf_install}`" && log_debug ""
validate_json ${conf_install}

log_debug "Generate Installer Spec '. ${installer_spec} ${kube_install}'"
. "${installer_spec}" "${kube_install}"

echo "Installer Configurations Generated"
