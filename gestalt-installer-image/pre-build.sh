#!/bin/bash

set -e

[ -d ./app/install ] && rm -r ./app/install && mkdir ./app/install

cp -r ../scripts ./app/install/
cp -r ../resource_templates ./app/install/
cp -r ../gestalt-helm-chart ./app/install/
