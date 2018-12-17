#!/bin/bash

############################################
# Utilities: Index
############################################

. scripts/utility-bash.sh


############################################
# Utilities: START
############################################


check_for_required_tools_gestalt_installer() {

  log_debug "Check presence of: base64 tr sed seq true kubectl curl unzip tar"
  check_if_installed base64 tr sed seq true kubectl curl unzip tar jq

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

    log_debug "[${FUNCNAME[0]}] Validate that expected json files are in json format: '${conf_install}'"
    validate_json ${conf_install}

    log_debug "[${FUNCNAME[0]}] Validate that expected json files are in json format: '${conf_install}'"
    validate_json ${gestalt_license}

    log_debug "[${FUNCNAME[0]}] Validate that expected environment variables are set ..."

    check_for_required_variables \
      kube_namespace conf_install \
      gestalt_license 

    check_for_kube

    echo "Precondition check succeeded"

}

gestalt_install_create_configmaps() {

  # Create a configmap with the generated install config
  #kubectl create configmap -n ${kube_namespace} installer-config --from-file ${conf_install}
  #exit_on_error "Failed create configmap \
  #'kubectl create configmap -n ${kube_namespace} installer-config --from-file ${conf_install}', aborting."

  # Create a configmap with gestal license
  #kubectl create configmap -n ${kube_namespace} gestalt-license --from-file ${gestalt_license}
  #exit_on_error "Failed create configmap \
  #'kubectl create configmap -n ${kube_namespace} gestalt-license --from-file ${gestalt_license}', aborting."

  # Create configmap from './custom_resource_templates' folder contents if want custom
  #kubectl create configmap -n ${kube_namespace} gestalt-resources --from-file ./configmaps/resource_templates/
  #exit_on_error "Failed create configmap \
  #'kubectl create configmap -n ${kube_namespace} gestalt-resources --from-file ./configmaps/resource_templates/', aborting."

  # Create for scripts
  #echo "Creating configmap for installation scripts to be run by gestalt-installer Pod..."
  #cmd="kubectl create configmap -n ${kube_namespace} installer-scripts --from-file ../gestalt-installer-image/scripts/"
  #echo $cmd
  #$cmd
  #exit_on_error "Command '$cmd' failed, aborting."

  #tar cfzv ./configmaps/gestalt.tar.gz -C ../gestalt-installer-image gestalt && \
  #cat ./configmaps/gestalt.tar.gz | base64 > ./configmaps/gestalt.tar.gz.b64
  #exit_on_error "Failed to build gestalt configmap data"

  # Create for Helm chart - main directory
  #echo "Creating configmap for Helm templates to be run by gestalt-installer Pod..."
  ##md="kubectl create configmap -n ${kube_namespace} gestalt-targz --from-file ./configmaps/gestalt.tar.gz.b64"
  #echo $cmd
  #$cmd
  #exit_on_error "Command '$cmd' failed, aborting."

  if [ -f configmaps/cacerts ]; then
    echo "Creating 'gestalt-security-cacerts' configmap from $gestalt_security_cacerts_file..."
    kubectl create configmap -n ${kube_namespace} gestalt-security-cacerts --from-file=configmaps/cacerts
    exit_on_error "Failed to build gestalt configmap data"
  fi

  # Cleanup
  #rm configmaps/gestalt.tar.gz
  #rm configmaps/gestalt.tar.gz.b64
}


# Run the install container with ConfigMaps


############################################
# Utilities: END
############################################

