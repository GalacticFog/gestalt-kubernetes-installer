#!/bin/bash

# Needs ./utilities/bash-utilities.sh

[[ $# -ne 1 ]] && echo && exit_with_error "File '$0' expects 1 parameter ($# provided) [$@], aborting."
GENERATED_CONF_FILE=$1

check_for_required_variables \
  admin_username \
  admin_password \
  provision_internal_database \
  database_image \
  database_image_tag \
  database_username \
  database_password \
  database_hostname \
  docker_registry \
  gestalt_docker_release_tag \
  gestalt_kong_service_host \
  gestalt_kong_service_nodeport \
  kubeconfig_data \
  gestalt_ui_service_nodeport \
  gestalt_kong_service_nodeport \
  gestalt_logging_service_nodeport

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
    "ADMIN_PASSWORD": "${admin_password}",
    "ADMIN_USERNAME": "${admin_username}",
    "CUSTOM_IMAGE_PULL_SECRET": "${custom_image_pull_secret}",
    "DATABASE_HOSTNAME": "${database_hostname}",
    "DATABASE_IMAGE": "${database_image}",
    "DATABASE_IMAGE_TAG": "${database_image_tag}",
    "DATABASE_NAME": "${database_name}",
    "DATABASE_PASSWORD": "${database_password}",
    "DATABASE_PORT": "5432",
    "DATABASE_USERNAME": "${database_username}",
    "DOTNET_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-dotnet:${gestalt_docker_release_tag}",
    "ELASTICSEARCH_HOST": "gestalt-elastic.gestalt-system",
    "ELASTICSEARCH_IMAGE": "${docker_registry}/elasticsearch-docker:5.3.1",
    "FOG_CLI_DEBUG": "${gestalt_fogcli_debug:-false}",
    "GESTALT_INSTALL_LOGGING_LVL": "${gestalt_install_mode}",
    "GOLANG_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-golang:${gestalt_docker_release_tag}",
    "GWM_EXECUTOR_IMAGE": "${docker_registry}/gestalt-api-gateway:${gestalt_docker_release_tag}",
    "GWM_IMAGE": "${docker_registry}/gestalt-api-gateway:${gestalt_docker_release_tag}",
    "JS_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-js:${gestalt_docker_release_tag}",
    "JS_EXECUTOR_MIN_COOL": "${gestalt_laser_executor_js_mincool:-0}",
    "JVM_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-jvm:${gestalt_docker_release_tag}",
    "KONG_IMAGE": "${docker_registry}/kong:${gestalt_docker_release_tag}",
    "KONG_INGRESS_SERVICE_NAME": "kng-ext",
    "KONG_NODEPORT": "${gestalt_kong_service_nodeport}",
    "KONG_MANAGEMENT_NODEPORT": "${gestalt_kong_management_nodeport}",
    "KONG_0_VIRTUAL_HOST": "${gestalt_kong_service_host}",
    "KONG_0_EXTERNAL_PROTOCOL" :"${gestalt_kong_service_protocol:-http}",
    "KUBECONFIG_BASE64": "${kubeconfig_data}",
    "LASER_IMAGE": "${docker_registry}/gestalt-laser:${gestalt_docker_release_tag}",
    "LASER_SERVICE_VHOST": "${laser_service_vhost}",
    "LASER_NODEPORT": "${gestalt_laser_service_nodeport}",
    "LASER_PROVIDER_CUSTOMIZE": "${gestalt_laser_customize:-0}",
    "LASER_PROVIDER_DEFINITION": "${gestalt_laser_provider_definition:-laser-provider}",
    "LASER_PROVIDER_CUSTOM_EXECUTORS": "${gestalt_laser_executor_list[@]}",  
    "LOGGING_SERVICE_HOST": "${logging_service_host}",
    "LOGGING_SERVICE_PROTOCOL": "${logging_service_protocol}",
    "LOGGING_IMAGE": "${docker_registry}/gestalt-log:${gestalt_docker_release_tag}",
    "LOGGING_NODEPORT": "${gestalt_logging_service_nodeport}",
    "META_HOSTNAME": "gestalt-meta.gestalt-system.svc.cluster.local",
    "META_IMAGE": "${docker_registry}/gestalt-meta:${gestalt_meta_release_tag:-$gestalt_docker_release_tag}",
    "META_PORT": "10131",
    "META_PROTOCOL": "http",
    "NODEJS_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-nodejs:${gestalt_docker_release_tag}",
    "POLICY_IMAGE": "${docker_registry}/gestalt-policy:${gestalt_docker_release_tag}",
    "PROVISION_INTERNAL_DATABASE": "${provision_internal_database}",
    "PYTHON_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-python:${gestalt_laser_executor_python_release_tag:-gestalt_docker_release_tag}",
    "PYTHON_EXECUTOR_MIN_COOL": "${gestalt_laser_executor_python_mincool:-0}",
    "PYTHON_3_6_1_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-python:${gestalt_laser_executor_python_361_release_tag:-python-3.6.1}",
    "PYTHON_3_6_1_EXECUTOR_MIN_COOL": "${gestalt_laser_executor_python_361_mincool:-0}",
    "PYTHON_3_6_3_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-python:${gestalt_laser_executor_python_363_release_tag:-python-3.6.3}",
    "PYTHON_3_6_3_EXECUTOR_MIN_COOL": "${gestalt_laser_executor_python_363_mincool:-0}",
    "RABBIT_HOST": "gestalt-rabbit.gestalt-system",
    "RABBIT_HOSTNAME": "gestalt-rabbit.gestalt-system",
    "RABBIT_HTTP_PORT": "15672",
    "RABBIT_IMAGE": "${docker_registry}/rabbit:${gestalt_docker_release_tag}",
    "RABBIT_PORT": "5672",
    "RUBY_EXECUTOR_IMAGE": "${docker_registry}/gestalt-laser-executor-ruby:${gestalt_docker_release_tag}",
    "SECURITY_HOSTNAME": "gestalt-security.gestalt-system.svc.cluster.local",
    "SECURITY_IMAGE": "${docker_registry}/gestalt-security:${gestalt_docker_release_tag}",
    "SECURITY_PORT": "9455",
    "SECURITY_PROTOCOL": "http",
    "UI_HOSTNAME": "gestalt-ui.gestalt-system.svc.cluster.local",
    "UI_IMAGE": "${docker_registry}/gestalt-ui-react:${gestalt_docker_release_tag}",
    "UI_NODEPORT": "${gestalt_ui_service_nodeport}",
    "UI_PORT": "80",
    "UI_PROTOCOL": "http"
}
EOF

# TODO: Move this into another location
cat > ../gestalt-installer-image/gestalt/values.yaml <<EOF
# TODO - Pull out additional configuration options
common:
  imagePullPolicy: Always
  # imagePullPolicy: IfNotPresent

security:
  exposedServiceType: NodePort
  hostname: gestalt-security.gestalt-system
  port: 9455
  protocol: http
  databaseName: gestalt-security

rabbit:
  hostname: gestalt-rabbit.gestalt-system
  port: 5672
  httpPort: 15672

elastic:
  hostname: gestalt-elastic.gestalt-system
  restPort: 9200
  transportPort: 9300
  initContainer:
    image: busybox:1.27.2

meta:
  exposedServiceType: NodePort
  hostname: gestalt-meta.gestalt-system
  port: 10131
  protocol: http
  databaseName: gestalt-meta
  nodePort: ${gestalt_meta_service_nodeport}

kong:
  nodePort: $KONG_NODEPORT

logging:
  nodePort: $LOGGING_NODEPORT

ui:
  exposedServiceType: NodePort
  nodePort: $UI_NODEPORT
  ingress:
    host: localhost

# Gestalt DB settings
db:
  # Hostname must be fully qualified for Kong service
  hostname: ${database_hostname}
  port: 5432
  # username: postgres
  databaseName: postgres

# The following only applies if the gestalt-postgresql chart is deployed
postgresql:
  postgresUser: ${database_username}
  postgresDatabase: ${database_name}
  persistence:
    size: ${internal_database_pv_storage_size}
    storageClass: "${internal_database_pv_storage_class}"
    subPath: "${postgres_persistence_subpath}"
  resources:
    requests:
      memory: ${postgres_memory_request}
      cpu: ${postgres_cpu_request}
  service:
    port: 5432
    type: ClusterIP
EOF

## LDAP Config

# First remove the existing file so it won't get staged
[ -f ./configmaps/resource_templates/ldap-config.yaml ] && \
  rm ./configmaps/resource_templates/ldap-config.yaml

if [ "$configure_ldap" == "Yes" ]; then
  echo "Will configure LDAP, copying LDAP config from ldap-config.yaml"
  cp ldap-config.yaml ./configmaps/resource_templates/ldap-config.yaml
  exit_on_error "Failed to copy ldap-config.yaml"
fi

[ -f ./configmaps/cacerts ] && \
  rm ./configmaps/cacerts

if [ ! -z "$gestalt_security_cacerts_file" ]; then
  cp $gestalt_security_cacerts_file ./configmaps/cacerts
  exit_on_error "Failed to copy $gestalt_security_cacerts_file"
fi