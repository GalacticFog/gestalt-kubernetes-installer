#!/bin/bash

exit_on_error() {
  if [ $? -ne 0 ]; then
    echo
    echo "[Error] $@"
    exit 1
  fi
}

exit_with_error() {
    echo
    echo "[Error] $@"
    exit 1
}

# Source common project configuration and utilities
utility_file='./utilities/utility-image-initialize.sh'
if [ -f ${utility_file} ]; then
  . ${utility_file}
else
  echo "[ERROR] Project initialization script '${utility_file}' can not be located, aborting. "
  exit 1
fi

# TODO: Make as options publish flag and tag(-s)
publish="true" # true - do docker push, false - don't

# Validate that at least one tag provided
if [ $# -lt 1 ]; then
  build_and_publish_help
fi

# Validate that all dependency binaries are downloaded
build_and_publish_validate_deps

#Build
echo "Building..."
docker build -t gestalt-installer . | tee buildoutput
exit_on_error "docker build failed, aborting."
imageid=`tail buildoutput | grep "^Successfully built" | awk '{ print $3 }'`
if [ "${imageid}" == "" ]; then
  exit_with_error "Failed obtain newly created image id"
fi


#Tag and Push
for curr_tag in $@; do
  echo "Tagging ${curr_tag}"
  docker tag $imageid galacticfog/gestalt-installer:${curr_tag}
  exit_on_error "image tag '${curr_tag}' failed, aborting."
  if [ ${publish} == "true" ]; then
    docker push galacticfog/gestalt-installer:${curr_tag}
    exit_on_error "docker push failed, aborting."
  fi
done

echo "Build and publish successful."
