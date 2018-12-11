#!/bin/bash

set -e

[ -d ./chart/gestalt ] && rm -r ./chart/gestalt

cp -r ../gestalt-helm-chart ./chart/gestalt
