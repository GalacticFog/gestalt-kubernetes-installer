#!/bin/bash
. ./conf/gestalt-platform-installer.conf

exit_on_error() {
  [ $? -ne 0 ] && echo $1 && exit 1
}

exit_with_error() {
  echo "[Error] $@"
  exit 1
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

get_fog_cli() {
  if [ -z fog_download_url ]; then
    exit_with_error "Fog download URL (fog_download_url) is not set, aborting".
  fi

  if [ ! -f ./deps/fog ]; then
    echo "Getting fog from $fog_download_url..."
    curl -L $fog_download_url -o ./deps/fog.zip
    cd deps
    unzip fog.zip
    rm fog.zip
    cd -
  else
    echo "OK - 'fog' already present, skipping"
  fi
}

# TODO: get_helm()

echo "Gathering dependencies..."

mkdir -p ./deps

# get_and_build_gestalt_cli

get_kubectl

get_fog_cli

# TODO: get_helm

echo "Finished gathering dependencies to ./deps/"
