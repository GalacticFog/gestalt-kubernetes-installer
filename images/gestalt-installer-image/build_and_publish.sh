#!/bin/bash
set -e

# Use this only for local builds !!!!

# TODO: Make as options publish flag and tag(-s)
publish="false"
# publish="true" # true - do docker push, false - don't
build_log="./buildoutput"

echo "------------------------------------------------------"
echo "Build: Step 0: Initialize..."
. ./utilities/utility-bash.sh
echo "------------------------------------------------------"
echo "Build: Step 1: Run pre-build.."
./pre-build.sh 
echo "------------------------------------------------------"
echo "Build: Step 2: Clone License(-s) Repository / get up-to-date master.."
if [ ! -d "./license-definitions" ]; then
  echo "Next: Clone: 'git@gitlab.com:galacticfog/license-definitions.git'"
  git clone git@gitlab.com:galacticfog/license-definitions.git
else
  echo "Next: Get up-to date master"
  cd license-definitions
  git checkout master
  git pull
  cd ~-
fi
echo "------------------------------------------------------" | tee ${build_log}
echo "Build: Step 3: Build Image" | tee -a ${build_log}
echo "++++++++++Dockerfile:START++++++++++"
cat Dockerfile | tee -a ${build_log}
echo
echo "++++++++++Dockerfile:END++++++++++"
docker build -t gestalt-installer . | tee -a ${build_log}
exit_on_error "docker build failed, aborting."
imageid=`tail buildoutput | grep "^Successfully built" | awk '{ print $3 }'`
if [ "${imageid}" == "" ]; then
  exit_with_error "Failed obtain newly created image id"
else
  echo "Image Built: ${imageid}"
fi
echo "------------------------------------------------------"
echo "Build: Step 4: Tag and Push(Optional)"
for curr_tag in $@; do
  echo "Tagging ${curr_tag}"
  docker tag $imageid galacticfog/gestalt-installer:${curr_tag}
  exit_on_error "image tag '${curr_tag}' failed, aborting."
  if [ ${publish} == "true" ]; then
    docker push galacticfog/gestalt-installer:${curr_tag}
    exit_on_error "docker push failed, aborting."
  else
    echo "Skipping push due publish=${publish}"
  fi
done

echo "Build and publish successful."
