#!/bin/bash

# Needs ./utilities/bash-utilities.sh

check_for_required_variables \
  gestalt_installer_image \
  gestalt_install_mode

cat > ${kube_install} << EOF
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
    image: "${gestalt_installer_image}"
    imagePullPolicy: Always
    # 'deploy' arg signals deployment of gestalt platform
    # 'debug' arg signals debug output
    command:
    - bash
    args: 
    - -c
    - rm -rf /gestalt /scripts /resource_templates && cat /install-data/install-data.tar.gz.b64 | base64 -d > /tmp/install-data.tar.gz && tar xfz /tmp/install-data.tar.gz -C / && chmod +x /scripts/*.sh /resource_templates/*.sh && /scripts/entrypoint.sh install ${gestalt_install_mode}
    volumeMounts:
    - mountPath: /install-data
      name: install-data
  volumes:
    - name: install-data
      configMap:
        name: install-data
EOF
