#!/bin/bash

set -e
set -o pipefail

function sleep_forever() {
    while [ 1 ]; do
        sleep 60
    done
}

function handle_error() {
    echo "[INSTALLATION_FAILURE] line=$1 code=$2 script=$0"
}

CMD=${1:-install}

trap 'handle_error ${LINENO} $?' ERR

if [ "$CMD" == 'install' ]; then
    echo "Installing Gestalt platform... ('install' container argument specified)"

    cd /app

    SECONDS=0
    log=/app/install.log

    # Get a config map from the current namespace and write contents to local file
    if [ -z ${MARKETPLACE_INSTALL+x} ]; then
      # NOT a Marketplace install
      kubectl get configmap install-data -ojsonpath='{.data.b64data}' | base64 -d > ./install-data.tar.gz

      # If an install-data package was placed, overwrite the install directories on this image with them
      if [ -f ./install-data.tar.gz ]; then
          # Untar in place
          mkdir -p ./install
          tar xfzv ./install-data.tar.gz -C ./install
      fi

    else
      echo "--------- MARKETPLACE INSTALL ----------"
      # Marketplace install - copy config files over
      mkdir -p /app/install/config
      [ -z ${K8S_PROVIDER+x} ] || echo "K8S_PROVIDER = ${K8S_PROVIDER}"
      ls -alF 
      if [ -d "/app/install/providers/${K8S_PROVIDER}" ]; then
        FIND_CMD="find /app/install/providers/${K8S_PROVIDER} -type f"
        echo $FIND_CMD
        $FIND_CMD
        echo "Copying /app/install/providers/${K8S_PROVIDER} to /app/install/"
        cp -r /app/install/providers/${K8S_PROVIDER}/* /app/install/
        FIND_CMD="find /app/install -type f"
        echo $FIND_CMD
        $FIND_CMD
        echo "DONE Copying /app/install/providers/${K8S_PROVIDER} to /app/install/"
        VIEW_FILE="/app/install/resource_templates/base/logging-provider.yaml"
        if [ -f ${VIEW_FILE} ]; then
          echo "---------- CONTENTS OF ${VIEW_FILE} ----------"
          cat ${VIEW_FILE}
          echo "---------- END OF ${VIEW_FILE} ----------"
        else
          echo "---------- FILE NOT FOUND ${VIEW_FILE} ----------"
          ls -alhF /app/install/resource_templates/base
        fi
      else
        echo "No directory found /app/install/providers/${K8S_PROVIDER}"
      fi
    fi

    # TODO: Test the file size, or check if the configmap didn't exist

    echo "Initiating Gestalt platform installation at `date`" | tee -a $log

    cd /app/install/scripts
    ./install.sh $2 2>&1 | tee -a $log

    if [ $? -eq 0 ]; then
        echo "[INSTALLATION_SUCCESS]"
    else
        echo "[INSTALLATION_FAILURE]"
    fi

    echo "Total elapsed time: $SECONDS seconds." | tee -a $log

    if [ "$2" == "debug" ]; then 
        echo "Debug was enabled, sleeping forever so container stays running..."
        sleep_forever
    fi
elif [ "$1" == 'sleep' ]; then
    echo "Sleep command asserted, sleeping forever so container stays running..."
    sleep_forever 
else
  echo "Skipping Gestalt installation ('install' container argument not specified)."
fi
