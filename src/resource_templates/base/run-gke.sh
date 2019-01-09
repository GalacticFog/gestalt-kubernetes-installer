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

# Set context
fog context set '/root'
[ $? -eq 0 ] || (echo "Error setting context, aborting" && exit 1)

# Set up hierarchy
fog create workspace --name 'gestalt-system-workspace' --description "Gestalt System Workspace"
[ $? -eq 0 ] || (echo "Error creating 'gestalt-system-workspace', aborting" && exit 1)

fog create environment 'gestalt-laser-environment' --org 'root' --workspace 'gestalt-system-workspace' --description "Gestalt Laser Environment" --type 'production'
[ $? -eq 0 ] || (echo "Error creating 'gestalt-laser-environment', aborting" && exit 1)

fog create environment 'gestalt-system-environment' --org 'root' --workspace 'gestalt-system-workspace' --description "Gestalt System Environment" --type 'production'
[ $? -eq 0 ] || (echo "Error creating 'gestalt-system-environment', aborting" && exit 1)


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

# Create other providers
create laser-provider
create policy-provider # Policy depends on Rabbit and Laser

# Create Kong API Provider
create kong-provider

# Uncomment to enable, and also ensure that the gatewaymanager provider has linked providers for each kong.
# create kong2-provider
# create kong3-external-provider

create gatewaymanager-provider  # Create the gateway manager provider after 
                                # kong providers, as it uses the kong providers as linked providers

create_healthchecks() {
  local healthcheck_environment=gestalt-health-environment
  exit_if_fail retry_fails fog create environment $healthcheck_environment --org 'root' --workspace 'gestalt-system-workspace' --type 'production' --description '"Gestalt HealthCheck Environment"'
  sleep 15
  gestalt_healthcheck_context="/root/gestalt-system-workspace/$healthcheck_environment"
  exit_if_fail retry_fails fog context set $gestalt_healthcheck_context
  echo "----- Creating the Kong healthcheck lambda -----"
  exit_if_fail retry_fails fog create resource -f healthcheck-lambda.json
  sleep 15
  echo "----- Creating the Kong healthcheck API -----"
  exit_if_fail retry_fails fog create api --name health --description healthcheck-api --provider default-kong
  sleep 15
  echo "----- Creating the Kong healthcheck API endpoint -----"
  exit_if_fail retry_fails fog create api-endpoint -f healthcheck-apiendpoint.json --api health --lambda health-lambda
  echo "----- Done creating healthchecks -----"
}

# Pause to give Kong a chance to come up and then create the healthcheck API endpoint and lambda
sleep 20
create_healthchecks


sleep 20  # Provide time for Meta to settle before migrating the schema
fog ext meta-schema-V7-migrate -f meta-migrate.json --provider 'default-laser' | jq .

# Catalog provider
if [ "$configure_catalog" == "Yes" ]; then
  create catalog-provider-inline
fi

## LDAP setup
if [ -f ldap/ldap-config.yaml ]; then
  echo "Configuring LDAP authentication in gestalt-security..."
  fog admin create-directory -f ldap/ldap-config.yaml --org root
  fog admin create-account-store -f ldap/root-directory-account-store.yaml --directory root-ldap-directory --org root
fi

return 0
