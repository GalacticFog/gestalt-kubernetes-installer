#!/bin/bash

############################################
# SETUP
############################################

# Source common project configuration and utilities
utility_file='./utilities/utility-image-initialize.sh'
if [ -f ${utility_file} ]; then
  . ${utility_file}
else
  echo "[ERROR] Project initialization script '${utility_file}' can not be located, aborting. "
  exit 1
fi

# Process script options and set appropriate variables
while getopts "hc:l:o" option ; do
  case $option in
  c) current_command="$OPTARG"
  ;;
  l) logging_lvl="$OPTARG"; logging_lvl_validate
  ;;
  o) os_override="$OPTARG"
  ;;
  h) dependencies_process_help
  ;;
  *) dependencies_process_help 
     exit_with_error "Invalid option: '$option' '$OPTARG'"
  ;;
  esac
done

dependencies_process_initialize #Set default variables for this script

# TODO: Later add only if special ovverride package not for image
# get_my_os #Get current OS

if [ ${current_command} == "clean" ]; then 
  dependencies_process_clean
  echo "Finished cleaning up dependencies from '${dependencies_folder}'"
else
  dependencies_process_fetch
  log_debug "All packaged dependencies `ls -lah ${dependencies_folder}`"
  echo "Finished gathering dependencies to '${dependencies_folder}'"
fi

############################################
# END
############################################