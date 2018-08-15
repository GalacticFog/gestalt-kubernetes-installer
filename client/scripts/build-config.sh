#!/bin/bash

# Needs ./utilities/bash-utilities.sh

[[ $# -ne 1 ]] && echo && exit_with_error "File '$0' expects 1 parameter ($# provided) [$@], aborting."
GENERATED_CONF_FILE=$1

#database_username=postgres
#database_password="s1lr7nOGQXmTaoaH"

#gestalt_docker_release_tag="release-2.1.0"
#docker_registry="galacticfog"


#external_gateway_host=localhost
#external_gateway_protocol=http
#gestalt_kong_service_nodeport=31113

cat > ${GENERATED_CONF_FILE} << EOF
{
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
    "kubeconfig-base64": "`cat ${conf_kube}`",
    "kong-virtual-host": "${external_gateway_host}:${gestalt_kong_service_nodeport}",
    "elasticsearch-host": "gestalt-elastic.gestalt-system",
    "rabbig-host": "gestalt-rabbit.gestalt-system"
}
EOF



