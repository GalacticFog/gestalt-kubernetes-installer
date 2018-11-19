#!/bin/bash

############################################
# SETUP
############################################

# Source common project configuration and utilities
. ./scripts/utilities/utility-project-check.sh

# Validate that all pre-conditions are met
gestalt_install_validate_preconditions

# Check that the `gestalt-system` namespace exists.  If not, print some commands to create it
kube_check_for_required_namespace ${kube_namespace}

# Make the gestalt-system/default service account a cluster-admin with the ability
# to create namespaces and resources in other namespaces.
echo "Creating ClusterRoleBinding for cluster-admin role for service account '${kube_namespace}/default'..."
kubectl apply -f - <<EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: ${kube_namespace}-cluster-admin
subjects:
- kind: ServiceAccount
  name: default
  namespace: ${kube_namespace}
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
#  name: gestalt-deployer-sa

# Create ConfigMap resources the installer pod depends on
#echo "Creating ConfigMaps resources for installer..."
#gestalt_install_create_configmaps

echo "Done."
