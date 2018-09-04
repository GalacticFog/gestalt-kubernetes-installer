#!/bin/bash

############################################
# General Settings and References
############################################

  # Credentials and Configs
  conf_folder="./conf"
  conf_gestalt_install="${conf_folder}/gestalt-platform-installer.conf"

  # Scripts and Utilities
  utility_folder="./utilities"
  script_folder="./scripts"
  utility_bash="${script_folder}/utility-bash.sh"
  utility_gestalt="${utility_folder}/utility-gestalt-installer-package.sh"

  # Generated files and folders
  dependencies_folder="./deps"

  all_source_me="${utility_bash} ${utility_gestalt} ${conf_gestalt_install}"
  all_check_me=""

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

########################################################################################
# END
########################################################################################
