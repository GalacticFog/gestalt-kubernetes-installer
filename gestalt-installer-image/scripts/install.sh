#!/bin/bash
## This script is the entrypoint to the Gestalt Installer container

# Source common project configuration and utilities
# TODO: Make work locally not just from built image
utility_file='/scripts/install-gestalt-platform-initialize.sh'
if [ -f "${utility_file}" ]; then
  . ${utility_file}
else
  echo "[ERROR] Project initialization script '${utility_file}' can not be located, aborting. "
  exit 1
fi

echo "Process configmap ..."
getsalt_installer_load_configmap
echo "Default and validate environment variables ..."
getsalt_installer_setcheck_variables

echo "Generate Help config ..."
gestalt_installer_generate_helm_config

echo "Generate Help config ..."
helm template gestalt --name gestalt -f helm-config.yaml > gestalt.yaml
exit_on_error "Failed: helm template gestalt --name gestalt -f helm-config.yaml > gestalt.yaml"

kubectl apply -n gestalt-system -f gestalt.yaml
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
