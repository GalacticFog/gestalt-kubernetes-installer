#!/bin/bash

# Needs ./utilities/bash-utilities.sh

[[ $# -ne 1 ]] && echo && exit_with_error "File '$0' expects 1 parameter ($# provided) [$@], aborting."
GENERATED_CONF_FILE=$1


check_for_required_variables \
  admin_username \
  admin_password \
  provision_internal_database \
  database_username \
  database_password \
  docker_registry \
  gestalt_docker_release_tag \
  external_gateway_host \
  gestalt_kong_service_nodeport \
  kubeconfig_data \
  gestalt_custom_resources

  #FOG DEBUG

cat > ${GENERATED_CONF_FILE} << EOF
{
EOF

if [ "${fogcli_debug}" == "true" ]; then
cat >> ${GENERATED_CONF_FILE} << EOF
    "FOGCLI_DEBUG": "${fogcli_debug}",
EOF
fi

cat >> ${GENERATED_CONF_FILE} << EOF
    "ADMIN_USERNAME": "${admin_username}",
    "ADMIN_PASSWORD": "${admin_password}",
    "PROVISION_INTERNAL_DATABASE": "${provision_internal_database}",
    "DATABASE_USERNAME": "${database_username}",
    "DATABASE_PASSWORD": "${database_password}",
    "DATABASE_HOSTNAME": "gestalt-postgresql.gestalt-system.svc.cluster.local",
    "DATABASE_PORT": "5432",
    "DOTNET_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-dotnet:${gestalt_docker_release_tag}",
    "JS_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-js:${gestalt_docker_release_tag}",
    "JVM_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-jvm:${gestalt_docker_release_tag}",
    "NODEJS_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-nodejs:${gestalt_docker_release_tag}",
    "GOLANG_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-golang:${gestalt_docker_release_tag}",
    "PYTHON_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-python:${gestalt_docker_release_tag}",
    "RUBY_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-ruby:${gestalt_docker_release_tag}",
    "GWM_EXECUTOR_IMAGE": "${docker_registry}/gestalt-api-gateway:${gestalt_docker_release_tag}",
    "KONG_IMAGE": "${docker_registry}/kong:${gestalt_docker_release_tag}",
    "LOGGING_IMAGE": "${docker_registry}/gestalt-log:${gestalt_docker_release_tag}",
    "POLICY_IMAGE": "${docker_registry}/gestalt-policy:${gestalt_docker_release_tag}",
    "KONG_VIRTUAL_HOST": "${external_gateway_host}:${gestalt_kong_service_nodeport}",
    "ELASTICSEARCH_HOST": "gestalt-elastic.gestalt-system",
    "RABBIT_HOST": "gestalt-rabbit.gestalt-system",
    "META_HOSTNAME": "gestalt-meta.gestalt-system.svc.cluster.local",
    "META_PORT": "10131",
    "META_PROTOCOL": "http",
    "SECURITY_HOSTNAME": "gestalt-security.gestalt-system.svc.cluster.local",
    "SECURITY_PORT": "9455",
    "SECURITY_PROTOCOL": "http",
    "UI_HOSTNAME": "gestalt-ui.gestalt-system.svc.cluster.local",
    "UI_PORT": "80",
    "UI_PROTOCOL": "http",
    "KUBECONFIG_BASE64": "${kubeconfig_data}",
    "GESTALT_CUSTOM_RESOURCES": ${gestalt_custom_resources},
    "GESTALT_INSTALL_LOGGING_LVL": "${gestalt_install_mode}"
}
EOF
