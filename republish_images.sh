#!/bin/bash

PULL_IMAGES=0
PUSH_IMAGES=0
LOG=1
LOG_FILE="log"
LOG_STARTED=0
SILENT=0
VERBOSE=1
RUN_BASE=`basename $0`
PRINT_IMAGE_IDS=0
SOURCE_REGISTRY="galacticfog"
declare -a SOURCE_TAGS
DEFAULT_SOURCE_TAG="2.4.1-RC"
TARGET_REGISTRY="gcr.io/galacticfog-public"
declare -a TARGET_TAGS
DEFAULT_TARGET_TAG="latest"
declare -a IMAGES
DEFAULT_IMAGES=(
  # 'gestalt-installer'
  # 'gestalt-deployer'
  'gestalt-meta'
  'gestalt-security'
  'gestalt-log'
  'gestalt-ui-react'
  'gestalt-policy'
  'gestalt-api-gateway'
  # 'gestalt-tracking-service'
  # 'gestalt-ubb-agent'
  # 'gestalt-redis'
  'gestalt-laser'
  # 'gestalt-laser-executor-bash'
  'gestalt-laser-executor-dotnet'
  'gestalt-laser-executor-golang'
  'gestalt-laser-executor-js'
  'gestalt-laser-executor-nodejs'
  'gestalt-laser-executor-jvm'
  'gestalt-laser-executor-python'
  'gestalt-laser-executor-ruby'
  'kong'
  'rabbit'
  # 'elasticsearch-docker:5.3.1'
  # 'busybox:1.29.3'
)

debug() {
  log "$@"
  if [ $VERBOSE -ne 0 ] && [ $SILENT -eq 0 ]; then
    echo "$@"
  fi
}

info() {
  log "$@"
  if [ $SILENT -eq 0 ]; then
    echo "$@"
  fi
}

error() {
  log "[ERROR] $@"
  >&2 echo "[Error] $@"
}

exit_with_error() {
  error "$@"
  exit 1
}

exit_on_error() {
  [ $? -eq 0 ] || exit_with_error "$@"
}

log() {
  [ $LOG -eq 1 ] && [ $LOG_STARTED -eq 1 ] && echo "$@" >> $LOG_FILE
}

start_log() {
  LOG_FILE="${RUN_BASE}.log"
  LOG_STARTED=1
  local TIMESTAMP=`date`
  log "[${TIMESTAMP}] start of run for $RUN_BASE"
}

usage() {
  local CMD=$RUN_BASE
  echo "\

$CMD USAGE:
    $CMD [OPTIONS]
    
    OPTIONS:
    -h
      Print this help info to STDOUT.
    -p
      Pull the images from the source image registry.
    -P
      Push the pulled images to the target image registry.
    -r SOURCE_REGISTRY
      Push the built image to this registry. (default DockerHub '${SOURCE_REGISTRY}' registry)
    -R TARGET_REGISTRY
      Push the built image to this registry. (default Google '${TARGET_REGISTRY}' registry)
    -i IMAGE
      Adds an image to the list that will be pulled and/or pushed.
    -t SOURCE_TAG
      Pull images with this tag. Can be used multiple times. (no default value)
    -T TARGET_TAG
      Tag the image with this value. Can be used multiple times. (no default value)
    -s
      Run silent.  Do not print output to STDOUT, but print errors to STDERR.
    -v
      Run verbose - print additional diagnostic output to STDOUT.  NOTE: -s overrides -v
    -z
      Print pulled image IDs to STDOUT even if the -s flag is set.  If both -s and -z
      flags are set, the image IDs will be the only output.
"
}

while getopts ":hpPsvzi:r:R:t:T:" opt; do
  case ${opt} in
    h)
      debug "-h flag is set!  Printing usage info to STDOUT..."
      usage
      exit 0
      ;;
    p)
      PULL_IMAGES=1
      debug "-p flag is set to PULL images!"
      ;;
    P)
      PUSH_IMAGES=1
      debug "-P flag is set to PUSH images!"
      ;;
    i)
      IMAGES+=("$OPTARG")
      debug "-i option adds IMAGE '$OPTARG'"
      debug "IMAGES = ( ${IMAGES[@]} )"
      ;;
    r)
      SOURCE_REGISTRY=$OPTARG
      debug "-r option sets SOURCE_REGISTRY to '$SOURCE_REGISTRY'"
      ;;
    R)
      TARGET_REGISTRY=$OPTARG
      debug "-r option sets TARGET_REGISTRY to '$TARGET_REGISTRY'"
      ;;
    t)
      SOURCE_TAGS+=("$OPTARG")
      debug "-t option adds SOURCE_TAG '$OPTARG'"
      debug "SOURCE_TAGS = ( ${SOURCE_TAGS[@]} )"
      ;;
    T)
      TARGET_TAGS+=("$OPTARG")
      debug "-t option adds TARGET_TAG '$OPTARG'"
      debug "TARGET_TAGS = ( ${TARGET_TAGS[@]} )"
      ;;
    s)
      debug "-s flag is set!"
      SILENT=1
      ;;
    v)
      VERBOSE=1
      debug "-v flag is set!"
      ;;
    z)
      debug "-z flag is set!"
      PRINT_IMAGE_IDS=1
      ;;
    :)
      exit_with_error "INVALID INPUT option '-${OPTARG}' requires an argument! $(usage)"
      ;;
    ?) 
      exit_with_error "INVALID INPUT option '-${OPTARG}' undefined! $(usage)"
      ;;
  esac
done
shift $((OPTIND -1))

start_log

if [ ${#IMAGES[@]} -gt 0 ]; then
  debug "${#IMAGES[@]} images defined '${IMAGES[*]}'"
else
  debug "Using default image list '${DEFAULT_IMAGES[*]}'"
  IMAGES=${DEFAULT_IMAGES[@]}
fi

if [ ${#SOURCE_TAGS[@]} -gt 0 ]; then
  debug "${#SOURCE_TAGS[@]} tags defined '${SOURCE_TAGS[*]}'"
else
  debug "Pulling only the default tag '${DEFAULT_SOURCE_TAG}'"
  SOURCE_TAGS=( "$DEFAULT_SOURCE_TAG" )
fi

if [ ${#TARGET_TAGS[@]} -gt 0 ]; then
  debug "${#TARGET_TAGS[@]} tags defined '${TARGET_TAGS[*]}'"
else
  debug "Pushing only the default tag '${DEFAULT_TARGET_TAG}'"
  TARGET_TAGS=( "$DEFAULT_TARGET_TAG" )
fi

NOT_STRING="NOT "
if [ $PULL_IMAGES -eq 1 ]; then
  NOT_STRING=""
fi
debug "$0 will ${NOT_STRING}pull images from the '$SOURCE_REGISTRY' registry"

NOT_STRING="NOT "
if [ $PUSH_IMAGES -eq 1 ]; then
  NOT_STRING=""
fi
debug "$0 will ${NOT_STRING}push the pulled image to the '$TARGET_REGISTRY' registry"

OUTPUT="no command has been called!"
get_output() {
  echo
  echo "------------------------------ START OUTPUT ------------------------------"
  echo "${OUTPUT}"
  echo "------------------------------- END OUTPUT -------------------------------"
}

PULL_FAILED=0
PUSH_FAILED=0
TAG_FAILED=0
IMAGE_ID=""

PULL_CMD="docker pull"
PUSH_CMD="docker push"
TAG_CMD="docker tag"
IMAGE_CMD="docker image ls -q"

get_id_for() {
  local TAG=$1
  local CMD="${IMAGE_CMD} ${TAG}"
  log "getting image ID for $TAG"
  log "GET_ID executing $CMD"
  local IMAGE_ID=$(${CMD})
  if [ $? -eq 0 ]; then
    if [ -z $IMAGE_ID ]; then
      echo "FAILED"
    else
      log "pulled image $IMAGE_ID for $TAG"
      echo $IMAGE_ID
    fi
  else
    echo "FAILED"
  fi
}

push_tag() {
  local TAG=$1
  local CMD="${PUSH_CMD} ${TAG}"
  debug "PUSH executing $CMD"
  OUTPUT=$(${CMD})
  if [ $? -eq 0 ]; then
    info "PUSH SUCCESS for '$TAG' using command '$CMD'"
    debug "$(get_output)"
    PUSH_FAILED=0
  else
    error "PUSH FAILED for '$TAG' using command '$CMD' $(get_output)"
    PUSH_FAILED=1
  fi
}

tag_image() {
  local IMAGE_ID=$1
  local TAG=$2
  local CMD="${TAG_CMD} ${IMAGE_ID} ${TAG}"
  debug "TAG executing $CMD"
  OUTPUT=$(${CMD})
  if [ $? -eq 0 ]; then
    info "TAG SUCCESS for image ${IMAGE_ID} using command '$CMD'"
    debug "$(get_output)"
    TAG_FAILED=0
  else
    error "TAG FAILED for image ${IMAGE_ID}  using command '$CMD' $(get_output)"
    TAG_FAILED=1
  fi
}

push_image() {
  local IMAGE_ID=$1
  local IMAGE=$2
  for TAG in ${TARGET_TAGS[@]}; do
    debug "pushing tag ${TAG} for ${IMAGE} to ${TARGET_REGISTRY}"
    local P_TAG="${TARGET_REGISTRY}/${IMAGE}:${TAG}"
    tag_image ${IMAGE_ID} ${P_TAG}
    [ $TAG_FAILED -eq 0 ] && push_tag ${P_TAG}
  done
}

pull_tag() {
  local TAG=$1
  local CMD="${PULL_CMD} ${TAG}"
  debug "PULL executing $CMD"
  OUTPUT=$(${CMD})
  if [ $? -eq 0 ]; then
    info "PULL SUCCESS for '$TAG' using command '$CMD'"
    debug "$(get_output)"
    PULL_FAILED=0
  else
    error "PULL FAILED for '$TAG' using command '$CMD' $(get_output)"
    PULL_FAILED=1
  fi
}

retag_and_push() {
  local PULL_TAG=$1
  local IMAGE_ID=$(get_id_for ${PULL_TAG})
  debug "found image id $IMAGE_ID for $PULL_TAG"
  [ $PUSH_IMAGES -ne 0 ] && [ $IMAGE_ID != "FAILED" ] && push_image ${IMAGE_ID} ${IMAGE}
}

pull_image() {
  local IMAGE=$1
  local TAG
  for TAG in ${SOURCE_TAGS[@]}; do
    local PULL_TAG="${SOURCE_REGISTRY}/${IMAGE}:${TAG}"
    pull_tag ${PULL_TAG}
    if [ $PULL_FAILED -eq 0 ]; then
      retag_and_push ${PULL_TAG}
    fi
  done
}

push_tags() {
  local IMAGE=$1
  local TAG
  for TAG in ${SOURCE_TAGS[@]}; do
    local PULL_TAG="${SOURCE_REGISTRY}/${IMAGE}:${TAG}"
    retag_and_push ${PULL_TAG}
  done
}

push_images() {
  local IMAGE
  debug "pushing ${#IMAGES[@]} images"
  for IMAGE in ${IMAGES[@]}; do
    info "----- pushing image $IMAGE"
    push_tags ${IMAGE}
  done
}

pull_images() {
  local IMAGE
  debug "pulling ${#IMAGES[@]} images"
  for IMAGE in ${IMAGES[@]}; do
    info "----- pulling image $IMAGE"
    pull_image $IMAGE
  done
}

if [ $PULL_IMAGES -ne 0 ]; then
  pull_images
else
  push_images
fi

info "Done."
