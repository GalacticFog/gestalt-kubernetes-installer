#!/bin/bash

# When this script is launched from the install-gestalt-platform script, the
# RELEASE_NAMESPACE variable should already be set.  If not, read it from the
# ./gestalt.conf file
if [ -z "$RELEASE_NAMESPACE" ]; then
  source ./helpers/install-functions.sh
  . ./gestalt.conf
fi

PROFILE=$(check_profile ${1})
if [ $? -ne 0 ]; then
  echo "$PROFILE"
  exit 1
fi
debug "FOUND PROFILE $PROFILE"

# Source common project configuration and utilities
PROJECT_CHECK_FUNCTIONS='./scripts/utilities/utility-project-check.sh'
if [ -f ${PROJECT_CHECK_FUNCTIONS} ]; then
  . ${PROJECT_CHECK_FUNCTIONS}
else
  echo "[ERROR] Project initialization script '${PROJECT_CHECK_FUNCTIONS}' can not be located, aborting. "
  exit 1
fi

INSTALLER_NAME="${RELEASE_NAME}-installer"

INSTALLER_IMAGE=$(get_installer_image_config $PROFILE)

read -r -d '' INSTALLER_YAML <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: '${INSTALLER_NAME}'
  labels:
    gestalt-app: 'installer'
    app.kubernetes.io/name: '${RELEASE_NAME}'
    app.kubernetes.io/app: 'gestalt'
    app.kubernetes.io/component: '${INSTALLER_NAME}'
spec:
  restartPolicy: Never
  imagePullSecrets:
  - name: imagepullsecret-1
  - name: imagepullsecret-2
  - name: imagepullsecret-3
  - name: imagepullsecret-4
  - name: imagepullsecret-5
  containers:
  - name: '${INSTALLER_NAME}'
    image: '${INSTALLER_IMAGE}'
    imagePullPolicy: Always
    args:
    - install
    - debug
    env:
    - name: RELEASE_NAME
      value: '${RELEASE_NAME}'
    - name: RELEASE_NAMESPACE
      value: '${RELEASE_NAMESPACE}'
    volumeMounts:
    - mountPath: /install-data
      name: install-data
  volumes:
    - name: install-data
      configMap:
        name: install-data
EOF

debug "$INSTALLER_YAML"

echo "=> Launching install Pod ..."
echo "$INSTALLER_YAML" | kubectl create -n ${RELEASE_NAMESPACE} -f -
exit_on_error "Failed to install Gestalt, aborting."

echo
echo "Gestalt Platform installer deployed to '${RELEASE_NAMESPACE}'.  To view the installer progress, run the following:"
echo
echo "  kubectl logs -n ${RELEASE_NAMESPACE} ${INSTALLER_NAME} --follow"
echo
echo "Done."
