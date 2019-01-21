create_gke_healthchecks() {
  local healthcheck_environment=gestalt-health-environment
  sleep 10
  fog create environment $healthcheck_environment --org 'root' --workspace 'gestalt-system-workspace' --description "Gestalt HealthCheck Environment" --type 'production'
  [ $? -eq 0 ] || exit_with_error "Error creating environment '${healthcheck_environment}', aborting"
  sleep 10
  local gestalt_healthcheck_context="/root/gestalt-system-workspace/$healthcheck_environment"
  exit_if_fail retry_fails fog context set $gestalt_healthcheck_context
  echo "----- Creating the Kong healthcheck lambda -----"
  exit_if_fail retry_fails fog create resource -f healthcheck-lambda.json
  sleep 10
  echo "----- Creating the Kong healthcheck API -----"
  exit_if_fail retry_fails fog create api --name health --description healthcheck-api --provider default-kong
  sleep 10
  echo "----- Creating the Kong healthcheck API endpoint -----"
  exit_if_fail retry_fails fog create api-endpoint -f healthcheck-apiendpoint.json --api health --lambda health-lambda
  echo "----- Done creating healthchecks -----"
}

retry_fails() {
  local tries=5
  local retry_delay=20
  local cmd=$*
  local try=0
  local cmd_output
  local exit_code
  echo "Attempting $tries tries of command '$cmd'"
  for try in `seq $tries`; do
    echo "attempt $try of '$cmd'"
    cmd_output=$($cmd)
    exit_code=$?
    echo $cmd_output
    if [ $exit_code -eq 0 ]; then
      echo "SUCCESS attempt $try of '$cmd'"
      return $exit_code
    fi
    echo "FAIL attempt $try of '$cmd' exit code $exit_code"
    echo "retrying in $retry_delay seconds"
    sleep $retry_delay
  done
  echo "FAILED!!! $tries attempts of command '$cmd'"
  return $exit_code
}

exit_if_fail() {
  $*
  [ $? -eq 0 ] || (echo "FATAL ERROR - exiting" && exit 1)
}
