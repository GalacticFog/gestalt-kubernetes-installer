#!/bin/bash

# Source common project configuration and utilities
utility_file='./scripts/utilities/utility-project-check.sh'
if [ -f ${utility_file} ]; then
  . ${utility_file}
else
  echo "[ERROR] Project initialization script '${utility_file}' can not be located, aborting. "
  exit 1
fi

#Check for required tools
check_if_installed base64 tr sed seq sudo true kubectl curl unzip tar jq

log_debug "" && log_debug "[Info] Obtain current context 'kubectl config current-context' ..."
kubectl_context=$(kubectl config current-context)
exit_on_error "Unable determine current context '${kubectl} config current-context', aborting."

# check_for_kube

## CACERTS file
# TODO: Make debug: echo "Checking for custom cacerts..."

# First, delete the original file so it won't be staged
[ -f ./stage/cacerts ] && \
  rm ./stage/cacerts

# Copy the file
if [ ! -z "$gestalt_security_cacerts_file" ]; then
  echo "Copying $gestalt_security_cacerts_file to ./stage/cacerts ..."
  cp $gestalt_security_cacerts_file ./stage/cacerts
  exit_on_error "Failed to copy $gestalt_security_cacerts_file"
fi

# echo
# echo "Installer configuration succeeded."

# Validate that all pre-conditions are met
gestalt_install_validate_preconditions

# Check that the target namespace exists.  If not, print some commands to create it
kube_check_for_required_namespace ${RELEASE_NAMESPACE}

# TODO # Create an install token, which has to match the target environment
# install_token=`randompw`
# kubectl create secret generic gestalt-install --from-literal=token=${install_token}

# Make the gestalt-system/default service account a cluster-admin with the ability
# to create namespaces and resources in other namespaces.

echo "Creating ClusterRoleBinding for cluster-admin role for service account '${RELEASE_NAMESPACE}/default'"
kubectl apply -f - <<EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: ${RELEASE_NAMESPACE}-cluster-admin
subjects:
- kind: ServiceAccount
  name: default
  namespace: ${RELEASE_NAMESPACE}
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF

# Copy from source
[ -d ../src/gestalt-helm-chart ] && cp -r ../src/gestalt-helm-chart ./stage/
[ -d ../src/resource_templates ] && cp -r ../src/resource_templates ./stage/
[ -d ../src/scripts ] && cp -r ../src/scripts ./stage/

# TODO: Make debug:echo "Creating ConfigMaps resources for installer..."

cd stage
if [ -e b64data ]; then rm b64data; fi
tar cfzv - * 2>/dev/null | base64 > b64data
cd ~-

cmd="kubectl create configmap -n ${RELEASE_NAMESPACE} install-data --from-file ./stage/b64data"
$cmd
exit_on_error "Failed create configmap from resource_templates directory, aborting."

# for CACERTS file
# echo "TODO: Ensure cacerts is handled properly"
if [ -f stage/cacerts ]; then
  CERT_MAP_NAME="${RELEASE_NAME}-security-cacerts"
  echo "Creating '${CERT_MAP_NAME}' configmap from $gestalt_security_cacerts_file..."
  kubectl create configmap -n ${RELEASE_NAMESPACE} ${CERT_MAP_NAME} --from-file=stage/cacerts
  exit_on_error "Failed to build gestalt configmap data"
fi

# Image pull secrets ...
if [ "${custom_image_pull_secret}" == "1" ]; then
  check_for_required_variables custom_image_pull_secret_namespace custom_image_pull_secret_name RELEASE_NAMESPACE
  kube_copy_secret ${custom_image_pull_secret_namespace} ${custom_image_pull_secret_name} ${RELEASE_NAMESPACE} "imagepullsecret-1"
fi
