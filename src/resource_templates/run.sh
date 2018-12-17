#!/bin/bash

set -e

if [ ! -z "$fog_cli_config" ]; then
    fog config set $fog_cli_config
fi

cd base
./run.sh
cd -

fog apply -d hierarchy

fog apply -d dev_sandbox_samples --context /sandbox/dev-sandbox/dev

# cd demo ; ./run.sh ; cd -
