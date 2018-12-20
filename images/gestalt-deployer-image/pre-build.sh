#!/bin/bash

set -e

[ -d ./chart/gestalt ] && rm -r ./chart/gestalt

cp -r ../../src/gestalt-helm-chart ./chart/gestalt

[ -d ./pre-build-respurces ] && cp ./pre-build-resources/* ./chart/gestalt/templates/
