#!/bin/bash

[ -d ./marketplace-k8s-app-tools ] ||  git clone git@github.com:GoogleCloudPlatform/marketplace-k8s-app-tools.git

[ -d ./chart/gestalt ] && rm -r ./chart/gestalt

cp -r ../../src/gestalt-helm-chart ./chart/gestalt

[ -d ./pre-build-resources ] && cp ./pre-build-resources/* ./chart/gestalt/templates/
