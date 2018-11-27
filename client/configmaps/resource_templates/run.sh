check_for_required_variables \
    SECURITY_KEY \
    SECURITY_SECRET \
    DATABASE_USERNAME \
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
    KONG_0_VIRTUAL_HOST \
    ELASTICSEARCH_HOST \
    KUBECONFIG_BASE64

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
[ $? -eq 0 ] || (echo "Error setting context, aborting" && exit 1)

# Set up hierarchy
fog create workspace --name 'gestalt-system-workspace' --description "Gestalt System Workspace"
[ $? -eq 0 ] || (echo "Error creating 'gestalt-system-workspace', aborting" && exit 1)

fog create environment 'gestalt-laser-environment' --org 'root' --workspace 'gestalt-system-workspace' --description "Gestalt Laser Environment" --type 'production'
[ $? -eq 0 ] || (echo "Error creating 'gestalt-laser-environment', aborting" && exit 1)

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
sleep 20
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
fog ext meta-schema-V7-migrate -f meta-migrate.json --provider 'default-laser' | jq .

## LDAP setup
if [ -f ldap-config.yaml ]; then
  echo "Configuring LDAP authentication in gestalt-security..."
  fog admin create-directory -f ldap-config.yaml --org root
  fog admin create-account-store -f root-directory-account-store.yaml --directory root-ldap-directory --org root
fi

return 0
