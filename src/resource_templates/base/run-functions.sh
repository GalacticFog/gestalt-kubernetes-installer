create() {

  # `fog` reads configuration from environment variables

  local file=$1.yaml
  echo "Creating resource from '$file'..."
  fog create resource -f $file
  if [ $? -ne 0 ]; then
    echo
    echo "Error: Error processing '$file', aborting."
    exit 1
  fi
}

error() {
  >&2 echo "[Error] $@"
}

exit_with_error() {
  error "$@"
  exit 1
}

exit_on_error() {
  [ $? -eq 0 ] || exit_with_error "$@"
}

warn_on_error() {
  [ $? -eq 0 ] && >&2 echo "[Warning] $@"
}

apply_image_pull_secrets() {
  kubectl get secret -n gestalt-system imagepullsecret-1 -oyaml > /tmp/secret-imagepullsecret-1.yaml
  exit_on_error "Unable obtain secret 'kubectl get secret -n gestalt-system imagepullsecret-1 -oyaml' , aborting."
  # Strip out and rename
  cat /tmp/secret-imagepullsecret-1.yaml | grep -v 'creationTimestamp:' | grep -v 'namespace:' | grep -v 'resourceVersion:' | grep -v 'selfLink:' | grep -v 'uid:' > /tmp/secret-clean-imagepullsecret-1.yaml
  exit_on_error "Unable manipulate source secret 'gestalt-system:imagepullsecret-1' , aborting."
  all_namespaces=$(kubectl get namespace -l "meta/fqon" --no-headers | awk '{print $1}')
  echo "Namespaces to process: ${all_namespaces[@]}"
  for curr_namespace in ${all_namespaces[@]}; do
    kubectl apply -f /tmp/secret-clean-imagepullsecret-1.yaml -n ${curr_namespace}
    exit_on_error "Unable create target secret '${curr_namespace}:imagepullsecret-1' , aborting."
    echo "OK - Secret Copied to '${curr_namespace}:imagepullsecret-1'"
  done
}

get_laser_host() {
  local namespace=$(kubectl get svc --all-namespaces | grep lsr | awk '{print $1}')
  [ -z "$namespace" ] && exit_with_error "Could not find laser's namespace, aborting"
  echo "http://lsr.${namespace}.svc.cluster.local:9000"
}

get_lambda_invoke_url() {
  local laser_host=$(get_laser_host)
  local lambda_id=$(fog show lambdas /root/gestalt-system-workspace/gestalt-system-environment --name container-import --fields name,id | grep container-import | awk '{print $2}')
  if [ -z "$lambda_id" ]; then
    exit_with_error "Could not find ID for container-import, aborting"
  fi
  echo "${laser_host}/lambdas/${lambda_id}/invokeSync"
}

get_caas_provider_id() {
  # Retrieve CaaS provider ID and set $caas_provider_id needed for later functions
  caas_provider_id=$(fog show providers / --name default-kubernetes -o json | jq -r '.[].id')
  exit_on_error "Failed to get 'default-kubernetes' provider ID, aborting"
  if [ "$caas_provider_id" == "null" ]; then
    exit_with_error "caas_provider_id is null, aborting"
  fi
}

patch_caas_provider_with_container_import_action() {
  [ -z "$caas_provider_id" ] && get_caas_provider_id

  local lambda_url=$(get_lambda_invoke_url)
  exit_on_error "Failed to get lambda_url, aborting"

  cat > /tmp/patch.json <<EOF
  [{
    "op": "replace",
    "path": "/properties/config/endpoints",
    "value": [{
        "kind": "",
        "url": "${lambda_url}",
        "actions": [
            {"name": "container.import", "post": {"responses": [{"code": 200}]}},
            {"name": "secret.import", "post": {"responses": [{"code": 200}]}},
            {"name": "volume.import", "post": {"responses": [{"code": 200}]}}
        ]
    }]
}]
EOF

  echo "Patching CaaS provider with container-import info"
  fog meta PATCH -f /tmp/patch.json /root/providers/${caas_provider_id}
  exit_on_error "Failed to patch CaaS provider with container-import info, aborting"
}

import_gestalt_system_k8s_resources() {

  # First, import dependencies
  import_secret gestalt-system gestalt-secrets
  import_volume gestalt-system gestalt-postgresql

  # Next, import containers
  for c in `kubectl get deploy -n gestalt-system --no-headers | awk '{print $1}'`; do 
    import_container "gestalt-system" $c
  done
}

import_container() {
  local namespace=$1
  local name=$2

  if [ -z "$gestalt_system_env_id" ]; then
    gestalt_system_env_id=$(fog show environments /root/gestalt-system-workspace --fields=name,id | grep gestalt-system-environment | awk '{print $2}')
    exit_on_error "Failed to get gestalt-system-environment ID, aborting"
  fi

  local file=/tmp/${name}-container.json

  cat > $file <<EOF
{
    "name":"${name}",
    "description":"Deployment ${name} imported from namespace '${namespace}' on `date`",
    "properties":{
        "image": "n/a",
        "container_type": "DOCKER",
        "provider":{"id":"${caas_provider_id}","locations":[]},
        "external_id": "/namespaces/${namespace}/deployments/${name}"
    }
}
EOF

  echo "Importing container $name..."
  fog meta POST /root/environments/${gestalt_system_env_id}/containers?action=import -f $file
  warn_on_error "Failed to import '${name}' container, aborting"
}

import_volume() {
  local namespace=$1
  local name=$2

  if [ -z "$gestalt_system_env_id" ]; then
    gestalt_system_env_id=$(fog show environments /root/gestalt-system-workspace --fields=name,id | grep gestalt-system-environment | awk '{print $2}')
    exit_on_error "Failed to get gestalt-system-environment ID, aborting"
  fi

  local file=/tmp/${name}-volume.json

  cat > $file <<EOF
{
    "name":"${name}",
    "description":"Voume ${name} imported from namespace '${namespace}' on `date`",
    "properties":{
        "provider":{"id":"${caas_provider_id}","locations":[]},
        "external_id": "/namespaces/${namespace}/persistentvolumeclaims/${name}",
        "size": 0,
        "config": "{}",
        "access_mode": "n/a",
        "type": "persistent"
    }
}
EOF

  echo "Importing volume $name..."
  fog meta POST /root/environments/${gestalt_system_env_id}/volumes?action=import -f $file
  warn_on_error "Failed to import volume '${name}', aborting"
}

import_secret() {
  local namespace=$1
  local name=$2

  if [ -z "$gestalt_system_env_id" ]; then
    gestalt_system_env_id=$(fog show environments /root/gestalt-system-workspace --fields=name,id | grep gestalt-system-environment | awk '{print $2}')
    exit_on_error "Failed to get gestalt-system-environment ID, aborting"
  fi

  [ -z "$caas_provider_id" ] && get_caas_provider_id

  local file=/tmp/${name}-secret.json

  cat > $file <<EOF
{
    "name":"${name}",
    "description":"Secret ${name} imported from namespace '${namespace}' on `date`",
    "properties":{
        "provider":{"id":"${caas_provider_id}","locations":[]},
        "external_id": "/namespaces/${namespace}/secrets/${name}"
    }
}
EOF

  echo "Importing secret $name..."
  fog meta POST /root/environments/${gestalt_system_env_id}/secrets?action=import -f $file
  warn_on_error "Failed to import secret '${name}', aborting"
}