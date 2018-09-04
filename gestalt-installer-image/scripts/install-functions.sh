#!/bin/bash

# Generic functions are in utilities-bash.sh

getsalt_installer_load_configmap() {

  check_for_required_variables gestalt_config
  validate_json ${gestalt_config}
  convert_json_to_env_variables ${gestalt_config} #process config map
  check_for_required_variables GESTALT_INSTALL_LOGGING_LVL
  logging_lvl=${GESTALT_INSTALL_LOGGING_LVL}
  log_set_logging_lvl
  logging_lvl_validate 
  # print_env_variables #will print only if debug

}

getsalt_installer_setcheck_variables() {

  export EXTERNAL_GATEWAY_HOST=localhost
  export EXTERNAL_GATEWAY_PROTOCOL=http

  if ! is_dynamic_lb_enabled ; then
    echo "Dynamic load balancing is not enabled, checking for required variables"
    check_for_required_variables \
      EXTERNAL_GATEWAY_HOST \
      EXTERNAL_GATEWAY_PROTOCOL
  fi

  # Check all variables in one call
  check_for_required_variables \
    ADMIN_PASSWORD \
    ADMIN_USERNAME \
    DATABASE_HOSTNAME \
    DATABASE_PASSWORD \
    DATABASE_USERNAME \
    DOTNET_EXECUTOR_IMAGE \
    ELASTICSEARCH_HOST \
    ELASTICSEARCH_IMAGE \
    GOLANG_EXECUTOR_IMAGE \
    GWM_EXECUTOR_IMAGE \
    JS_EXECUTOR_IMAGE \
    JVM_EXECUTOR_IMAGE \
    KONG_IMAGE \
    KONG_VIRTUAL_HOST \
    KUBECONFIG_BASE64 \
    LOGGING_IMAGE \
    META_HOSTNAME \
    META_IMAGE \
    META_PORT \
    META_PROTOCOL \
    NODEJS_EXECUTOR_IMAGE \
    POLICY_IMAGE \
    PYTHON_EXECUTOR_IMAGE \
    RABBIT_HOST \
    RABBIT_HOSTNAME \
    RABBIT_HTTP_PORT \
    RABBIT_IMAGE \
    RABBIT_PORT \
    RUBY_EXECUTOR_IMAGE \
    SECURITY_HOSTNAME \
    SECURITY_IMAGE \
    SECURITY_PORT \
    SECURITY_PROTOCOL \
    UI_HOSTNAME \
    UI_IMAGE \
    UI_PORT \
    UI_PROTOCOL

  export SECURITY_URL="$SECURITY_PROTOCOL://$SECURITY_HOSTNAME:$SECURITY_PORT"
  export META_URL="$META_PROTOCOL://$META_HOSTNAME:$META_PORT"
  export UI_URL="$UI_PROTOCOL://$UI_HOSTNAME:$UI_PORT"

  # Acces points - uris
  check_for_required_variables \
    SECURITY_URL \
    META_URL \
    UI_URL

  check_for_optional_variables \
    META_BOOTSTRAP_PARAMS
}

gestalt_installer_generate_helm_config() {

  check_for_required_variables \
    SECURITY_IMAGE \
    SECURITY_HOSTNAME \
    SECURITY_PORT \
    SECURITY_PROTOCOL \
    ADMIN_USERNAME \
    ADMIN_PASSWORD \
    DATABASE_IMAGE \
    DATABASE_IMAGE_TAG \
    DATABASE_PASSWORD \
    DATABASE_USERNAME \
    KUBECONFIG_BASE64 \
    RABBIT_IMAGE \
    RABBIT_HOSTNAME \
    RABBIT_PORT \
    RABBIT_HTTP_PORT \
    ELASTICSEARCH_IMAGE \
    META_IMAGE \
    META_HOSTNAME \
    META_PORT \
    META_PROTOCOL \
    KONG_NODEPORT \
    LOGGING_NODEPORT \
    UI_IMAGE \
    UI_NODEPORT

  cat > helm-config.yaml <<EOF
security:
  image: "${SECURITY_IMAGE}"
  hostname: "${SECURITY_HOSTNAME}"
  port: "${SECURITY_PORT}"
  protocol: "${SECURITY_PROTOCOL}"
  adminUser: "${ADMIN_USERNAME}"
  adminPassword: "${ADMIN_PASSWORD}"

postgresql:
  postgresPassword: "${DATABASE_PASSWORD}"
  image: "${DATABASE_IMAGE}"
  imageTag: "${DATABASE_IMAGE_TAG}"

db:
  username: "${DATABASE_USERNAME}"
  password: "${DATABASE_PASSWORD}"

installer:
  gestaltCliData: "${KUBECONFIG_BASE64}"

rabbit:
  image: "${RABBIT_IMAGE}"
  hostname: "${RABBIT_HOSTNAME}"
  port: ${RABBIT_PORT}
  httpPort: ${RABBIT_HTTP_PORT}

elastic:
  image: ${ELASTICSEARCH_IMAGE}

meta:
  image: ${META_IMAGE}
  exposedServiceType: NodePort
  hostname: ${META_HOSTNAME}
  port: ${META_PORT}
  protocol: ${META_PROTOCOL}
  databaseName: gestalt-meta

kong:
  nodePort: ${KONG_NODEPORT}

logging:
  nodePort: ${LOGGING_NODEPORT}

ui:
  image: ${UI_IMAGE}
  exposedServiceType: NodePort
  nodePort: ${UI_NODEPORT}
  ingress:
    host: localhost


EOF

}

http_post() {
  # store the whole response with the status as last line
  if [ -z "$2" ]; then
    HTTP_RESPONSE=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" -X POST -H "Content-Type: application/json" $1)
  else
    HTTP_RESPONSE=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" -X POST -H "Content-Type: application/json" $1 -d $2)
  fi

  HTTP_BODY=$(echo $HTTP_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g')
  HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

  unset HTTP_RESPONSE
}

check_for_existing_services() {
  if is_dynamic_lb_enabled ; then
    return 0
  fi

  service_name="default-kong"
  kubectl get services --all-namespaces | grep $service_name > kong_service
  if [ `cat kong_service | wc -l` -ne 0 ]; then
    exit_with_error "'$service_name' service already exists, aborting."
  fi
}

wait_for_database() {
  echo "Waiting for database..."
  secs=30
  for i in `seq 1 20`; do
    echo "Attempting database connection. (attempt $i)"
    ${script_folder}/psql.sh -c '\l'
    if [ $? -eq 0 ]; then
      echo "Database is available."
      return 0
    fi

    echo "Database not available, trying again in $secs seconds. (attempt $i)"
    sleep $secs
  done

  exit_with_error "Database did not become availble, aborting."
}

init_database() {

  echo "Parsing CLI config for database names..."
  echo "$GESTALT_CLI_DATA" | base64 -d > /gestalt/gestalt.json.tmp
  envsubst < /gestalt/gestalt.json.tmp | jq . > /gestalt/gestalt.json.tmp2


  local kongdb=$(cat /gestalt/gestalt.json.tmp2 | jq -r '.kong.dbName')
  local laserdb=$(cat /gestalt/gestalt.json.tmp2 | jq -r '.laser.dbName')
  local gatewaydb=$(cat /gestalt/gestalt.json.tmp2 | jq -r '.gateway.dbName')

  echo "Dropping existing databases..."

  for db in gestalt-meta $kongdb $laserdb $gatewaydb $SECURITY_DB_NAME ; do
    ${script_folder}/drop_database.sh $db --yes
    exit_on_error "Failed to initialize database, aborting."
  done

  echo "Attempting to initalize database..."
  ${script_folder}/create_initial_databases.sh
  exit_on_error "Failed to initialize database, aborting."
  echo "Database initialized."
}

invoke_security_init() {
  echo "Initializing Security..."
  secs=20
  for i in `seq 1 20`; do
    do_invoke_security_init
    if [ $? -eq 0 ]; then
      return 0
    fi

    echo "Trying again in $secs seconds. (attempt $i)"
    sleep $secs
  done

  exit_with_error "Failed to initialize Security, aborting."
}

do_invoke_security_init() {
  echo "Invoking $SECURITY_URL/init..."

  # sets HTTP_STATUS and HTTP_BODY
  http_post $SECURITY_URL/init "{\"username\":\"$ADMIN_USERNAME\",\"password\":\"$ADMIN_PASSWORD\"}"

  if [ ! "$HTTP_STATUS" -eq "200" ]; then
    echo "Error invoking $SECURITY_URL/init ($HTTP_STATUS returned)"
    return 1
  fi

  echo "$HTTP_BODY" > init_payload

  do_get_security_credentials

  echo "Security initialization invoked, API key and secret obtained."
}

do_get_security_credentials() {

  export SECURITY_KEY=`cat init_payload | jq '.[] .apiKey' | sed -e 's/^"//' -e 's/"$//'`
  exit_on_error "Failed to obtain or parse API key (error code $?), aborting."

  export SECURITY_SECRET=`cat init_payload | jq '.[] .apiSecret' | sed -e 's/^"//' -e 's/"$//'`
  exit_on_error "Failed to obtain or parse API secret (error code $?), aborting."

}

wait_for_security_init() {
  echo "Waiting for Security to initialize..."
  secs=20

  for i in `seq 1 20`; do
    if [ "`curl $SECURITY_URL/init | jq '.initialized'`" == "true" ]; then
      echo "Security initialized."
      return 0
    fi
    echo "Not yet, trying again in $secs seconds. (attempt $i)"
    sleep $secs
  done

  exit_with_error "Security did not initialize, aborting."
}

init_meta() {
  echo "Initializing Meta..."

  if [ -z "$SECURITY_KEY" ]; then
    echo "Parsing security credentials."
    do_get_security_credentials
  fi

  secs=20
  for i in `seq 1 20`; do
    do_init_meta
    if [ $? -eq 0 ]; then
      return 0
    fi

    echo "Trying again in $secs seconds. (attempt $i)"
    sleep $secs
  done

  exit_with_error "Failed to initialize Meta."
}

do_init_meta() {

  echo "Polling $META_URL/root..."
  # Check if meta initialized (ready to bootstrap when /root returns 500)
  HTTP_STATUS=$(curl -s -o /dev/null -u $SECURITY_KEY:$SECURITY_SECRET -w '%{http_code}' $META_URL/root)
  if [ "$HTTP_STATUS" == "500" ]; then

    echo "Bootstrapping Meta at $META_URL/bootstrap..."
    HTTP_STATUS=$(curl -X POST -s -o /dev/null -u $SECURITY_KEY:$SECURITY_SECRET -w '%{http_code}' $META_URL/bootstrap?$META_BOOTSTRAP_PARAMS)

    if [ "$HTTP_STATUS" -ge "200" ] && [ "$HTTP_STATUS" -lt "300" ]; then
      echo "Meta bootstrapped (returned $HTTP_STATUS)."
    else
      exit_with_error "Error bootstrapping Meta, aborting."
    fi

    echo "Syncing Meta at $META_URL/sync..."
    HTTP_STATUS=$(curl -X POST -s -o /dev/null -u $SECURITY_KEY:$SECURITY_SECRET -w '%{http_code}' $META_URL/sync)

    if [ "$HTTP_STATUS" -ge "200" ] && [ "$HTTP_STATUS" -lt "300" ]; then
      echo "Meta synced (returned $HTTP_STATUS)."
    else
      exit_with_error "Error syncing Meta, aborting."
    fi
  else
    echo "Meta not yet ready."
    return 1
  fi
}

do_get_loadbalancer_hostname() {

  [ -z $KONG_INGRESS_SERVICE_NAME ] && KONG_INGRESS_SERVICE_NAME=kng

  local service_name=$KONG_INGRESS_SERVICE_NAME

  kubectl get services --all-namespaces | grep $service_name > kong_service
  if [ `cat kong_service | wc -l` -ne 1 ]; then
    exit_with_error "Did not find a unique '$service_name' service"
  fi
  local service_namespace=`cat kong_service | awk '{print $1}'`


  secs=10
  for i in `seq 1 20`; do
    echo "Polling for load balancer (attempt $i)"
    lb=`kubectl get service $service_name -n $service_namespace -ojson | jq -r '.status.loadBalancer.ingress[0].hostname'`
    if [ -z "$lb" ] || [ "$lb" == "null" ]; then
      echo "Got \"$lb\", trying again in $secs seconds. (attempt $i)"
      sleep $secs
    else
      echo "LB hostname = $lb"
      LB_HOSTNAME=$lb
      return 0
    fi
  done
  exit_with_error "Could not get '$service_name' load balancer hostname"
}

is_dynamic_lb_enabled() {
  # Check for 'yes' or 'true'
  case $USE_DYNAMIC_LOADBALANCERS in
    [Yy]*) return 0  ;;
    [Tt]*) return 0  ;;
  esac

  return 1
}

gestalt_cli_set_opts() {
  if [ "${FOGCLI_DEBUG}" == "true" ]; then
    fog config set debug=true
  fi
}

gestalt_cli_login() {

  cmd="fog login $UI_URL -u $ADMIN_USERNAME -p $ADMIN_PASSWORD"
  echo "Running $cmd"
  $cmd
  exit_on_error "Failed to login to Gestalt, aborting."

}

gestalt_cli_license_set() {
  check_for_required_files ${gestalt_license}
  fog admin update-license -f ${gestalt_license}
  exit_on_error "Failed to upload license '${gestalt_license}' (error code $?), aborting."
}

gestalt_cli_context_set() {

  fog context set --path /root
  exit_on_error "Failed to set fog context '/root' (error code $?), aborting."

}

gestalt_cli_create_resources() {
  cd /resource_templates

  # Always assume there's a script called run.sh
  if [ -f ./run.sh ]; then 
    # Source run.sh so that it has access to higher-level functions
    . run.sh
    exit_on_error "Gestalt resource setup did not succeed (error code $?), aborting."
  else
    echo "Warning - Not running resource templates script, /resource_templates/run.sh not found"
  fi
  cd -
  echo "Gestalt resource(s) created."
}


create_kong_ingress_v2() {
  if [ -z $KONG_INGRESS_SERVICE_NAME ]; then
    echo "Skipping Kong Ingress setup since KONG_INGRESS_SERVICE_NAME not provided"
    return 0
    # KONG_INGRESS_SERVICE_NAME=kng
    # echo "KONG_INGRESS_SERVICE_NAME not defined, defaulting to $KONG_INGRESS_SERVICE_NAME"
  fi

  echo "Creating Kubernetes Ingress resource for $KONG_INGRESS_SERVICE_NAME..."

  local service_name=$KONG_INGRESS_SERVICE_NAME

  kubectl get services --all-namespaces | grep $service_name > kong_service
  if [ `cat kong_service | wc -l` -ne 1 ]; then
    exit_with_error "Did not find a unique '$service_name' service"
  fi
  local service_namespace=`cat kong_service | awk '{print $1}'`

  # Note - if EXTERNAL_GATEWAY_HOST isn't specified, providing an empty host will result
  # in '*' for the host for the ingress - which means any host would apply
  local host=$EXTERNAL_GATEWAY_HOST

  kubectl apply -f - <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: $service_name
  namespace: $service_namespace
spec:
  rules:
  - host: $host
    http:
      paths:
      - path: /
        backend:
          serviceName: $service_name
          servicePort: 8000
EOF
  exit_on_error "Could not create ingress to '$service_namespace/$service_name' for ''$host' (kubectl error code $?), aborting."

  echo "Kong ingress to '$service_namespace/$service_name' configured for '$host'."
}
