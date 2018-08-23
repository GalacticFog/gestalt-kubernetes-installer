#!/bin/bash
## This script is the entrypoint to the Gestalt Installer container

# Set base variables and source helper functions
script_folder="/scripts"
scipt_install_helper="${script_folder}/install-functions.sh"
base_config_map="/config/install-config.json"

ls -la ${script_folder}

if [ ! -f "${scipt_install_helper}" ]; then
   echo "[script_folder=${script_folder}][`ls -la ${script_folder}`]"
   echo "[ERROR] Utility file '${scipt_install_helper}' not found, aborting."
   exit 1
else
  source "${scipt_install_helper}"
  if [ $? -ne 0 ]; then
    echo "[ERROR] Unable source utility file '${scipt_install_helper}', aborting."
    exit 1
  fi
fi

logging_lvl="debug" # error, info, debug

echo "aaaa"

# cat ${base_config_map}

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

check_for_required_variables \
  DATABASE_HOSTNAME \
  DATABASE_USERNAME \
  DATABASE_PASSWORD 


SECURITY_URL='http://gestalt-security.gestalt-system.svc.cluster.local:9455'
META_URL='http://gestalt-meta.gestalt-system.svc.cluster.local:10131'


## Assume that 'installer-config.json' is present.

# Check if installer-config exists, exit with error if not

# Parse the config file usign jq to get all necessary parameters

database_password="s1lr7nOGQXmTaoaH"
admin_password="BZ2pAcpRQ0pyASMn"

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

echo "xxx"

#cat helm-config.yaml

echo "yyy"

helm_os="linux"
helm_version="2.9.1"
url="https://storage.googleapis.com/kubernetes-helm/helm-v$helm_version-$helm_os-amd64.tar.gz"
curl -L $url -o helm.tar.gz
tar xfzv helm.tar.gz
cp linux-amd64/helm /bin/
chmod +x /bin/helm

echo "yyyyyyy2222"





#echo "[yyy1][`pwd`][`ls -la`]"
#echo "[yyy2][bin][`ls -la /bin`]"

#need add helm - modify fetch deps an change no ./bin or lookup where script does this like for kubectl

# Render the Kubernetes resources using helm
###rasma temp messing around was just .
/bin/helm template gestalt --name gestalt -f helm-config.yaml > gestalt.yaml
exit_on_error "Failed ./bin/helm template gestalt --name gestalt -f helm-config.yaml > gestalt.yaml"

echo "zzz"

# cat gestalt.yaml

echo "zzzz2"

# Abort if error (consider using pipefail, or detect non-zero exit code and return a specific error message)

# Deploy the core gestalt services
###rasma temp messing around was just .
/bin/kubectl apply -n gestalt-system -f gestalt.yaml
exit_on_error "Failed ./bin/kubectl apply -n gestalt-system -f gestalt.yaml, aborting."




# Stage 2 - Orchestrate the Gestalt Platform installation

cd ./scripts
./install-gestalt-platform.sh
