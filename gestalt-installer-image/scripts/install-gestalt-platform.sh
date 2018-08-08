#!/bin/bash
# Bash script for initializing the Gestalt Platform on kubernetes

. ./install-functions.sh

# Function wrapper for friendly logging and basic timing
run() {
  SECONDS=0
  echo "[Running '$@']"
  $@
  echo "['$@' finished in $SECONDS seconds]"
  echo ""
}

echo "Initiating installation of Gestalt platform at `date`."

if [ "${1,,}" == "debug" ]; then
  echo "Debugging output is enabled ('debug' specified as argument)."
  DEBUG_OUTPUT=1
else
  echo "Debugging output not enabled ('debug' not specified as argument)."
fi


# Each of the functions below should exit on error, aborting the deployment
# process.

check_for_required_variables \
  DATABASE_HOSTNAME \
  DATABASE_PORT \
  DATABASE_USERNAME \
  DATABASE_PASSWORD \
  DATABASE_NAME \
  SECURITY_HOSTNAME \
  SECURITY_PORT \
  SECURITY_PROTOCOL \
  SECURITY_ADMIN_USERNAME \
  SECURITY_ADMIN_PASSWORD \
  META_HOSTNAME \
  META_PORT \
  META_PROTOCOL \
  GESTALT_CLI_DATA \
  USE_DYNAMIC_LOADBALANCERS

check_for_optional_variables \
  META_BOOTSTRAP_PARAMS

if ! is_dynamic_lb_enabled ; then
  echo "Dynamic load balancing is not enabled, checking for required variables"
  check_for_required_variables \
    EXTERNAL_GATEWAY_HOST \
    EXTERNAL_GATEWAY_PROTOCOL
fi

META_URL="$META_PROTOCOL://$META_HOSTNAME:$META_PORT"
SECURITY_URL="$SECURITY_PROTOCOL://$SECURITY_HOSTNAME:$SECURITY_PORT"


# TODO - check_for_existing_gestalt

run check_for_existing_services
run wait_for_database
run init_database
run invoke_security_init
run wait_for_security_init
run init_meta
run setup_license
# run setup_ingress_controller
run create_providers
# run create_kong_ingress #  AWS approach
run create_kong_ingress_v2 # Minikube approach

echo "[Success] Gestalt platform installation completed."
