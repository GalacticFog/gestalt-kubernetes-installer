#!/bin/bash

set -e

[ -d ./app/install ] && rm -r ./app/install
mkdir ./app/install 

cp -r ../../src/scripts ./app/install/
cp -r ../../src/resource_templates ./app/install/
cp -r ../../src/gestalt-helm-chart ./app/install/

[ -d ./app/install/config ] || mkdir ./app/install/config
cp ../../installer/config/gestalt-license.json ./app/install/config/
cp ../../installer/config/install-config.yaml ./app/install/config/
