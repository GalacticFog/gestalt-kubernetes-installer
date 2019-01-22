#!/bin/bash
set -o pipefail

. helpers/install-functions.sh
. gestalt.conf

profile=$1

if [ -z "$profile" ]; then
  exit_with_error "Must specify an installation profile (docker-for-desktop, minikube, gke, eks, aws)"
elif [ ! -d ./profiles/$profile ]; then
  exit_with_error "Invalid profile: $profile" 
fi

# echo "Checking for required dependencies..."

check_for_required_tools

download_fog_cli

# Run profile-specific pre-check
run_helper pre-check

install_prefix=gestalt
install_namespace="gestalt-system"

# Environment checks
check_for_kube
create_or_check_for_required_namespace
check_for_prior_install

check_cluster_capacity
