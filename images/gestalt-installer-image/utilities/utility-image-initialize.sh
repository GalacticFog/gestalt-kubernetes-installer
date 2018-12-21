#!/bin/bash

############################################
# General Settings and References
############################################

  # Credentials and Configs
  conf_folder="./conf"
  conf_gestalt_install="${conf_folder}/gestalt-platform-installer.conf"

  # Scripts and Utilities
  utility_folder="./utilities"
  utility_bash="${utility_folder}/utility-bash.sh"
  utility_gestalt="${utility_folder}/utility-gestalt-installer-package.sh"

  # Sources
  sources_folder="./src"
  source_yaml2json="${sources_folder}/yaml2json"
  # Generated files and folders
  dependencies_folder="./deps"

  all_source_me="${utility_bash} ${utility_gestalt} ${conf_gestalt_install}"
  all_check_me="${source_yaml2json}"

############################################
# Check / Source expected configurations and scripts
############################################

  for tmp_file in ${all_source_me[@]}; do
    if [ ! -f "${tmp_file}" ]; then
      echo "[ERROR] Utility file '${tmp_file}' not found, aborting."
      exit 1
    else
      . "${tmp_file}"
      if [ $? -ne 0 ]; then
        echo "[ERROR] Unable source utility file '${tmp_file}', aborting."
        exit 1
      fi
      log_debug "[${FUNCNAME[0]}] sourced '${tmp_file}'"
    fi
  done

  for tmp_file in ${all_check_me[@]}; do
    if [ ! -f "${tmp_file}" ]; then
      echo "[ERROR] File '${tmp_file}' not found, aborting."
      exit 1
    fi
  done

  check_for_required_variables \
    dependencies_folder \
    kubectl_download_url \
    fog_download_url \
    helm_download_url \
    source_yaml2json

########################################################################################
# END
########################################################################################
