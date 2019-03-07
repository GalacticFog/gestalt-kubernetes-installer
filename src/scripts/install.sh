#!/bin/bash
## This script is called by entrypoint.sh

gestalt_config="../config/install-config.json"
gestalt_config_yaml="../config/install-config.yaml"
gestalt_license="../config/gestalt-license.json"

. ./utility-bash.sh
. ./install-functions.sh
. ./eula-functions.sh

check_for_required_files \
  ${gestalt_config_yaml} \
  ${gestalt_license}

stage_0() {
  # Try to create an install token, which has to match the target environment, which acts as a guard
  # against the install pod running a second time
  install_token=`randompw`
  kubectl create secret -n $RELEASE_NAMESPACE generic ${RELEASE_NAME}-install --from-literal=token=${install_token}
  exit_on_error "Error creating '${RELEASE_NAME}-install' secret, unable to proceed.  An installation already appears to be present or may presently be running."
}

stage_1() {

  #
  # Stage 1 - Building configuration
  #

  run gestalt_installer_generate_helm_config

  echo
  env | sort
  echo

  echo "Cleanup MacOS metadata files..."
  find ../gestalt-helm-chart -type f -name '._*' -delete

  echo "Rendering Helm templates..."
  helm template ../gestalt-helm-chart --name ${RELEASE_NAME} -f helm-config.yaml > ../gestalt.yaml
  exit_on_error "Failed: 'helm template', aborting."

  echo "Creating Kubernetes resources..."
  kubectl create -n $RELEASE_NAMESPACE -f ../gestalt.yaml
  exit_on_error "Failed 'kubectl apply', aborting."
}

stage_2() {
  #
  # Stage 2 - Orchestrate the Gestalt Platform installation
  #

  run wait_for_database_pod
  run wait_for_database
  run init_database

  echo "Waiting a bit..."
  sleep 10

  run wait_for_system_pod "${RELEASE_NAME}-rabbit"

  run invoke_security_init
  run wait_for_security_init
  run init_meta

  run wait_for_system_pod "${RELEASE_NAME}-ui"
  run wait_for_system_pod "${RELEASE_NAME}-elastic"

  gestalt_cli_set_opts
  do_get_security_credentials
  create_gestalt_security_creds_secret
  gestalt_cli_login

  # echo "Enable Debug..."
  # fog config set debug=true

  gestalt_cli_license_set
  gestalt_cli_context_set

  echo
  env | sort | tee install.env
  echo

  run gestalt_cli_create_resources #Default or Custom as per config

  if [ ${K8S_PROVIDER:=default} == "gke" ]; then
    if_kong_ingress_service_name_is_set and_health_api_is_working create_kong_readiness_probe
  fi

  if_kong_ingress_service_name_is_set create_kong_ingress_v2
}

#### Main ####

run getsalt_installer_load_configmap
run getsalt_installer_setcheck_variables

if [ -z ${MARKETPLACE_INSTALL+x} ]; then
  stage_0
  stage_1
else
  send_marketplace_eula_slack_message
fi
stage_2

echo "[Success] Gestalt platform installation completed."
