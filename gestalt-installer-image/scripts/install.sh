#!/bin/bash
## This script is the entrypoint to the Gestalt Installer container

# Source common project configuration and utilities
# TODO: Make work locally not just from built image
. ./scripts/install-gestalt-platform-initialize.sh
if [ $? -ne 0 ]; then
  echo "[ERROR] Project initialization script can not be loaded, aborting. "
  exit 1
fi

# Stage 1 - Building configuration

run getsalt_installer_load_configmap
run getsalt_installer_setcheck_variables
run gestalt_installer_generate_helm_config

# Database
case $PROVISION_INTERNAL_DATABASE in
  [Nn0]*)
    echo "Not provisioning internal database, deleting postgres chart..."
    rm -rv /gestalt/charts/postgresql* /gestalt/requirements.*
    ;;
esac


echo "Rendering Helm templates..."
helm template gestalt --name gestalt -f helm-config.yaml > gestalt.yaml
exit_on_error "Failed: helm template gestalt --name gestalt -f helm-config.yaml > gestalt.yaml"

echo "Creating Kubernetes resources..."
kubectl create -n gestalt-system -f gestalt.yaml
exit_on_error "Failed kubectl apply -n gestalt-system -f gestalt.yaml, aborting."

# Stage 2 - Orchestrate the Gestalt Platform installation

run check_for_existing_services
run wait_for_database
run init_database
run invoke_security_init
run wait_for_security_init
run init_meta

gestalt_cli_set_opts
do_get_security_credentials
gestalt_cli_login
gestalt_cli_license_set
gestalt_cli_context_set

run gestalt_cli_create_resources #Default or Custom as per config
# run create_kong_ingress #  AWS approach
run create_kong_ingress_v2 #

echo "[Success] Gestalt platform installation completed."
