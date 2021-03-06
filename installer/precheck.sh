#!/bin/bash
set -o pipefail

. helpers/install-functions.sh
. gestalt.conf

PROFILE=$1

if [ -z "$PROFILE" ]; then
  exit_with_error "Must specify an installation profile (docker-desktop, minikube, gke, eks, aws)"
elif [ ! -d ./profiles/$PROFILE ]; then
  exit_with_error "Invalid profile: $PROFILE" 
fi

if [ -z "$RELEASE_NAME" ]; then
  echo "Application RELEASE_NAME is not defined - using default value 'gestalt'"
  RELEASE_NAME='gestalt'
fi
debug "Install Gestalt with application name '${RELEASE_NAME}'"

if [ -z "$RELEASE_NAMESPACE" ]; then
  echo "Kubernetes RELEASE_NAMESPACE is not defined - using default value 'gestalt-system'"
  RELEASE_NAMESPACE='gestalt-system'
fi
debug "Install Gestalt in Kubernetes Namespace '${RELEASE_NAMESPACE}'"

# echo "Checking for required dependencies..."

check_for_required_tools

download_fog_cli

# Run profile-specific pre-check
run_helper $PROFILE pre-check

# Environment checks
check_for_kube
create_or_check_for_required_namespace
check_for_prior_install

check_cluster_capacity
