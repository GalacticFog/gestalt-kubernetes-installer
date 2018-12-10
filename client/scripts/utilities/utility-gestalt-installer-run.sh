#!/bin/bash

############################################
# Utilities: Index
############################################



############################################
# Utilities: START
############################################


check_for_required_tools_gestalt_installer() {

  log_debug "Check presence of: base64 tr sed seq sudo true kubectl curl unzip tar"
  check_if_installed base64 tr sed seq sudo true kubectl curl unzip tar jq

}

gestalt_install_help () {

  echo ""
  echo "Help: `basename $0`"
  echo ""

}

gestalt_install_validate_preconditions() {

    echo "Expectation, that user already successfully ran ./configure.sh"

    file_array="${conf_install} ${kube_install}"
    log_debug "[${FUNCNAME[0]}] Check for required files: '${file_array[@]}'"
    check_for_required_files "${file_array[@]}"

    log_debug "[${FUNCNAME[0]}] Validate that expected environment variables are set ..."

    check_for_required_variables \
      kube_namespace \
      conf_install

    check_for_kube

    echo "Precondition check succeeded"

}

gestalt_install_create_configmaps() {

  # Create configmap for install data
  mkdir tmp && \
  tar cfzv ./tmp/install-data.tar.gz -C .. \
    gestalt \
    resource_templates \
    scripts \
    config \
    && cat ./tmp/install-data.tar.gz | base64 > ./tmp/install-data.tar.gz.b64
  cmd="kubectl create configmap -n ${kube_namespace} install-data --from-file ./tmp/install-data.tar.gz.b64"
  echo $cmd
  $cmd
  exit_on_error "Failed create configmap from resource_templates directory, aborting."

  # for CACERTS file
  echo "TODO: Ensure cacerts is handled properly"
  if [ -f tmp/cacerts ]; then
    echo "Creating 'gestalt-security-cacerts' configmap from $gestalt_security_cacerts_file..."
    kubectl create configmap -n ${kube_namespace} gestalt-security-cacerts --from-file=configmaps/cacerts
    exit_on_error "Failed to build gestalt configmap data"
  fi

  # Cleanup
  rm -r ./tmp
}

# Run the install container with ConfigMaps


############################################
# Utilities: END
############################################

