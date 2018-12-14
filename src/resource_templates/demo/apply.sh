#!/bin/bash -x

set -e

fog apply -d orgs

fog apply -d demo_workspace

fog apply -d demo_environments --context /training/demo 

fog apply -d lambda_demo  --context /training/demo/lambda_demo --params api=demo-lambda-demo --config config.yaml

fog apply -d lambda_chaining  --context /training/demo/lambda_chaining --params api=demo-lambda-chaining --config config.yaml

fog apply -d periodic_lambdas  --context /training/demo/periodic_lambdas --config config.yaml

fog apply -d async_lambdas  --context /training/demo/async_lambdas --params api=demo-async-lambdas --config config.yaml

fog apply -d ui_lambdas --context /training/demo/ui_lambdas --params api=demo-ui-lambdas --config config.yaml
