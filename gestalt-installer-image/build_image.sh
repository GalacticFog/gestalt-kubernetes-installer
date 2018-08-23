#!/bin/bash

exit_on_error() {
  if [ $? -ne 0 ]; then
    echo $1
    exit 1
  fi
}

if [ -z "$1" ]; then
  echo "Usage: ./build_and_publish.sh <docker label>"
  exit 1
fi

# Check for dependencies
[ -f ./deps/kubectl ]
exit_on_error "./deps/kubectl not found, aborting."

[ -f ./deps/fog ]
exit_on_error "./deps/fog not found, aborting."

echo "Building..."
docker build -t gestalt-installer . | tee buildoutput

exit_on_error "docker build failed, aborting."

imageid=`tail buildoutput | grep "^Successfully built" | awk '{ print $3 }'`

docker tag $imageid galacticfog/gestalt-installer:$1

exit_on_error "image tag failed, aborting."

echo "Build and publish successful."
