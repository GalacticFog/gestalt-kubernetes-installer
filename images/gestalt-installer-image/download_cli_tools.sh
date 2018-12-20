#!/bin/bash
#
# This script is meant to run in a "builder" container which downloads and
# extracts command-line tools for the Gestalt installer container base image.
# You can run it on your local computer if you like, and it will download
# the tools, but unless you're running Alpine Linux on your system they
# probably won't run.
#
# If you want to test this script with Docker, use this command.
#
#     docker build . --target builder
#
# See comments in the Dockerfile in this dir for more info.
#
DEFAULT_KUBECTL_VERSION="latest"
DEFAULT_HELM_VERSION="latest"
DEFAULT_FOG_VERSION="0.10.5"

ARCH="amd64"
OS="linux"
DISTRO="alpine"

FOG_DOWNLOAD_HOME="https://github.com/GalacticFog/gestalt-fog-cli/releases/download"

KUBECTL_DOWNLOAD_HOME="https://storage.googleapis.com/kubernetes-release/release"
KUBECTL_LATEST_VERSION_URL="${KUBECTL_DOWNLOAD_HOME}/stable.txt"

HELM_DOWNLOAD_HOME="https://kubernetes-helm.storage.googleapis.com"
HELM_RELEASE_HOME="https://github.com/helm/helm/releases"

FOG_VERSION=${DEFAULT_FOG_VERSION}
KUBECTL_VERSION=${DEFAULT_KUBECTL_VERSION}
HELM_VERSION=${DEFAULT_HELM_VERSION}

usage() {
  local CMD=`basename $0`
  echo "\
$CMD USAGE:
    $CMD [-h] [-f FOG_VERSION] [-l HELM_VERSION] [-k KUBECTL_VERSION]

    This script is meant to run within an Alpine Linux builder container which downloads 
    these CLI utilities for the Gestalt installer's base container image and then builds
    the base image and copies the utility binaries into it without their associated 
    distribution packages or similar junk.

    If you want to test it locally with Docker, try this command.

        docker build . --target builder

    See my comments at the top of the Dockerfile in this directory for more info.
    
    OPTIONS:
    -h
      Display this help text
    -f FOG_VERSION
      Download this version of the fog CLI utility (defaults to '$DEFAULT_FOG_VERSION')
    -k KUBECTL_VERSION
      Download this version of kubectl (default '$DEFAULT_KUBECTL_VERSION')
    -l HELM_VERSION
      Download this version of Helm (defaults to '$DEFAULT_HELM_VERSION')
"
}

while getopts ":hf:k:l:" opt; do
  case ${opt} in
    h)
      usage
      exit 0
      ;;
    f)
      echo "----- Setting FOG_VERSION to '$OPTARG' -----"
      FOG_VERSION=$OPTARG
      ;;
    k)
      echo "----- Setting KUBECTL_VERSION to '$OPTARG' -----"
      KUBECTL_VERSION=$OPTARG
      ;;
    l)
      echo "----- Setting HELM_VERSION to '$OPTARG' -----"
      HELM_VERSION=$OPTARG
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

OS_ARCH="${OS}-${ARCH}"
KUBECTL_DOWNLOAD_PATH="bin/${OS}/${ARCH}/kubectl"

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

download_fog() {
  local VERSION="$1"
  local FOG_PKG=$2 
  local DOWNLOAD_URL="${FOG_DOWNLOAD_HOME}/${VERSION}/gestalt-fog-cli-${DISTRO}-${VERSION}.zip"
  echo "Downloading fog CLI version $VERSION from '$DOWNLOAD_URL' to '$FOG_PKG'"
  curl -SsL ${DOWNLOAD_URL} -o ${FOG_PKG}
  exit_on_error "FAILED to download fog CLI from '${DOWNLOAD_URL}'!  Exiting..."
}

unzip_fog() {
  local FOG_PKG="$1"
  if [ -f $FOG_PKG ]; then
    echo "Unzipping file '$FOG_PKG'"
    unzip -o $FOG_PKG
    exit_on_error "FAILED to unzip fog CLI package '$FOG_PKG'!  Exiting..."
    rm $FOG_PKG
  else
    exit_with_error "No such file '$FOG_PKG' to unzip!  Exiting..."
  fi
}

get_fog() {
  local VERSION="$1"
  local FOG_BIN="./fog"
  local FOG_PKG="${FOG_BIN}.zip"
  download_fog $VERSION $FOG_PKG
  unzip_fog $FOG_PKG
  if [ -f "${FOG_BIN}" ]; then
    chmod 0755 ${FOG_BIN}
    # ${FOG_BIN} --version
  else
    exit_with_error "FAILED to extract fog CLI binary '${FOG_BIN}' from package '${FOG_PKG}'!  Exiting..."
  fi
}

kubectl_latest_version() {
  local VERSION=$(curl -s ${KUBECTL_LATEST_VERSION_URL})
  exit_on_error "FAILED to get latest kubectl version from '${KUBECTL_LATEST_VERSION_URL}'!  Exiting..."
  echo "$VERSION"
}

download_kubectl() {
  local VERSION="$1"
  local DOWNLOAD_URL="${KUBECTL_DOWNLOAD_HOME}/${VERSION}/${KUBECTL_DOWNLOAD_PATH}"
  echo "Downloading kubectl version $VERSION from '$DOWNLOAD_URL'"
  curl -SsLO $DOWNLOAD_URL
  exit_on_error "FAILED to download kubectl version ${VERSION} from '${DOWNLOAD_URL}'!  Exiting..."
}

get_kubectl() {
  local VERSION="$1"
  local KUBECTL_BIN="./kubectl"
  if [ -z "$VERSION" ]; then
    echo "No kubectl version defined!  Using default version '$DEFAULT_KUBECTL_VERSION'..."
    VERSION="latest"
  fi
  if [ "$VERSION" == "latest" ]; then
    VERSION=$(kubectl_latest_version)
  fi
  download_kubectl $VERSION
  if [ -f "${KUBECTL_BIN}" ]; then
    chmod 0755 ${KUBECTL_BIN}
  fi
  # ${KUBECTL_BIN} version --client
}

resolve_helm_version() {
  VERSION="$1"
  HELM_RELEASE_URL="${HELM_RELEASE_HOME}/${VERSION}"
  RESOLVED=$(curl -SsL $HELM_RELEASE_URL | awk '/\/tag\//' | grep -v no-underline | head -n 1 | cut -d '"' -f 2 | awk '{n=split($NF,a,"/");print a[n]}')
  exit_on_error "FAILED to resolve helm version ${VERSION} at '${HELM_RELEASE_URL}'!  Exiting..."
  echo $RESOLVED
}

verify_helm_release() {
  local VERSION="$1"
  #echo "resolving helm version '$VERSION'"
  local RESOLVED=$(resolve_helm_version ${VERSION})
  #echo "RESOLVED version '$VERSION' to '$RESOLVED'"
  if [ -z "${RESOLVED}" ]; then
    if [ "$VERSION" == "latest" ]; then
      exit_with_error "Unable to obtain latest helm version!  Exiting..."
    fi
    #echo "Requested helm version $VERSION not found!  Obtaining latest version..."
    RESOLVED=$(resolve_helm_version latest)
    #echo "Latest helm version is '$RESOLVED'..."
  fi
  echo $RESOLVED
}

download_helm() {
  local VERSION="$1"
  local HELM_PKG="$2"
  local HELM_DIST="helm-${VERSION}-${OS_ARCH}.tar.gz"
  local DOWNLOAD_URL="${HELM_DOWNLOAD_HOME}/${HELM_DIST}"
  echo "Downloading helm version $VERSION from '$DOWNLOAD_URL' to '${HELM_PKG}'"
  curl -SsL "${DOWNLOAD_URL}" -o "${HELM_PKG}"
  exit_on_error "Unable to download helm ${VERSION} from '${DOWNLOAD_URL}'!  Exiting..."
}

extract_helm() {
  local HELM_PKG="$1"
  local HELM_BIN="$2"
  local HELM_PKG_DIR="./helm_package"
  mkdir -p ${HELM_PKG_DIR}
  gunzip -c "${HELM_PKG}" | tar -xpf - -C "$HELM_PKG_DIR"
  local HELM_EXT="${HELM_PKG_DIR}/${OS_ARCH}/helm"
  if [ -f "$HELM_EXT" ]; then
    mv "$HELM_EXT" "$HELM_BIN"
    exit_on_error "FAILED to move helm binary '$HELM_EXT' to '$HELM_BIN'!  Exiting..."
  else
    exit_with_error "FAILED to find helm binary at '$HELM_EXT'!  Exiting..."
  fi
  rm $HELM_PKG
  rm -Rf $HELM_PKG_DIR
}

get_helm() {
  local VERSION=$1
  if [ -z "$VERSION" ]; then
    echo "No helm version defined!  Looking up default version..."
    VERSION=${DEFAULT_HELM_VERSION}
  fi
  VERSION=$(verify_helm_release "$VERSION")
  local HELM_BIN="./helm"
  local HELM_PKG="${HELM_BIN}.tar.gz"
  download_helm ${VERSION} ${HELM_PKG}
  extract_helm ${HELM_PKG} ${HELM_BIN}
  if [ -f "${HELM_BIN}" ]; then
    chmod 0755 $HELM_BIN
    exit_on_error "FAILED to make helm binary at '$HELM_BIN' executable!  Exiting..."
  else
    exit_with_error "FAILED to find helm binary at '$HELM_BIN'!  Exiting..."
  fi
  # ${HELM_BIN} version -c
}

get_kubectl $KUBECTL_VERSION
get_helm $HELM_VERSION
get_fog $FOG_VERSION

echo "Command-line tools successfully downloaded!"
