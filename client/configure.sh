#!/bin/bash

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
  conf_kube="./kubeconfig.b64"

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

############################################
# Validations
############################################

  ### Then source any other applicable configuration files

  all_file="${conf_credential} ${conf_gestalt}"
  [ "${logging_lvl}" == "debug" ] && echo "[Debug] All files for sourcing: '${all_file[@]}'"

  for curr_file in ${all_file[@]}
  do
    if [ ! -f "${curr_file[@]}" ]; then
      exit_with_error "Required file '${curr_file[@]}' not found, aborting."
    else
      source "${curr_file}"
      exit_on_error "Unable source required file '${curr_file}', aborting."
      [ "${logging_lvl}" == "debug" ] && echo "[Debug] Sourced file '${curr_file}'"
    fi
  done

  ### Binaries
  OS="`uname`"
  case $OS in
    'Linux')
      kubectl="./bin/kubectl"
      [ "${logging_lvl}" == "debug" ] && echo "[Debug] '${OS}' detected will use packaged kubectl '${kubectl}'"
      ;;
    'Darwin')
      check_if_installed "kubectl"
      kubectl=`which kubectl`
      ;;
    *)
      exit_with_error "Unsupported OS '{OS}'"
    ;;
  esac

  #Check for required tools
  check_for_required_tools

  ### Check for presence for other script files

  all_file="${conf_credential} ${conf_gestalt}"
  [ "${logging_lvl}" == "debug" ] && echo "[Debug] All other files for execution: '${all_file[@]}'"
 
  for curr_file in ${all_file[@]}
  do
    if [ ! -f "${curr_file[@]}" ]; then
      exit_with_error "File '${curr_file[@]}' not found, aborting."
    else
      [ "${logging_lvl}" == "debug" ] && echo "[Debug] File found: '${curr_file}'"
    fi
  done


############################################
# Kubectl: Context and Config
############################################

[[ "${logging_lvl}" =~ (debug|info) ]] && echo && echo "[Info] Obtain current context '$kubectl config current-context' ..."
kubectl_context=$($kubectl config current-context)
exit_on_error "Unable determine current context '${kubectl} config current-context', aborting."

#use process_kubeconfig() { instead
[[ "${logging_lvl}" =~ (debug|info) ]] && echo && \
echo "[Info] Obtain kubeconfig from current context (${kubectl_context}) '$kubectl config view --raw --minify --flatten \
 | base64 > ${conf_kube}' ..."
$kubectl config view --raw --minify --flatten | base64 > kubeconfig.b64
exit_on_error "Unable obtain and encode kubeconfig from context (${kubectl_context}) '$kubectl config view --raw --minify --flatten \
 | base64 > ${conf_kube}', aborting."

############################################
# Generate Configuration
############################################

[[ "${logging_lvl}" =~ (debug|info) ]] && echo && \
echo "[Info] Generate Installer Configuration '. ${installer_config}'"
. "${installer_config}" "${conf_install}"
exit_on_error "Issue during building '${installer_config}'"
[[ "${logging_lvl}" =~ (debug) ]] && echo && \
echo "[Debug] Generated Installer Configuration:" && \
cat "${conf_install}" && echo


############################################
# Generate Installer Spec
############################################


[[ "${logging_lvl}" =~ (debug|info) ]] && echo && \
echo "[Info] Generate Installer Spec '. ${installer_spec} ${kube_install}'"
. "${installer_spec}" "${kube_install}"


############################################
# END
############################################