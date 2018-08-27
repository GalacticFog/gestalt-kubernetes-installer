#!/bin/bash

# Needs ./utilities/bash-utilities.sh

[[ $# -ne 1 ]] && echo && exit_with_error "File '$0' expects 1 parameter ($# provided) [$@], aborting."
GENERATED_CONF_FILE=$1


check_for_required_variables \
  database_username \
  database_password \
  docker_registry \
  gestalt_docker_release_tag \
  external_gateway_host \
  gestalt_kong_service_nodeport



cat > ${GENERATED_CONF_FILE} << EOF
{
    "external_gateway_host": "localhost",
    "external_gateway_protocol": "http",
    "provision_internal_database": "${provision_internal_database}",
    "database-username": "${database_username}",
    "database-password": "${database_password}",
    "database-hostname": "gestalt-postgresql.gestalt-system.svc.cluster.local",
    "dotnet-executor-image": "${docker_registry}/gestalt-laser-executor-dotnet:${gestalt_docker_release_tag}",
    "js-executor-image": "${docker_registry}/gestalt-laser-executor-js:${gestalt_docker_release_tag}",
    "jvm-executor-image": "${docker_registry}/gestalt-laser-executor-jvm:${gestalt_docker_release_tag}",
    "nodejs-executor-image": "${docker_registry}/gestalt-laser-executor-nodejs:${gestalt_docker_release_tag}",
    "python-executor-image": "${docker_registry}/gestalt-laser-executor-python:${gestalt_docker_release_tag}",
    "ruby-executor-image": "${docker_registry}/gestalt-laser-executor-ruby:${gestalt_docker_release_tag}",
    "gwm-image": "${docker_registry}/gestalt-api-gateway:${gestalt_docker_release_tag}",
    "kong-image": "${docker_registry}/kong:${gestalt_docker_release_tag}",
    "logging-image": "${docker_registry}/gestalt-log:${gestalt_docker_release_tag}",
    "policy-image": "${docker_registry}/gestalt-policy:${gestalt_docker_release_tag}",
    "kubeconfig-base64": "${kubeconfig_data}",
    "kong-virtual-host": "${external_gateway_host}:${gestalt_kong_service_nodeport}",
    "elasticsearch-host": "gestalt-elastic.gestalt-system",
    "rabbig-host": "gestalt-rabbit.gestalt-system"
}
EOF


cat > ${GENERATED_CONF_FILE} << EOF
{
    "ADMIN_USERNAME": "${admin_username}",
    "ADMIN_PASSWORD": "${admin_password}",
    "provision_internal_database": "${provision_internal_database}",
    "DATABASE_USERNAME": "${database_username}",
    "DATABASE_PASSWORD": "${database_password}",
    "DATABASE_HOSTNAME": "gestalt-postgresql.gestalt-system.svc.cluster.local",
    "DATABASE_PORT": "5432",
    "dotnet-executor-image": "${docker_registry}/gestalt-laser-executor-dotnet:${gestalt_docker_release_tag}",
    "js-executor-image": "${docker_registry}/gestalt-laser-executor-js:${gestalt_docker_release_tag}",
    "jvm-executor-image": "${docker_registry}/gestalt-laser-executor-jvm:${gestalt_docker_release_tag}",
    "nodejs-executor-image": "${docker_registry}/gestalt-laser-executor-nodejs:${gestalt_docker_release_tag}",
    "golang-executor-image": "${docker_registry}/gestalt-laser-executor-golang:${gestalt_docker_release_tag}",
    "python-executor-image": "${docker_registry}/gestalt-laser-executor-python:${gestalt_docker_release_tag}",
    "ruby-executor-image": "${docker_registry}/gestalt-laser-executor-ruby:${gestalt_docker_release_tag}",
    "gwm-image": "${docker_registry}/gestalt-api-gateway:${gestalt_docker_release_tag}",
    "kong-image": "${docker_registry}/kong:${gestalt_docker_release_tag}",
    "logging-image": "${docker_registry}/gestalt-log:${gestalt_docker_release_tag}",
    "policy-image": "${docker_registry}/gestalt-policy:${gestalt_docker_release_tag}",
    "KUBECONFIG_BASE64": "${kubeconfig_data}",
    "kong-virtual-host": "${external_gateway_host}:${gestalt_kong_service_nodeport}",
    "elasticsearch-host": "gestalt-elastic.gestalt-system",
    "rabbit-host": "gestalt-rabbit.gestalt-system"
}
EOF
