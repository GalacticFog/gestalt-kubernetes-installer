#!/bin/bash

############################################
# Utilities: Index
############################################

# exit_with_error - Prints passed message with [Error] prefix and exits with error code 1
# exit_on_error - If current status is non-0, prints passed message with [Error] prefix and exits with error code 1



############################################
# Utilities: START
############################################


exit_with_error() {
  echo "[Error] $@"
  exit 1
}

exit_on_error() {
  if [ $? -ne 0 ]; then
    echo "[Error] $1"
    exit 1
  fi
}

check_for_required_variables() {
  retval=0

  for e in $@; do
    if [ -z "${!e}" ]; then
      echo "[Error] Required variable \"$e\" not defined."
      retval=1
    fi
  done

  if [ $retval -ne 0 ]; then
    echo
    echo "[Error] One or more required variables not defined, aborting."
    exit 1
  else
    echo "All required variables found."
  fi
}


check_if_installed() {
    for curr_tool in "$@"; do
        if ! which $curr_tool &> /dev/null; then
            exit_with_error "Unable locate $curr_tool"
        fi
    done
}

check_for_required_tools() {

  check_if_installed "base64"

}

xx_check_for_required_tools() {
  # echo "Checking for required tools..."
  which base64    >/dev/null 2>&1 ; exit_on_error "'base64' command not found, aborting."
  which tr        >/dev/null 2>&1 ; exit_on_error "'tr' command not found, aborting."
  which sed       >/dev/null 2>&1 ; exit_on_error "'sed' command not found, aborting."
  which seq       >/dev/null 2>&1 ; exit_on_error "'seq' command not found, aborting."
  which sudo      >/dev/null 2>&1 ; exit_on_error "'sudo' command not found, aborting."
  which true      >/dev/null 2>&1 ; exit_on_error "'true' command not found, aborting."
  # 'read' may be implemented as a shell function rather than a separate function
  # which read      >/dev/null 2>&1 ; exit_on_error "'read' command not found, aborting."
  which bc        >/dev/null 2>&1 ; exit_on_error "'bc' command not found, aborting."
  # which helm      >/dev/null 2>&1 ; exit_on_error "'helm' not found, aborting."
  which kubectl   >/dev/null 2>&1 ; exit_on_error "'kubectl' command not found, aborting."
  which curl      >/dev/null 2>&1 ; exit_on_error "'curl' command not found, aborting."
  which unzip     >/dev/null 2>&1 ; exit_on_error "'unzip' command not found, aborting."
  which tar       >/dev/null 2>&1 ; exit_on_error "'tar' command not found, aborting."
  echo "OK - Required tools found."
}


############################################
# Utilities: END
############################################



## Don't output the first comma, but output after that.
## Used for building an array "[`comma`a `comma`b `comma`c ]" --> "[ a, b, c ]", e.g. if there's only one element,
## don't print out a comma.
comma_flag=
function comma() {
  echo $comma_flag
  comma_flag=","
}

process_kubeconfig() {
  # echo "Processing kubectl configuration (provided to the installer)..."

  os=`uname`

  if [ -z "$kubeconfig_data" ]; then
    echo "Obtaining kubeconfig from kubectl context '`kubectl config current-context`'"
    data=$(kubectl config view --raw --flatten=true --minify=true)
    kubeurl='https://kubernetes.default.svc'
    echo "Converting server URL to '$kubeurl'"

    # for 'http'
    data=$(echo "$data" | sed "s;server: http://.*;server: $kubeurl;g")

    # for 'https'
    data=$(echo "$data" | sed "s;server: https://.*;server: $kubeurl;g")

    exit_on_error "Could not process kube config, aborting."

    if [ "$os" == "Darwin" ]; then
      kubeconfig_data=`echo "$data" | base64`
    elif [ "$os" == "Linux" ]; then
      kubeconfig_data=`echo "$data" | base64 | tr -d '\n'`
    else
      echo "Warning: unknown OS type '$os', treating as Linux"
      kubeconfig_data=`echo "$data" | base64 | tr -d '\n'`
    fi
  fi
}
