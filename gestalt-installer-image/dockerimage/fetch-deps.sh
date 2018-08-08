#!/bin/bash

exit_on_error() {
  [ $? -ne 0 ] && echo $1 && exit 1
}

get_kubectl() {
  kube_version=`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`
  kube_url=https://storage.googleapis.com/kubernetes-release/release/${kube_version}/bin/linux/amd64/kubectl

  # Get Kubectl
  if [ ! -f ./deps/kubectl ]; then
    echo "Getting kubectl from $kube_url..."
    curl -L $kube_url -o ./deps/kubectl
    exit_on_error "Failed to get kubectl, aborting."
  else
    echo "OK - kubectl already present, skipping"
  fi
}

get_and_build_gestalt_cli() {
  if [ ! -f ./deps/gestalt-cli.jar ]; then

    if [ ! -d ./deps/gestalt-cli ]; then
      cd deps
      git clone git@gitlab.com:galacticfog/gestalt-cli.git
      cd -
    else
      echo "OK - gestalt-cli already present, skipping"
    fi

    cli_path=./deps/gestalt-cli/target/scala-2.11/gestalt-cli.jar

    echo "Building gestalt-cli project"
    cd deps/gestalt-cli

    # git checkout udpate_license

    sbt clean update compile assembly
    exit_on_error "Failed to build gestalt-cli, aborting."
    cd -

    echo "Copying $cli_path to ./deps"
    cp $cli_path ./deps/
    exit_on_error "Failed to copy $cli_path, aborting."

    echo "Cleaning up gestalt-cli source"
    rm -rf ./deps/gestalt-cli
  else
    echo "OK - gestalt-cli.jar already present, skipping"
  fi
}

echo "Gathering dependencies..."

mkdir -p ./deps

get_and_build_gestalt_cli

get_kubectl

echo "Finished gathering dependencies to ./deps/"
