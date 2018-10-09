
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
    KONG_VIRTUAL_HOST \
    ELASTICSEARCH_HOST \
    KUBECONFIG_BASE64

# Generate config
config_file="/tmp/config.json"
envsubst < config.json.template > ${config_file}
if [ $? -ne 0 ]; then
  echo "Error: Failed generate config ${config_file} from template 'config.json.template', aborting."
  exit 1
fi

create() {
  local file=$1.yaml
  echo "Creating resource from '$file'..."
  fog create resource -f $file --config $config_file
  if [ $? -ne 0 ]; then
    echo
    echo "Error: Error processing '$file', aborting."
    exit 1
  fi
}

# Set context
fog context set --path '/root'

# Set up hierarchy
fog create workspace --name 'gestalt-system-workspace' -d "Gestalt System Workspace"
fog create environment -w 'gestalt-system-workspace' -n 'gestalt-laser-environment' -d "Gestalt Laser Environment" -t 'production'

# Create base providers
create db-provider
create security-provider
create kubernetes-provider
create rabbit-provider
create logging-provider

# Link the logging provider to the CaaS provider
# fog meta patch-provider --provider '/root/default-kubernetes' -f link-logging-provider.json

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
create policy-provider
create kong-provider
create gatewaymanager-provider
