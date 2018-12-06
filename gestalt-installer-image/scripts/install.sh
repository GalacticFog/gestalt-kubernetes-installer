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

echo
env | sort
echo

# Stage 2 - Orchestrate the Gestalt Platform installation

run check_for_existing_services
run wait_for_database
run init_database

echo "Waiting a bit..."
sleep 10

run invoke_security_init
run wait_for_security_init
run init_meta

gestalt_cli_set_opts
do_get_security_credentials
create_gestalt_security_creds_secret
gestalt_cli_login

# echo "Enable Debug..."
# fog config set debug=true

gestalt_cli_license_set
gestalt_cli_context_set

run gestalt_cli_create_resources #Default or Custom as per config
# run create_kong_ingress #  AWS approach
if_kong_ingress_service_name_is_set and_health_api_is_working create_kong_readiness_probe
if_kong_ingress_service_name_is_set create_kong_ingress_v2

echo "[Success] Gestalt platform installation completed."
