#!/bin/bash

PUBLISH=0
DEFAULT_TAG="latest"
LABEL="gestalt-installer-base"
REGISTRY="galacticfog"

usage() {
  local CMD=`basename $0`
  echo "\
$CMD USAGE:
    $CMD [-p] [-r REGISTRY] [-t TAG] [-l LABEL]
    
    OPTIONS:
    -p
      Push the built image to the container image registry (default false)
    -r REGISTRY
      Push the built image to this registry (default DockerHub 'galacticfog' registry)
    -l LABEL
      Use this image label value (default 'gestalt-installer-base')
    -t TAG
      Publish the image with this tag value. Can be used multiple times. (default 'latest')
"
}

declare -a TAGS

while getopts ":phl:r:t:" opt; do
  case ${opt} in
    h)
      usage
      exit 0
      ;;
    p)
      PUBLISH=1
      ;;
    r)
      REGISTRY=$OPTARG
      ;;
    t)
      TAGS+=("$OPTARG")
      ;;
    l)
      LABEL=$OPTARG
      ;;
    ?) 
      echo "INVALID INPUT option '-${OPTARG}' undefined!" 1>&2
      usage
      exit 1
      ;;
    : )
      echo "INVALID INPUT option '-${OPTARG}' requires an argument!" 1>&2
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [ ${#TAGS[@]} -gt 0 ]; then
  echo "${#TAGS[@]} defined '${TAGS[*]}'"
else
  TAGS+=("${DEFAULT_TAG}")
  echo "${#TAGS[@]} default '${TAGS[*]}'"
fi

NOT_STRING="NOT "
if [ $PUBLISH -eq 1 ]; then
  NOT_STRING=""
fi
echo "$0 will ${NOT_STRING}publish image as $REGISTRY/$LABEL:$TAGS"

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

#Build the image
echo "Building..."
BUILD_OUTPUT=$( docker build -t "${REGISTRY}/${LABEL}:build" . 2>&1 )
if [ $? -ne 0 ]; then
  echo $BUILD_OUTPUT
  exit_with_error "docker build failed for '$LABEL', aborting!"
fi

imageid=$( grep "^Successfully built" <<<"$BUILD_OUTPUT" | awk '{ print $3 }' )
if [ -z "${imageid}" ]; then
  exit_with_error "Failed to obtain newly created image id from docker build output!"
fi
echo "----- Successfully built ${LABEL} image with ID '$imageid'"

#Tag and Push
for TAG in ${TAGS[@]}; do
  full_tag="${REGISTRY}/${LABEL}:${TAG}"
  echo "tagging ${LABEL} image id ${imageid} as ${full_tag}"
  docker tag $imageid $full_tag
  exit_on_error "image tag '${full_tag}' failed, aborting."
  if [ ${PUBLISH} -eq 1 ]; then
    PUSH_CMD="docker push ${full_tag}"
    $PUSH_CMD
    exit_on_error "docker push to '${full_tag}' failed, aborting."
  fi
done

echo "Build and publish successful."
