#!/bin/bash

# Needs ./utilities/bash-utilities.sh

[[ $# -ne 1 ]] && echo && exit_with_error "File '$0' expects 1 parameter ($# provided) [$@], aborting."
GENERATED_CONF_FILE=$1


check_for_required_variables \
  docker_registry \
  gestalt_installer_docker_release_tag \
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
  imagePullSecrets:
  - name: imagepullsecret-1
  - name: imagepullsecret-2
  - name: imagepullsecret-3
  - name: imagepullsecret-4
  - name: imagepullsecret-5
  containers:
  - name: gestalt-installer
    image: "${docker_registry}/gestalt-installer:${gestalt_installer_docker_release_tag}"
    imagePullPolicy: Always
    # 'deploy' arg signals deployment of gestalt platform
    # 'debug' arg signals debug output
    command:
    - bash
    args: 
    - -c
    - rm -rf /gestalt && cat /gestalt2/gestalt.tar.gz.b64 | base64 -d > /tmp/gestalt.tar.gz && tar xfz /tmp/gestalt.tar.gz -C / && rm -rf /scripts && cp -r /scripts2 /scripts && chmod +x /scripts/*.sh && /scripts/entrypoint.sh install ${gestalt_install_mode}
    volumeMounts:
    - mountPath: /config
      name: config
    - mountPath: /license
      name: license
    - mountPath: /scripts2
      name: scripts
    - mountPath: /gestalt2
      name: gestalt-targz
    - mountPath: /resource_templates
      name: resources
  volumes:
    - name: config
      configMap:
        name: installer-config
    - name: scripts
      configMap:
        name: installer-scripts
    - name: gestalt-targz
      configMap:
        name: gestalt-targz
    - name: license
      configMap:
        name: gestalt-license
    - name: resources
      configMap:
        name: gestalt-resources
EOF
