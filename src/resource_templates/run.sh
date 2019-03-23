#!/bin/bash

set -e

if [ ! -z "$fog_cli_config" ]; then
    fog config set $fog_cli_config
fi

cd base
./run.sh
cd ~-

fog apply -d hierarchy

if [ -z "$SKIP_SANDBOX_SAMPLES" ]; then
  fog apply -d dev_sandbox_samples --context /sandbox/dev-sandbox/dev
fi
