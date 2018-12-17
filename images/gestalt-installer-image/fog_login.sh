#!/bin/bash

set -e

. gestalt.conf

gestalt_admin_username=`kubectl get secrets -n gestalt-system gestalt-secrets -ojsonpath='{.data.admin-username}' | base64 --decode`
gestalt_admin_password=`kubectl get secrets -n gestalt-system gestalt-secrets -ojsonpath='{.data.admin-password}' | base64 --decode`

fog login $gestalt_ui_service_url -u $gestalt_admin_username -p $gestalt_admin_password
