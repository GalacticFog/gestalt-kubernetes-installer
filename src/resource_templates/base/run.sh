create() {

  # `fog` reads configuration from environment variables

  local file=$1.yaml
  echo "Creating resource from '$file'..."
  fog create resource -f $file
  if [ $? -ne 0 ]; then
    echo
    echo "Error: Error processing '$file', aborting."
    exit 1
  fi
}

retry_fails() {
  local tries=5
  local retry_delay=20
  local cmd=$*
  local try=0
  local cmd_output
  local exit_code
  echo "Attempting $tries tries of command '$cmd'"
  for try in `seq $tries`; do
    echo "attempt $try of '$cmd'"
    cmd_output=$($cmd)
    exit_code=$?
    echo $cmd_output
    if [ $exit_code -eq 0 ]; then
      echo "SUCCESS attempt $try of '$cmd'"
      return $exit_code
    fi
    echo "FAIL attempt $try of '$cmd' exit code $exit_code"
    echo "retrying in $retry_delay seconds"
    sleep $retry_delay
  done
  echo "FAILED!!! $tries attempts of command '$cmd'"
  return $exit_code
}

exit_if_fail() {
  $*
  [ $? -eq 0 ] || (echo "FATAL ERROR - exiting" && exit 1)
}

exit_with_error() {
  error "$@"
  exit 1
}

exit_on_error() {
  [ $? -eq 0 ] || exit_with_error "$@"
}

kube_copy_secret () {

  [[ $# -ne 4 ]] && echo && exit_with_error "[${FUNCNAME[0]}] Function expects 4 parameter(-s) ($# provided) [$@], aborting."
  f_source_namespace_name=$1 
  f_source_secret_name=$2
  f_target_namespace_name=$3 
  f_target_secret_name=$4
  f_base_folder="/tmp"

  kubectl get secret -n ${f_source_namespace_name} ${f_source_secret_name} -oyaml > ${f_base_folder}/secret-${f_source_secret_name}.yaml
  exit_on_error "Unable obtain secret 'kubectl get secret -n ${f_source_namespace_name} ${f_source_secret_name} -oyaml' , aborting."

  # Strip out and rename
  cat ${f_base_folder}/secret-${f_source_secret_name}.yaml | sed "s/name: ${f_source_secret_name}/name: ${f_target_secret_name}/" | grep -v 'creationTimestamp:' | grep -v 'namespace:' | grep -v 'resourceVersion:' | grep -v 'selfLink:' | grep -v 'uid:' > ${f_base_folder}/secret-${f_target_secret_name}.yaml
  exit_on_error "Unable manipulate source secret '${f_source_namespace_name}:${f_source_secret_name}' , aborting."

  kubectl apply -f ${f_base_folder}/secret-${f_target_secret_name}.yaml -n ${f_target_namespace_name}
  exit_on_error "Unable create target secret '${f_target_namespace_name}:${f_target_secret_name}' , aborting."

  echo "OK - Secret Copied to '${f_target_namespace_name}:${f_target_secret_name}'"

}

# echo "Enable Debug for CLI..."
if [ "${FOG_CLI_DEBUG}" == "true" ]; then
  fog config set debug=true
fi

# Set context
fog context set '/root'
exit_on_error "Error setting context, aborting"

# Set up hierarchy
fog create workspace --name 'gestalt-system-workspace' --description "Gestalt System Workspace"
exit_on_error "Error creating 'gestalt-system-workspace', aborting"

fog create environment 'gestalt-laser-environment' --org 'root' --workspace 'gestalt-system-workspace' --description "Gestalt Laser Environment" --type 'production'
exit_on_error "Error creating 'gestalt-laser-environment', aborting"

fog create environment 'gestalt-system-environment' --org 'root' --workspace 'gestalt-system-workspace' --description "Gestalt System Environment" --type 'production'
exit_on_error "Error creating 'gestalt-system-environment', aborting"

# Create base providers
create db-provider
create security-provider
create kubernetes-provider
create rabbit-provider
create logging-provider

# Link the logging provider to the CaaS provider
fog meta patch-provider --provider '/root/default-kubernetes' -f link-logging-provider.yaml

# Create Executor Providers
create js-executor
create jvm-executor
create dotnet-executor
create golang-executor
create nodejs-executor
create python-executor
create ruby-executor

# Laser
if [ "${LASER_PROVIDER_CUSTOMIZE}" == "1" ]; then
  for CURR_EXECUTOR in $(echo ${LASER_PROVIDER_CUSTOM_EXECUTORS[@]} | sed "s/:/ /g"); do
    create ${CURR_EXECUTOR}
  done
  create ${LASER_PROVIDER_DEFINITION}
else
  create laser-provider
fi

# Create other providers
create policy-provider # Policy depends on Rabbit and Laser
create kong-provider

# Uncomment to enable, and also ensure that the gatewaymanager provider has linked providers for each kong.
# create kong2-provider
# create kong3-external-provider

create gatewaymanager-provider  # Create the gateway manager provider after 
                                # kong providers, as it uses the kong providers as linked providers

## Copy in secrets to all Gestalt Managed Namespaces
if [ "${CUSTOM_IMAGE_PULL_SECRET}" == "1" ]; then
  kubectl get secret -n gestalt-system imagepullsecret-1 -oyaml > /tmp/secret-imagepullsecret-1.yaml
  exit_on_error "Unable obtain secret 'kubectl get secret -n gestalt-system imagepullsecret-1 -oyaml' , aborting."
  # Strip out and rename
  cat /tmp/secret-imagepullsecret-1.yaml | grep -v 'creationTimestamp:' | grep -v 'namespace:' | grep -v 'resourceVersion:' | grep -v 'selfLink:' | grep -v 'uid:' > /tmp/secret-clean-imagepullsecret-1.yaml
  exit_on_error "Unable manipulate source secret 'gestalt-system:imagepullsecret-1' , aborting."
  all_namespaces=$(kubectl get namespace -l "meta/fqon" --no-headers | awk '{print $1}')
  echo "Namespaces to process: ${all_namespaces[@]}"
  for curr_namespace in ${all_namespaces[@]}; do
    kubectl apply -f /tmp/secret-clean-imagepullsecret-1.yaml -n ${curr_namespace}
    exit_on_error "Unable create target secret '${curr_namespace}:imagepullsecret-1' , aborting."
    echo "OK - Secret Copied to '${curr_namespace}:imagepullsecret-1'"
  done
fi

sleep 20  # Provide time for Meta to settle before migrating the schema
fog meta POST /migrate -f meta-migrate.json | jq .

# Catalog provider
if [ "$configure_catalog" == "Yes" ]; then
  create catalog-provider-inline
fi

create_gke_healthchecks() {
  local healthcheck_environment=gestalt-health-environment
  sleep 10
  fog create environment $healthcheck_environment --org 'root' --workspace 'gestalt-system-workspace' --description "Gestalt HealthCheck Environment" --type 'production'
  [ $? -eq 0 ] || exit_with_error "Error creating environment '${healthcheck_environment}', aborting"
  sleep 10
  local gestalt_healthcheck_context="/root/gestalt-system-workspace/$healthcheck_environment"
  exit_if_fail retry_fails fog context set $gestalt_healthcheck_context
  echo "----- Creating the Kong healthcheck lambda -----"
  exit_if_fail retry_fails fog create resource -f healthcheck-lambda.json
  sleep 10
  echo "----- Creating the Kong healthcheck API -----"
  exit_if_fail retry_fails fog create api --name health --description healthcheck-api --provider default-kong
  sleep 10
  echo "----- Creating the Kong healthcheck API endpoint -----"
  exit_if_fail retry_fails fog create api-endpoint -f healthcheck-apiendpoint.json --api health --lambda health-lambda
  echo "----- Done creating healthchecks -----"
}

[ ${K8S_PROVIDER:="default"} == "gke" ] && create_gke_healthchecks

echo "TODO: ensure there's a configure_ldap variable here"
if [ "$configure_ldap" == "Yes" ]; then
  ## LDAP setup
  if [ -f ldap-config.yaml ]; then
    echo "Configuring LDAP authentication in gestalt-security..."
    fog admin create-directory -f ldap-config.yaml --org root
    fog admin create-account-store -f root-directory-account-store.yaml --directory root-ldap-directory --org root
  fi
fi


### Create import container action

# Create the container import lambda
fog create resource -f container-import-lambda.yaml --context /root/gestalt-system-workspace/gestalt-system-environment

get_laser_host() {
  local namespace=$(kubectl get svc --all-namespaces | grep lsr | awk '{print $1}')
  [ -z "$namespace" ] && exit_with_error "Could not find laser's namespace, aborting"
  echo "http://lsr.${namespace}.svc.cluster.local:9000"
}

get_lambda_invoke_url() {
  local laser_host=$(get_laser_host)
  local lambda_id=$(fog show lambdas --context /root/gestalt-system-workspace/gestalt-system-environment --name container-import --fields name,id | grep container-import | awk '{print $2}')
  echo "${laser_host}/lambdas/${lambda_id}/invokeSync"
}

patch_caas_provider() {
  local lambda_url=$(get_lambda_invoke_url)
  exit_on_error "Failed to get lambda_url, aborting"

  cat > /tmp/patch.json <<EOF
  [{
    "op": "replace",
    "path": "/properties/config/endpoints",
    "value": [{
        "kind": "",
        "url": "${lambda_url}",
        "actions": [
            {"name": "container.import", "post": {"responses": [{"code": 200}]}},
            {"name": "secret.import", "post": {"responses": [{"code": 200}]}},
            {"name": "volume.import", "post": {"responses": [{"code": 200}]}}
        ]
    }]
}]
EOF

  echo "Patching CaaS provider with container-import info"
  fog meta PATCH -f /tmp/patch.json /root/providers/${caas_provider_id}
  exit_on_error "Failed to patch CaaS provider with container-import info, aborting"
}

caas_provider_id=$(fog show providers / --name default-kubernetes -o json | jq -r '.[].id')
exit_on_error "Failed to get 'default-kubernetes' provider ID, aborting"
if [ "$caas_provider_id" == "null" ]; then
  exit_with_error "caas_provider_id is null, aborting"
fi


# Patch the CaaS provider
patch_caas_provider


### Import containers
import_container() {
  local name=$1

  cat > /tmp/${name}.json <<EOF
{
    "name":"${name}",
    "description":"$name imported on `date`",
    "properties":{
        "image": "n/a",
        "container_type": "DOCKER",
        "provider":{"id":"${caas_provider_id}","locations":[]},
        "external_id": "/namespaces/gestalt-system/deployments/${name}"
    }
}
EOF

  echo "Importing container $name..."
  fog meta POST /root/environments/${gestalt_system_env_id}/containers?action=import -f /tmp/${name}.json
  exit_on_error "Failed to import '${name}' container, aborting"
}


gestalt_system_env_id=$(fog show environments /root/gestalt-system-workspace --fields=name,id | grep gestalt-system-environment | awk '{print $2}')
exit_on_error "Failed to get gestalt-system-environment ID, aborting"

## Skip for now
# for c in `kubectl get deploy -n gestalt-system --no-headers | awk '{print $1}'`; do 
#   import_container $c
# done
