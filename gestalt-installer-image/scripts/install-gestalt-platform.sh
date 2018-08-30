#!/bin/bash
# Bash script for initializing the Gestalt Platform on kubernetes

scripts_folder="/scripts"

echo "LALALALA - -00000"

. ${scripts_folder}/install-functions.sh

echo "LALALALA - -00001"

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

### CHECK FILE AND MAKE sure NEEDED variables are present
### jq
### if want read in environment variables (most likely will have to)
### as function so next can be left as is

#gestalt username and pwd
#SECURITY_ADMIN_USERNAME \

##########################
#
###

main_config_map=

#########################

echo "LALALALA - -00002"


base_config_map="/config/install-config.json"

cat ${base_config_map}

ALL_CURRENT_VARIABLES_ARRAY=$(cat  ${base_config_map} | awk -F'"' '{print $2}' | grep -v '^$' | grep -v 'use_dynamic_loadbalancers' | grep -v 'provision_internal_database')

for CURR_CURR_VARIABLE in ${ALL_CURRENT_VARIABLES_ARRAY[@]}; do
  CURR_VARIABLE_NAME=`echo ${CURR_CURR_VARIABLE} | tr '[a-z]' '[A-Z]' | sed 's|-|_|g'`
  CURR_VARIABLE_VALUE=`jq -r '.["'${CURR_CURR_VARIABLE}'"]' ${base_config_map}`
  eval ${CURR_VARIABLE_NAME}=${CURR_VARIABLE_VALUE}
  echo "[INFO][${CURR_VARIABLE_NAME}=${CURR_VARIABLE_VALUE}]"
  export eval ${CURR_VARIABLE_NAME}=${CURR_VARIABLE_VALUE}
done

provision_internal_database=`jq '.["provision_internal_database"]' ${base_config_map}`
use_dynamic_loadbalancers=`jq '.["use_dynamic_loadbalancers"]' ${base_config_map}`
export DATABASE_PORT=5432

env | sort


export SECURITY_URL='http://gestalt-security.gestalt-system.svc.cluster.local:9455'
export META_URL='http://gestalt-meta.gestalt-system.svc.cluster.local:10131'
export UI_URL='http://gestalt-ui.gestalt-system.svc.cluster.local:80'



check_for_required_variables \
  DATABASE_HOSTNAME \
  DATABASE_USERNAME \
  DATABASE_PASSWORD \
  DATABASE_PASSWORD \
  DATABASE_HOSTNAME \
  RABBIT_HOST \
  DOTNET_EXECUTOR_IMAGE \
  JS_EXECUTOR_IMAGE \
  JVM_EXECUTOR_IMAGE \
  NODEJS_EXECUTOR_IMAGE \
  PYTHON_EXECUTOR_IMAGE \
  RUBY_EXECUTOR_IMAGE \
  GOLANG_EXECUTOR_IMAGE \
  GWM_IMAGE \
  KONG_IMAGE \
  LOGGING_IMAGE \
  POLICY_IMAGE \
  KONG_VIRTUAL_HOST \
  ELASTICSEARCH_HOST \
  KUBECONFIG_BASE64 \
  SECURITY_URL \
  META_URL \
  UI_URL

#
# [INFO][RABBIT_HOST=gestalt-rabbit.gestalt-system]
# All required variables found.
# Required variable "DATABASE_NAME" not defined.  - I believe we have default
# Required variable "SECURITY_HOSTNAME" not defined.
# Required variable "SECURITY_PORT" not defined.
# Required variable "SECURITY_PROTOCOL" not defined.
# Required variable "SECURITY_ADMIN_USERNAME" not defined.
# Required variable "SECURITY_ADMIN_PASSWORD" not defined.
# Required variable "META_HOSTNAME" not defined.
# Required variable "META_PORT" not defined.
# Required variable "META_PROTOCOL" not defined.
# Required variable "GESTALT_CLI_DATA" not defined.
# Required variable "USE_DYNAMIC_LOADBALANCERS" not defined. - Have IT
# One or more required variables not defined, aborting.


# check_for_required_variables \
 # DATABASE_HOSTNAME \
 # DATABASE_PORT \
 # DATABASE_USERNAME \
 # DATABASE_PASSWORD \
  # DATABASE_NAME \
 # SECURITY_HOSTNAME \
 # SECURITY_PORT \
 # SECURITY_PROTOCOL \
 # SECURITY_ADMIN_USERNAME \
 # SECURITY_ADMIN_PASSWORD \
 # META_HOSTNAME \
 # META_PORT \
 # META_PROTOCOL \
 # GESTALT_CLI_DATA \ 
  # USE_DYNAMIC_LOADBALANCERS # need rename we have it set

EXTERNAL_GATEWAY_HOST=localhost
EXTERNAL_GATEWAY_PROTOCOL=http

echo "LALALALA - -00003"

check_for_optional_variables \
  META_BOOTSTRAP_PARAMS


echo "LALALALA - -00004 - for now comment out block"
if ! is_dynamic_lb_enabled ; then
  echo "Dynamic load balancing is not enabled, checking for required variables"
  check_for_required_variables \
    EXTERNAL_GATEWAY_HOST \
    EXTERNAL_GATEWAY_PROTOCOL
fi




META_URL="$META_PROTOCOL://$META_HOSTNAME:$META_PORT"
SECURITY_URL="$SECURITY_PROTOCOL://$SECURITY_HOSTNAME:$SECURITY_PORT"
UI_URL="$UI_PROTOCOL://$UI_HOSTNAME:$UI_PORT"

SECURITY_URL='http://gestalt-security.gestalt-system.svc.cluster.local:9455'
META_URL='http://gestalt-meta.gestalt-system.svc.cluster.local:10131'


# TODO - check_for_existing_gestalt

echo "[NEXT][run check_for_existing_services]"
run check_for_existing_services


echo "+======================================"



echo "[NEXT][run wait_for_database]"
run wait_for_database
echo "++======================================"
echo "++======================================"
echo "[run init_database]"
run init_database
echo "+++======================================"
echo "+++======================================"
echo "+++======================================"
run invoke_security_init
echo "++++======================================"
echo "++++======================================"
echo "++++======================================"
echo "++++======================================"
run wait_for_security_init
echo "++++======================================"
echo "++++======================================"
echo "++++======================================"
echo "++++=============NEXT:run init_meta================="
run init_meta

####GOOD
# run setup_ingress_controller
run create_providers #ERIC
# run create_kong_ingress #  AWS approach
run create_kong_ingress_v2 # Minikube approach #WILL FAIL IF DO NOT HAVE ERIC's STUFF

echo "[Success] Gestalt platform installation completed."
