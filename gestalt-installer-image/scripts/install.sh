#!/bin/bash
## This script is the entrypoint to the Gestalt Installer container

# Source common project configuration and utilities
# TODO: Make work locally not just from built image
utility_file='/scripts/install-gestalt-platform-initialize.sh'
if [ -f "${utility_file}" ]; then
  . ${utility_file}
else
  echo "[ERROR] Project initialization script '${utility_file}' can not be located, aborting. "
  exit 1
fi

echo "Process configmap ..."
getsalt_installer_load_configmap
echo "Default and validate environment variables ..."
getsalt_installer_setcheck_variables



#provision_internal_database=`jq '.["provision_internal_database"]' ${base_config_map}`
#use_dynamic_loadbalancers=`jq '.["use_dynamic_loadbalancers"]' ${base_config_map}`


## Assume that 'installer-config.json' is present.

# Check if installer-config exists, exit with error if not

# Parse the config file usign jq to get all necessary parameters

####database_password="s1lr7nOGQXmTaoaH"
####admin_password="BZ2pAcpRQ0pyASMn"

# Check to ensure all required parameters are present
# - kubeconfig (in base64 encoding)
# - db username, password

# Generate helm-config.yaml

echo "Generating helm configuration..."

#from config map jq

#here overrride if needed image and imageTag for postgresql
cat > helm-config.yaml <<EOF
security:
  adminPassword: "$admin_password"

postgresql:
  postgresPassword: "$database_password"
  image: "postgres"
  imageTag: "9.6.2"

db:
  password: "$database_password"

installer:
  gestaltCliData: "${KUBECONFIG_BASE64}"
EOF

helm template gestalt --name gestalt -f helm-config.yaml > gestalt.yaml
exit_on_error "Failed: helm template gestalt --name gestalt -f helm-config.yaml > gestalt.yaml"

kubectl apply -n gestalt-system -f gestalt.yaml
exit_on_error "Failed kubectl apply -n gestalt-system -f gestalt.yaml, aborting."




# Stage 2 - Orchestrate the Gestalt Platform installation

cd ./scripts
./install-gestalt-platform.sh

