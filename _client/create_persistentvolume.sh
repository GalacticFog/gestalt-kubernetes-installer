#!/bin/bash
################################################################################
#
# Use this script to create a Kubernetes persistentvolume resource in which the
# postgres database can store its data. You shouldn't need to do this for EKS or
# GKE installs, but you'll need it for local docker-for-desktop or minikube.
#
################################################################################

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gestalt-postgresql-volume
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 100Mi
  hostPath:
    path: /tmp/gestalt-postgresql-volume
    type: ""
  persistentVolumeReclaimPolicy: Delete
  storageClassName: gestalt-postgresql-volume
EOF
