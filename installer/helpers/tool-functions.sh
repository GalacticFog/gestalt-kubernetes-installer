# This file is sourced into various command-line tool scripts

log_debug() {
  [[ $DEBUG -ne 0 ]] && echo "$@"
}

exit_with_error() {
  echo "[Error] $@" 1>&2
  exit 1
}

exit_on_error() {
  [ $? -eq 0 ] || exit_with_error $@
}

warn_on_error() {
  [ $? -eq 0 ] || echo "[Warning] $@"
}

debug() {
  [ ${DEBUG:-0} -eq 0 ] || echo "[Debug] $@"
}

find_release() {
  # TODO Handle multiple releases
  kubectl get --all-namespaces svc -l "app.kubernetes.io/app=gestalt" -o jsonpath='{.items[*].metadata.labels.app\.kubernetes\.io/name}' | tr ' ' '\n' | uniq
}

find_namespace() {
  local DEFAULT_NAMESPACE=${1:-"gestalt-system"}

  # TODO Handle multiple namespaces
  local NS=$( kubectl get ns $DEFAULT_NAMESPACE -o jsonpath="{.metadata.name}" )
  [ -z "$NS" ] && NS=$( kubectl get --all-namespaces ns -l "app.kubernetes.io/app=gestalt" -o jsonpath="{.items[*].metadata.name}" | tr ' ' '\n' | uniq )
  [ -z "$NS" ] && exit_with_error "Unable to find a Gestalt release namespace (or one named '${DEFAULT_NAMESPACE}')"
  echo "$NS"
}

check_for_kubectl() {
  which kubectl   >/dev/null 2>&1 ; exit_on_error "'kubectl' command not found, aborting."
}

check_for_kube() {
  echo "Checking for Kubernetes..."
  local kubecontext="`kubectl config current-context`"

  if [ ! -z "$target_kube_context" ]; then
      if [ "$kubecontext" != "$target_kube_context" ]; then
      do_prompt_to_continue \
        "Warning - The current Kubernetes context name '$kubecontext' does not match the expected value, '$target_kube_context'" \
        "Proceed anyway?"
      fi
  fi

  kube_cluster_info=$(kubectl cluster-info)
  exit_on_error "Kubernetes cluster not accessible, aborting."

  echo "OK - Kubernetes cluster '$kubecontext' is accessible."
}

check_release_name_and_namespace() {
  if [ -z "$RELEASE_NAME" ]; then
    echo "Application RELEASE_NAME is not defined - using default value 'gestalt'"
    RELEASE_NAME='gestalt'
  fi
  debug "Gestalt RELEASE_NAME '${RELEASE_NAME}'"
  
  DEFAULT_NS="${RELEASE_NAME}-system"
  if [ -z "$RELEASE_NAMESPACE" ]; then
    echo "Kubernetes RELEASE_NAMESPACE is not defined - using default value '${DEFAULT_NS}'"
    RELEASE_NAMESPACE='${DEFAULT_NS}'
  fi
  debug "Gestalt RELEASE_NAMESPACE '${RELEASE_NAMESPACE}'"
}

check_for_required_namespace() {
  # echo "Checking for existing Kubernetes namespace '$RELEASE_NAMESPACE'..."
  kubectl get namespace $RELEASE_NAMESPACE > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo ""
    echo "Kubernetes namespace '$RELEASE_NAMESPACE' doesn't exist, aborting.  To create the namespace, run the following command:"
    echo ""
    echo "  kubectl create namespace $RELEASE_NAMESPACE"
    echo ""
    echo "Then ensure that 'Full Control' grants are provided for the '$RELEASE_NAMESPACE/default' service account."
    echo ""
    exit_with_error "Kubernetes namespace '$RELEASE_NAMESPACE' doesn't exist, aborting."
  fi
  echo "OK - Kubernetes namespace '$RELEASE_NAMESPACE' is present."
}

fog_cli_login() {

  ./fog login ${gestalt_url} -u $gestalt_admin_username -p $gestalt_admin_password
  if [ $? -ne 0 ]; then
    echo ""
    echo "  Warning: Failed to log in to '$gestalt_url' using user '$gestalt_admin_username'."
    echo "  If Gestalt is behind a load balancer that requires DNS, the Gestalt service may not yet be live.  To attempt to log in manually, run the following:"
    echo ""
    echo "    ./fog login $gestalt_url"
    echo ""
  fi
}

get_secrets() {
  local SECRETS_NAME
  SECRETS_NAME=$( kubectl -n ${RELEASE_NAMESPACE} get secret -l "app.kubernetes.io/app=gestalt" -o jsonpath="{.items[*].metadata.name}" )
  exit_on_error "kubectl error while looking for secrets!"
  [ -z "$SECRETS_NAME" ] && exit_with_error "Unable to find Gestalt secrets in namespace '${RELEASE_NAMESPACE}'"
  echo "Found Gestalt secrets named '$SECRETS_NAME'"
 
  gestalt_url=$( kubectl get secrets -n $RELEASE_NAMESPACE $SECRETS_NAME -ojsonpath='{.data.gestalt-url}' | base64 --decode )
  gestalt_admin_username=$( kubectl get secrets -n $RELEASE_NAMESPACE $SECRETS_NAME -ojsonpath='{.data.admin-username}' | base64 --decode )
  gestalt_admin_password=$( kubectl get secrets -n $RELEASE_NAMESPACE $SECRETS_NAME -ojsonpath='{.data.admin-password}' | base64 --decode )
  gestalt_db_name=$( kubectl get secrets -n $RELEASE_NAMESPACE $SECRETS_NAME -ojsonpath='{.data.db-database}' | base64 --decode )
  gestalt_db_username=$( kubectl get secrets -n $RELEASE_NAMESPACE $SECRETS_NAME -ojsonpath='{.data.db-username}' | base64 --decode )
  gestalt_db_password=$( kubectl get secrets -n $RELEASE_NAMESPACE $SECRETS_NAME -ojsonpath='{.data.db-password}' | base64 --decode )
}
