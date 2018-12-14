#!/bin/bash

set -e

[ -d ./chart/gestalt ] && rm -r ./chart/gestalt

cp -r ../../src/gestalt-helm-chart ./chart/gestalt
