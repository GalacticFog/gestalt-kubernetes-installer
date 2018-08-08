cat - << EOF
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
