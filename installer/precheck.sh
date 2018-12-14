#!/bin/bash
set -o pipefail

. helpers/install-functions.sh

echo "Checking for required dependencies..."

check_for_required_tools

install_prefix=gestalt
install_namespace="gestalt-system"

# Environment checks
check_kubeconfig
check_for_kube
create_or_check_for_required_namespace
check_for_prior_install

check_cluster_capacity
