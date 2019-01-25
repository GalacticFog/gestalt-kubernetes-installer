# Functional Tests

## Execute a Lambda

1. Login to Gestalt
2. Navigate to Sandbox -> Developer Sandbox -> Development -> Lambdas
3. Click on a lambda end-point  (the Factorial lambda, for instance)

A new browser tab should open, and running the lambda should not indicate any error.

## List using fog CLI

The following commands should not indicate any errors:

```sh
# From linux or MacOS:

./download_gestalt_cli.sh

./fog login <gestalt URL>   # (follow the prompts)

./fog status

./fog show hierarchy

./fog show containers /root/gestalt-system-workspace

./fog show lambdas /root/gestalt-system-workspace

```
