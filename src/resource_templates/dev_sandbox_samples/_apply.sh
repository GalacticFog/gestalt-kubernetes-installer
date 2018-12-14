#!/bin/bash

set -e

fog apply -d orgs

fog apply -d demo_workspace

fog apply -d demo_environments --context /training/demo 

fog apply -d dev_sandbox --context /sandbox/dev-sandbox/dev

echo
echo "Done creating sample resources."
