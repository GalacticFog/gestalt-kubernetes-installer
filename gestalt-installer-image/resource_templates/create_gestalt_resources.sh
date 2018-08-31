#!/bin/bash

exit_on_error() {
  if [ $? -ne 0 ]; then
    echo
    echo "[Error] $@"
    exit 1
  fi
}


echo "Create Workspace"
fog create workspace --name gestalt-system-workspace -d "Gestalt System Workspace" ${GESTALT_FOGCLI_OPTS}
exit_on_error "Failed to create workspace (error code $?), aborting."

echo "Create Environment"
fog create environment -w gestalt-system-workspace -n gestalt-laser-environment -d "Gestalt Laser Environment" -t production ${GESTALT_FOGCLI_OPTS}
exit_on_error "Failed to create environment (error code $?), aborting."

echo "Create Resources: Providers"
all_configs="db security kubernetes rabbit logging"
for curr_config in ${all_configs[@]}; do
  fog create resource -f ${curr_config}-provider.json --config config.json ${GESTALT_FOGCLI_OPTS}
  exit_on_error "Failed to create resource: provider '${curr_config}' (error code $?), aborting."
done

echo "Link Logging Provider"
fog meta patch-provider --provider /root/default-kubernetes -f link-logging-provider.json ${GESTALT_FOGCLI_OPTS}
exit_on_error "Failed to link logging provider (error code $?), aborting."


echo "Create Resources: Executors"
all_configs="js jvm dotnet golang nodejs python ruby"
for curr_config in ${all_configs[@]}; do
  fog create resource -f ${curr_config}-executor.json --config config.json ${GESTALT_FOGCLI_OPTS}
  exit_on_error "Failed to create resource: executor '${curr_config}' (error code $?), aborting."
done


echo "Create Resources: Providers"
all_configs="laser policy kong gatewaymanager"
for curr_config in ${all_configs[@]}; do
  fog create resource -f ${curr_config}-provider.json --config config.json ${GESTALT_FOGCLI_OPTS}
  exit_on_error "Failed to create resource: provider '${curr_config}' (error code $?), aborting."
done
