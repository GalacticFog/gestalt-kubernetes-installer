#!/bin/bash

set -e

cd base
./create_providers.sh
cd -

fog apply -d hierarchy

fog apply -d dev_sandbox_samples --context /sandbox/dev-sandbox/dev

