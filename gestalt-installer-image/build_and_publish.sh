#!/bin/bash

# Script specific utility functions
help_build_and_publish () {
  echo ""
  echo "Script '$0' was called with $# arguments. At lest one expected."
  echo ""
  echo "Usage: "
  echo "    ./build_and_publish.sh <docker label> [<override binaries>]"
  echo "          <docker label> - docker label for generated image"
  echo "          (<override binaries>) - optional flag to override packaged binaries if exists. Supported values: {true, false (default)}"
  echo ""
  exit 1
}

# Global variables
utility_folder="./utilities"
utility_bash="${utility_folder}/utility-bash.sh"
utility_gestalt="${utility_folder}/utility-gestalt.sh"

conf_folder="./conf"
conf_getsalt="${conf_folder}/gestalt-platform-installer.conf"

binary_folder="/bin"

# ####################################################################
# START
# ####################################################################

# kubect="${binaries_folder}/kubecl"
# helm="${binaries_folder}/helm"

if [ $# -lt 1 ]; then
  help_build_and_publish
fi


# . ./utilities/utility-bash.sh
# . ./utilities/gestalt.sh
# . ./conf/gestalt-platform-installer.conf


 exit_on_error() {
  if [ $? -ne 0 ]; then
    echo $1
    exit 1
  fi
}



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

docker push galacticfog/gestalt-installer:$1

exit_on_error "docker push failed, aborting."

echo "Build and publish successful."


# ####################################################################
# START
# ####################################################################