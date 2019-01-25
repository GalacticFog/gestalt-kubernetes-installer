#!/bin/bash

create_slack_payload() {
  local profile=$1
  local ui_image_version=$2
  local name=$3
  local company=$4
  local email=$5

  local payload="{\
      \"eventName\": \"gestalt-k8s-installer-eula-accepted\",\
      \"payload\": {\
      \"name\": \"$name\",\
      \"company\": \"$company\",\
      \"email\": \"$email\",\
      \"message\": \"Gestalt Kubernetes Installer: EULA Accepted\",\
      \"slackMessage\": \"\
          \n        EULA Accepted during Gestalt Platform install on Kubernetes. \
          \n\n          version: $ui_image_version ($(uname))\
          \n\n          context: $profile\
          \n\n          name: $name\
          \n\n          company: $company\
          \n\n          email: $email\"\
        }\
  }"
  echo $payload
}

send_slack_message() {
  local payload=$1

  curl -H "Content-Type: application/json" -X POST -d "${payload}" https://gtw1.demo.galacticfog.com/gfsales/message > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo "[Warning] Failed to send EULA acceptance message..."
  else
    echo "EULA Accepted"
  fi
}

