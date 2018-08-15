#!/bin/bash

############################################
# Functions
############################################

check_for_required_namespace() {

  [[ $# -ne 1 ]] && echo && exit_with_error "Function '${FUNCNAME[0]}' expects 1 parameter ($# provided) [$@], aborting."
  f_namespace_name=$1

  # echo "Checking for existing Kubernetes namespace '$install_namespace'..."
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


############################################
# General Settings and References
############################################

  logging_lvl="debug" # error, info, debug

  # Credentials and Configs
  conf_folder="."
  conf_credential="${conf_folder}/credentials.conf"
  conf_gestalt="${conf_folder}/gestalt.conf"

  # Scripts and Utilities
  script_folder="./scripts"
  script_utility_folder="${script_folder}/utilities"

  utility_bash="${script_utility_folder}/bash-utilities.sh"
  installer_config="${script_folder}/build-config.sh"
  installer_spec="${script_folder}/build-installer-spec.sh"

  # Generated files and folders

  log_folder="./logs"
  log_configure="${log_folder}/gestalt-configure.log"

  conf_install="./install-config.json"
  kube_install="./installer.yaml"

  kube_namespace="gestalt-system"

############################################
# Source Utilities
############################################


  [ "${logging_lvl}" == "debug" ] && echo "[Debug][START] Your current location [`pwd`]"

  ### First source utilities file

  if [ ! -f "${utility_bash}" ]; then
    echo "[ERROR] Utility file '${utility_bash}' not found, aborting."
    exit 1
  else
    source "${utility_bash}"
    exit_on_error "Unable source utility file '${utility_bash}', aborting."
    [ "${logging_lvl}" == "debug" ] && echo "[Debug] Sourced utility file '${utility_bash}'"
  fi

  ### Check for presence for other script files

  all_file="${conf_install} ${kube_install}"
  [ "${logging_lvl}" == "debug" ] && echo "[Debug] All other files for execution: '${all_file[@]}'"
 
  for curr_file in ${all_file[@]}
  do
    if [ ! -f "${curr_file[@]}" ]; then
      exit_with_error "File '${curr_file[@]}' not found, aborting."
    else
      [ "${logging_lvl}" == "debug" ] && echo "[Debug] File found: '${curr_file}'"
    fi
  done

# Check that the generated files exist, otherwise abort (User should have run ./configure.sh first)

# Check that the `gestalt-system` namespace exists.  If not, print some commands to create it
check_for_required_namespace ${kube_namespace}

# Create a configmap with the generated install config
kubectl create configmap -n ${kube_namespace} installer-config --from-file ${conf_install}
exit_on_error "Failed create configmap \
'kubectl create configmap -n ${kube_namespace} installer-config --from-file ${conf_install}', aborting."

# Optionally, create a config map from the sample resource files
# TODO

# Run the install container with ConfigMaps
kubectl apply -n ${kube_namespace} -f ${kube_install}
exit_on_error "Failed install \
'kubectl apply -n ${kube_namespace} -f ${kube_install}', aborting."