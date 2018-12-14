#!/bin/bash

set -e

cd base; ./run.sh ; cd -

fog apply -d hierarchy

fog apply -d dev_sandbox_samples --context /sandbox/dev-sandbox/dev

cd demo ; ./run.sh ; cd -
