#!/bin/bash
## This script is the entrypoint to the Gestalt Deployer container

error() {
  >&2 echo "[Error] $@"
}

exit_with_error() {
  error "$@"
  exit 1
}

exit_on_error() {
  [ $? -eq 0 ] || exit_with_error "$@"
}

echo "Rendering Helm templates..."
HELM_CMD="helm template gestalt --name gestalt -f helm-config.yaml > gestalt.yaml"
echo "Running helm command '${HELM_CMD}'"
${HELM_CMD}
exit_on_error "Failed: helm template gestalt --name gestalt -f helm-config.yaml > gestalt.yaml"

echo "Creating Kubernetes resources..."
kubectl create -n gestalt-system -f gestalt.yaml
exit_on_error "Failed kubectl apply -n gestalt-system -f gestalt.yaml, aborting."

