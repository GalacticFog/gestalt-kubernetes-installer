#!/bin/bash

. gestalt.conf

# TODO: get gestalt-system namespace and security pod name dynamically
pod=`kubectl get pod -n ${RELEASE_NAMESPACE} | grep gestalt-security- | awk '{print $1}'`

kubectl cp ${RELEASE_NAMESPACE}/$pod:/etc/ssl/certs/java/cacerts .
