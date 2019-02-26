#!/bin/bash

# Import functions
. ../../scripts/install-functions.sh
. run-functions.sh
. run-functions-gke.sh

# Enable Debug for CLI
if [ "${FOG_CLI_DEBUG}" == "true" ]; then
  fog config set debug=true
fi

# Set context
fog context set '/root'
exit_on_error "Error setting context, aborting"

# https://gitlab.com/galacticfog/gestalt-meta/issues/597#note_139551352
# fog meta POST /migrate?version=V31

# Meta migration v7 creates a lambda - so can not be done now, but we want rest to be run as they are added
fog meta POST /migrate?skip=V7 > /tmp/migrate.out
cat /tmp/migrate.out | jq .
echo ...

# Check for migration any failure
cat /tmp/migrate.out | jq . | grep -i failure
if [ $? -eq 0 ]; then 
  echo "Meta migration did not fully succeed"
  cat /tmp/migrate.out | jq . | grep -i failure -A20 -B5
  echo
  echo "Full log:"
  cat /tmp/migrate.out
  exit_with_error "Meta migration did not succeed, aborting"
fi

# Set up hierarchy
fog create workspace --name 'gestalt-system-workspace' --description "Gestalt System Workspace"
exit_on_error "Error creating 'gestalt-system-workspace', aborting"

fog create environment 'gestalt-laser-environment' --org 'root' --workspace 'gestalt-system-workspace' --description "Gestalt Laser Environment" --type 'production'
exit_on_error "Error creating 'gestalt-laser-environment', aborting"

fog create environment 'gestalt-system-environment' --org 'root' --workspace 'gestalt-system-workspace' --description "Gestalt System Environment" --type 'production'
exit_on_error "Error creating 'gestalt-system-environment', aborting"

# Create base providers
create db-provider
create security-provider
create kubernetes-provider
create rabbit-provider
create logging-provider

# Link the logging provider to the CaaS provider
fog meta patch-provider --provider '/root/default-kubernetes' -f link-logging-provider.yaml

# Create Executor Providers
create js-executor
create jvm-executor
create dotnet-executor
create golang-executor
create nodejs-executor
create python-executor
create ruby-executor
create graalvm-jvm-scala-executor
create graalvm-nodejs-executor
create graalvm-lvm-executor
create bash-executor

# Laser - create custom executors if applicable
if [ "${LASER_PROVIDER_CUSTOMIZE}" == "1" ]; then
  for CURR_EXECUTOR in $(echo ${LASER_PROVIDER_CUSTOM_EXECUTORS[@]} | sed "s/:/ /g"); do
    create ${CURR_EXECUTOR}
  done
  create ${LASER_PROVIDER_DEFINITION}
else
  create laser-provider
fi

# Create other providers
create policy-provider # Policy depends on Rabbit and Laser
create kong-provider

# Uncomment to enable additional kong providers, and also ensure that the gatewaymanager provider has linked providers for each kong.
# create kong2-provider
# create kong3-external-provider

create gatewaymanager-provider  # Create the gateway manager provider after 
                                # kong providers, as it uses the kong providers as linked providers

## Copy in secrets to all Gestalt Managed Namespaces
if [ "${CUSTOM_IMAGE_PULL_SECRET}" == "1" ]; then
  apply_image_pull_secrets
fi

# Wait for laser, as Meta migration v7 creates a lambda
wait_for_pod lsr

#TODO: Implement a laser health check to avoid sleep?
sleep 20  # Provide time for Laser and Meta to settle before migrating the schema

# fog meta POST /migrate -f meta-migrate.json > /tmp/migrate.out
# cat /tmp/migrate.out | jq .
# echo ...

fog meta POST /migrate?version=V7 -f meta-migrate.json > /tmp/migrate.out
cat /tmp/migrate.out | jq .
echo ...

# Check for migration any failure
cat /tmp/migrate.out | jq . | grep -i failure
if [ $? -eq 0 ]; then 
  echo "Meta migration did not fully succeed"
  cat /tmp/migrate.out | jq . | grep -i failure -A20 -B5
  echo
  echo "Full log:"
  cat /tmp/migrate.out
  exit_with_error "Meta migration did not succeed, aborting"
fi

# Catalog provider
if [ "$configure_catalog" == "Yes" ]; then
  create catalog-provider-inline
fi

# Create GKE healthchecks
if [ "$K8S_PROVIDER" == "gke" ]; then
  create_gke_healthchecks
fi

echo "TODO: ensure there's a configure_ldap variable here"
if [ "$configure_ldap" == "Yes" ]; then
  ## LDAP setup
  if [ -f ldap-config.yaml ]; then
    echo "Configuring LDAP authentication in gestalt-security..."
    fog admin create-directory -f ldap-config.yaml --org root
    fog admin create-account-store -f root-directory-account-store.yaml --directory root-ldap-directory --org root
  fi
fi

### Create import container action

# Create the container import lambda
fog create resource -f container-import-lambda.yaml --context /root/gestalt-system-workspace/gestalt-system-environment

# Create Gestalt System Environment Resources
#   Migrate Lambda
fog apply -d ../gestalt-system-environment --context /root/gestalt-system-workspace/gestalt-system-environment

# Patch the CaaS provider with Container import action
patch_caas_provider_with_container_import_action

### Import containers

## Skip for now, until container import is fully functional
import_gestalt_system_k8s_resources

# Wait for pods to start before moving on to the next stage, which creates APIs.  API
# creation will fail if the GWM and/or Kong images haven't started yet (images may still be being pulled down)
wait_for_pod gwm
wait_for_pod kng
