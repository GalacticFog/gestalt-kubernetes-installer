
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
envsubst < config.json.template > config.json

# Set context
fog context set --path '/root'

# Set up hierarchy
fog create workspace --name 'gestalt-system-workspace' -d "Gestalt System Workspace"
fog create environment -w 'gestalt-system-workspace' -n 'gestalt-laser-environment' -d "Gestalt Laser Environment" -t 'production'

# Create base providers
fog create resource -f db-provider.json --config config.json
fog create resource -f security-provider.json --config config.json
fog create resource -f kubernetes-provider.json --config config.json
fog create resource -f rabbit-provider.json --config config.json
fog create resource -f logging-provider.json --config config.json

# Link the logging provider to the CaaS provider
# fog meta patch-provider --provider '/root/default-kubernetes' -f link-logging-provider.json

# Create Executor Providers
fog create resource -f js-executor.json --config config.json
fog create resource -f jvm-executor.json --config config.json
fog create resource -f dotnet-executor.json --config config.json
fog create resource -f golang-executor.json --config config.json
fog create resource -f nodejs-executor.json --config config.json
fog create resource -f python-executor.json --config config.json
fog create resource -f ruby-executor.json --config config.json

# Create other providers
fog create resource -f laser-provider.json --config config.json
fog create resource -f policy-provider.json --config config.json
fog create resource -f kong-provider.json --config config.json
fog create resource -f gatewaymanager-provider.json --config config.json
