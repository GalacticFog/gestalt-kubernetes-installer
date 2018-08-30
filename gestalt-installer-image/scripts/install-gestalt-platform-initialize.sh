#!/bin/bash

############################################
# General Settings and References
############################################

# TODO: Make smarter to allow run from local and built image

  # Scripts and Utilities
  utility_folder_shared="/scripts"
  utility_bash="${utility_folder_shared}/utility-bash.sh"

  export script_folder="/scripts"
  scipt_install_helper="${script_folder}/install-functions.sh"

  gestalt_config="/config/install-config.json"
  gestalt_license="/license/gestalt-license.json"
  gestalt_resource_script="/resource_templates/create_gestalt_resources.sh"

  all_source_me="${utility_bash} ${scipt_install_helper}"

############################################
# Check / Source expected configurations and scripts
############################################

  for tmp_file in ${all_source_me[@]}; do

    if [ ! -f "${tmp_file}" ]; then
      echo "[ERROR] Utility file '${tmp_file}' not found, aborting."
      exit 1
    else
      source "${tmp_file}"
      if [ $? -ne 0 ]; then
        echo "[ERROR] Unable source utility file '${tmp_file}', aborting."
        exit 1
      fi
      log_debug "[${FUNCNAME[0]}] sourced '${tmp_file}'"
    fi

  done

  # Now we should have bash utilities

  check_for_required_files ${gestalt_config} ${gestalt_license} ${gestalt_resource_script}
  

########################################################################################
# END
########################################################################################
