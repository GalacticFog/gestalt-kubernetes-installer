
check_for_required_variables \
    SECURITY_KEY \
    SECURITY_SECRET \
    DATABASE_USERNAME \
    DATABASE_PASSWORD \
    DATABASE_HOSTNAME \
    RABBIT_HOSTNAME \
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
fog create environment -w 'gestalt-system-workspace' -n 'gestalt-system-environment' -d "Gestalt System Environment" -t 'production'

# Create base providers
fog create resources --config $config_file \
  db-provider.yaml \
  security-provider.yaml \
  kubernetes-provider.yaml \
  rabbit-provider.yaml \
  logging-provider.yaml

# Link the logging provider to the CaaS provider
# fog meta patch-provider --provider '/root/default-kubernetes' -f link-logging-provider.json

# Create Executor Providers
fog create resources --config $config_file \
  js-executor.yaml \
  jvm-executor.yaml \
  dotnet-executor.yaml \
  golang-executor.yaml \
  nodejs-executor.yaml \
  python-executor.yaml \
  ruby-executor.yaml

# Create other providers
fog create resources --config $config_file \
  laser-provider.yaml \
  policy-provider.yaml # Policy depends on Rabbit and Laser

create kong-provider

# Uncomment to enable, and also ensure that the gatewaymanager provider has linked providers for each kong.
create kong2-provider
# create kong3-external-provider

create gatewaymanager-provider  # Create the gateway manager provider after 
                                # kong providers, as it uses the kong providers as linked providers

fog ext meta-schema-V7-migrate -f meta-migrate.json --provider 'default-laser'
