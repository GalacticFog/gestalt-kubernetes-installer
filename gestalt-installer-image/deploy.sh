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

############################################
# SETUP
############################################

deploy_file=${1:-deployer.yaml}
kube_namespace=${2:-gestalt-system}

# Validate that all pre-conditions are met
gestalt_install_validate_preconditions

# Check that the `gestalt-system` namespace exists.  If not, print some commands to create it
kube_check_for_required_namespace ${kube_namespace}

# TODO: Add function that check whether config maps were created and whether has actual content
# kubectl get configmap -n gestalt-system
kubectl create configmap -n ${kube_namespace} gestalt-deployer-config --from-file ${conf_gestalt_conf}

# Run the install container with ConfigMaps
cmd="kubectl apply -n ${kube_namespace} -f ${deploy_file}"
echo "Running deploy command '$cmd'"
$cmd
exit_on_error "Failed deploy: '$cmd', aborting."

echo "\

Gestalt Platform deployer deployed to '${kube_namespace}'.  To view the deployer progress, run the following:

  kubectl logs -n ${kube_namespace} gestalt-deployer --follow

Done.
"
