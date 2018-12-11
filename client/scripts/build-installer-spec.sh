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
    args: 
    - install
    - ${gestalt_install_mode}
    volumeMounts:
    - mountPath: /install-data
      name: install-data
  volumes:
    - name: install-data
      configMap:
        name: install-data
EOF
