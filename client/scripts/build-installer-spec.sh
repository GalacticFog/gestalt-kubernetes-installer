#!/bin/bash

# Needs ./utilities/bash-utilities.sh

[[ $# -ne 1 ]] && echo && exit_with_error "File '$0' expects 1 parameter ($# provided) [$@], aborting."
GENERATED_CONF_FILE=$1


check_for_required_variables \
  docker_registry \
  gestalt_docker_release_tag \
  gestalt_install_mode
  


cat > ${GENERATED_CONF_FILE} << EOF
# This is a pod w/ restartPolicy=Never so that the installer only runs once.
apiVersion: v1
kind: Pod
metadata:
  name: gestalt-installer
  labels:
    gestalt-app: installer
spec:
  restartPolicy: Never
  containers:
  - name: gestalt-installer
    image: "${docker_registry}/gestalt-installer:${gestalt_docker_release_tag}"
    imagePullPolicy: Always
    # 'deploy' arg signals deployment of gestalt platform
    # 'debug' arg signals debug output
    args: ["install", "${gestalt_install_mode}"]
    volumeMounts:
    - mountPath: /config
      name: config
  volumes:
    - name: config
      configMap:
        name: installer-config
EOF
