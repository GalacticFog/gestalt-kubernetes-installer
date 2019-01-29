#!/bin/bash

exit_on_error() {
  if [ $? -ne 0 ]; then
    echo
    echo "[Error] $@"
    exit 1
  fi
}

# Before runnign do: docker login

# Source
gestalt_docker_release_tag="2.4.1"
gestalt_installer_docker_release_tag="2.4.1"
docker_registry="galacticfog"
# Target
target_registry="gcr.io/kube-test-env-208414" #GF gke

# Manually grap all applicable images for installer
# grep -v ^# base-config.yaml | grep 'docker.io/galacticfog/' | awk '{print $2}' | awk -F'/' '{print $2"/"$3}'
ALL_IMAGES=(
gestalt-laser-executor-dotnet:2.4.1
elasticsearch-docker:5.3.1
gestalt-laser-executor-golang:2.4.1
gestalt-laser-executor-graalvm:2.4.1
gestalt-api-gateway:2.4.1
gestalt-api-gateway:2.4.1
gestalt-laser-executor-js:2.4.1
gestalt-laser-executor-jvm:2.4.1
kong:2.4.1
gestalt-laser:2.4.1
gestalt-log:2.4.1
gestalt-meta:2.4.1
gestalt-laser-executor-nodejs:2.4.1
gestalt-policy:2.4.1
gestalt-laser-executor-python:python-3.6.1
gestalt-laser-executor-python:python-3.6.3
gestalt-laser-executor-python:2.4.1
rabbit:2.4.1
gestalt-laser-executor-ruby:2.4.1
gestalt-security:2.4.1
gestalt-ui-react:2.4.1
gestalt-upgrader:2.4.1
redis:2.4.1
gestalt-tracking-service:2.4.1
gestalt-ubb-agent:2.4.1
postgres:2.4.1
gestalt-laser-executor-hyper:2.4.1
)
# grep '${docker_registry}' ./client/scripts/build-installer-spec.sh | awk -F'"' '{print $2}' | awk -F'/' '{print $2}'
ALL_IMAGES="${ALL_IMAGES} gestalt-installer:${gestalt_installer_docker_release_tag}"

# Pull all images and save locally
for CURR_IMAGE in ${ALL_IMAGES[@]}; do
  cmd="docker pull ${docker_registry}/${CURR_IMAGE}"
  echo "[Info] Pulling image: ${cmd} ..." 
  ${cmd}
  exit_on_error "Failed download image: ${cmd}"
done

# Tag and upload images to target
for CURR_IMAGE in ${ALL_IMAGES[@]}; do
  cmd="docker tag ${docker_registry}/${CURR_IMAGE}  ${target_registry}/${CURR_IMAGE}"
  echo "[Info] Tagging image: ${cmd} ..."
  ${cmd}
  exit_on_error "Failed tag an image: ${cmd}"
  cmd="docker push ${target_registry}/${CURR_IMAGE}"
  echo "[Info] Pushing image: ${cmd} ..."
  ${cmd}
  exit_on_error "Failed to push an image: ${cmd}"
done
