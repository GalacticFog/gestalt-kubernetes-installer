#!/bin/bash

exit_on_error() {
  if [ $? -ne 0 ]; then
    echo $1
    exit 1
  fi
}

exit_with_error() {
  echo "[Error] $1"
  exit 1
}


log_debug () {
  [ "${logging_lvl}" == "debug" ] && echo && echo "[Debug] $@"
}

log_info () {
  [[ "${logging_lvl}" =~ (debug|info) ]] && echo && echo "[Info] $@"
}

log_error () {
  [[ "${logging_lvl}" =~ (debug|info|error) ]] && echo && echo "[Error] $@"
}

check_for_required_files () {
echo "aaa"
}

default_gestalt_variables () {
  echo "bbb"
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

check_for_required_variables() {
  retval=0

  for e in $@; do
    if [ -z "${!e}" ]; then
      echo "Required variable \"$e\" not defined."
      retval=1
    fi
  done

  if [ $retval -ne 0 ]; then
    echo "One or more required variables not defined, aborting."
    exit 1
  else
    echo "All required variables found."
  fi
}

check_for_optional_variables() {
  for e in $@; do
    if [ -z "${!e}" ]; then
      echo "Optional variable \"$e\" not defined."
    fi
  done
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
    chmod +x ${scripts_folder}/psql.sh
    ${scripts_folder}/psql.sh -c '\l'
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
    chmod +x ${scripts_folder}/drop_database.sh
    ${scripts_folder}/drop_database.sh $db --yes
    exit_on_error "Failed to initialize database, aborting."
  done

  echo "Attempting to initalize database..."
    chmod +x ${scripts_folder}/create_initial_databases.sh
    ${scripts_folder}/create_initial_databases.sh
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

  echo "[LALALAA 3333 AAAA]"
  #[{"apiKey":"6dd2d579-72d6-45f6-ac2a-a3ed585eefa8","apiSecret":"IEcKank5f7ReWegke2XHxAjuPcnpgW6DXrp0LuKY","accountId":"2a4248ea-01f5-41c6-a613-6ba95d0acdbf","disabled":false}]
  cat init_payload
  echo "[LALALAA 3333 BBBbB]"
  SECURITY_KEY=`cat init_payload | jq '.[] .apiKey' | sed -e 's/^"//' -e 's/"$//'`
  exit_on_error "Failed to obtain or parse API key (error code $?), aborting."

  SECURITY_SECRET=`cat init_payload | jq '.[] .apiSecret' | sed -e 's/^"//' -e 's/"$//'`
  exit_on_error "Failed to obtain or parse API secret (error code $?), aborting."

  echo "[SECURITY_KEY=${SECURITY_KEY}]"
  echo "[SECURITY_SECRET=${SECURITY_SECRET}]"

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

create_providers() {
  echo "Creating default providers..."

  # Getting security keys again, just in case this function is run standalone
  do_get_security_credentials

  # note the hostname for the ELB (sets LB_HOSTNAME)
  if is_dynamic_lb_enabled ; then
    echo "Configuring for dynamic loadbalancing - polling for load balancer hostname"
    do_get_loadbalancer_hostname
    [ -z $EXTERNAL_GATEWAY_PROTOCOL ] && EXTERNAL_GATEWAY_PROTOCOL=http  # default if not specified
    EXTERNAL_GATEWAY_HOST=$LB_HOSTNAME
  else
    check_for_required_variables \
      EXTERNAL_GATEWAY_HOST \
      EXTERNAL_GATEWAY_PROTOCOL
  fi

  if [ "$DEBUG_OUTPUT" == "1" ]; then
    debug_flag="--debug"
  fi



echo "sdsdgdsgsd"
cat /resource_templates/config.json

echo "jjjjjjjjjj"

env | sort

echo "ssdfsdfsdfs"

export SECURITY_KEY=${SECURITY_KEY}
  export SECURITY_SECRET=${SECURITY_SECRET}

env | sort

echo "22222222ssdfsdfsdfs"

   echo "[xxxSECURITY_KEY=${SECURITY_KEY}]"
  echo "[xxxSECURITY_SECRET=${SECURITY_SECRET}]"

  # Generate config
  envsubst < /resource_templates/config.json > /resource_templates/config.json.tmp
  mv /resource_templates/config.json.tmp /resource_templates/config.json

  cat /resource_templates/config.json
  
  echo "222222"
  




  cmd="fog login $UI_URL -u $ADMIN_USERNAME -p $ADMIN_PASSWORD"
  echo "Running $cmd"
  $cmd

  exit_on_error "Failed to login to Gestalt, aborting."

  cd /resource_templates

  ./create_providers.sh

  exit_on_error "Provider setup did not succeed (error code $?), aborting."

  cd -

  echo "Default providers created."
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
