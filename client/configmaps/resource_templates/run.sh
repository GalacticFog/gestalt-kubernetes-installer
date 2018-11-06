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

# Pause to give Kong a chance to come up and then create the healthcheck API endpoint and lambda
# echo "----- Creating the Kong healthcheck lambda -----"
# create healthcheck-lambda
# echo "----- Creating the Kong healthcheck API endpoint -----"
# create healthcheck-api
# echo "----- Done creating healthchecks -----"

sleep 20  # Provide time for Meta to settle before migrating the schema
fog ext meta-schema-V7-migrate -f meta-migrate.json --provider 'default-laser' | jq .

## LDAP setup
if [ -f ldap/ldap-config.yaml ]; then
  echo "Configuring LDAP authentication in gestalt-security..."
  fog admin create-directory -f ldap/ldap-config.yaml --org root
  fog admin create-account-store -f ldap/root-directory-account-store.yaml --directory root-ldap-directory --org root
fi

return 0
