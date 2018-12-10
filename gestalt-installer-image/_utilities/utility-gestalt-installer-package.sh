#!/bin/bash

############################################
# Dependencies
############################################

# Needs ./utilities/utility-bash.sh

############################################
# Index
############################################

dependencies_process_help () {
  echo ""
  echo "Help: '`basename $0`' Dependency Management Utility to gather or cleanup gestalt platform installation dependency binaries"
  echo ""
  echo "    Default: Download (if not present) dependency binaries"
  echo ""
  echo "    All supported options:"
  echo "        -l <logging_lvl>' : specify your desired logging level: 'debug|info|error(Default)''"
  echo "        -c <dependencies_processing_command>' : specify your desired dependencies management command: 'clean|fetch(Default)'"
  echo "        -l <logging_lvl>' : specify your desired logging level: 'debug|info|error(Default)'"
  echo "        -h : print this help"
}

build_and_publish_help () {
  echo ""
  echo "Script '$0' was called with $# arguments. At lest one tag expected."
  echo ""
  echo "Usage: "
  echo "    ./build_and_publish.sh <docker tag array>"
  echo "          <docker tag array> - space separated docker tags"
  echo ""
  exit 1
}

build_and_publish_validate_deps() {
  echo "Validate gestalt installer image dependencies created by './dependnecies-process.sh' are present"

  check_for_required_variables \
    dependencies_folder

  all_binaries="kubectl helm fog"

  for curr_binary in ${all_binaries[@]}; do

    log_debug "Looking up '${dependencies_folder}/${curr_binary}'"
    if [ ! -f ${dependencies_folder}/${curr_binary} ]; then
      exit_with_error "'${dependencies_folder}/${curr_binary}' not found, aborting."
    fi

  done

  echo "OK - All gestalt installer image dependencies are present"
}

dependencies_process_set_command () {
  if [ -z ${current_command} ]; then
    current_command="fetch"
    echo "[Info] Current command not set, defaulting to 'fetch'. Supported 'fetch|clean'."
  fi
}

dependencies_process_print_info () {
  log_debug "[${FUNCNAME[0]}] logging_lvl = '${logging_lvl}'"
  log_debug "[${FUNCNAME[0]}] current_command = '${current_command}'"
  log_debug "[${FUNCNAME[0]}] helm_download_url = '${helm_download_url}'"
  log_debug "[${FUNCNAME[0]}] kubectl_download_url = '${kubectl_download_url}'"
  log_debug "[${FUNCNAME[0]}] fog_download_url = '${fog_download_url}'"
}

dependencies_process_initialize () {
  log_set_logging_lvl #Set default logging level if not specified (error)
  dependencies_process_set_command #Set default command if not specified (fetch)
  dependencies_process_print_info #If Debug will print main variables
}

build_and_publish_initialize () {
  log_set_logging_lvl #Set default logging level if not specified (error)
}

dependencies_process_clean () {
  check_for_required_variables dependencies_folder

  if [ -d ${dependencies_folder} ]; then
    cmd="rm -rf ${dependencies_folder}/*"
    log_debug "Cleaning dependencies with: $cmd"
    $cmd
    exit_on_error "Failed cleaning dependencies with: $cmd"
    log_info "Done cleaning dependencies."
  else
    log_info "Nothing to do, '${dependencies_folder}' not present."
  fi
}

dependencies_process_fetch () {
  check_for_required_variables dependencies_folder

  if [ ! -d ${dependencies_folder} ]; then
    log_info "As not present creating '${dependencies_folder}'"
    mkdir -p ${dependencies_folder}
  fi

  get_kubectl
  get_helm
  get_fog_cli
}

get_kubectl() {
  check_for_required_variables \
    dependencies_folder \
    kubectl_download_url

  if [ ! -f ${dependencies_folder}/kubectl ]; then
    echo "Getting kubectl from '${kubectl_download_url}'"
    curl -sL ${kubectl_download_url} -o ${dependencies_folder}/kubectl
    exit_on_error "Failed to get kubectl from '${kubectl_download_url}' to '${dependencies_folder}', aborting."
    chmod +x ${dependencies_folder}/kubectl
    exit_on_error "Failed to make kubectl executable '${dependencies_folder}/kubectl', aborting."   
    echo "kubectl_version=${kubectl_version}" >> "${dependencies_folder}/versions.txt"
  else
    log_info "OK - 'kubectl' already present, skipping"
  fi
}

get_fog_cli() {
  check_for_required_variables \
    dependencies_folder \
    fog_download_url

  if [ ! -f ${dependencies_folder}/fog ]; then
    
    echo "Getting fog from '${fog_download_url}'"
    curl -sL ${fog_download_url} -o ${dependencies_folder}/fog.zip
    exit_on_error "Failed to get fog cli from '${kubectl_download_url}' to '${dependencies_folder}', aborting."
    cd ${dependencies_folder}
    exit_on_error "Failed to navigate to '${dependencies_folder}', aborting."
    unzip -qq fog.zip
    exit_on_error "Failed to extract fog cli zip, aborting."
    rm fog.zip
    exit_on_error "Failed to cleanup fog cli zip, aborting."    
    cd -
    exit_on_error "Failed to navigate back to main folder, aborting."
    chmod +x ${dependencies_folder}/fog
    exit_on_error "Failed to make fog cli executable '${dependencies_folder}/fog', aborting."
    echo "fog_version=${fog_version}" >> "${dependencies_folder}/versions.txt"

  else
    log_info "OK - 'fog' already present, skipping"
  fi
}

get_helm() {
  check_for_required_variables \
    dependencies_folder \
    helm_download_url

  if [ ! -f ${dependencies_folder}/helm ]; then
    
    echo "Getting fog from '${helm_download_url}'"
    curl -sL ${helm_download_url} -o ${dependencies_folder}/helm.tar.gz
    exit_on_error "Failed to get helm from '${helm_download_url}' to '${dependencies_folder}', aborting."
    tar xfz ${dependencies_folder}/helm.tar.gz -C ${dependencies_folder} --strip-components 1 --exclude=README.md --exclude=LICENSE
    exit_on_error "Failed to extract helm archive', aborting."
    rm ${dependencies_folder}/helm.tar.gz
    exit_on_error "Failed to cleanup helm archive, aborting."  
    chmod +x ${dependencies_folder}/helm
    exit_on_error "Failed to make helm executable '${dependencies_folder}/helm', aborting."
    echo "helm_version=${helm_version}" >> "${dependencies_folder}/versions.txt"

  else
    log_info "OK - 'helm' already present, skipping"
  fi
}

############################################
# END
############################################