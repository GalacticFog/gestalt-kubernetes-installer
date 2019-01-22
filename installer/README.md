# Installation Steps

## Quick Start

```sh
./install-gestalt-platform              # Run installation, follow on-screen prompts
```

## Advanced
```sh
vi ./base-config.yaml                   # Change configuration options

vi ./profile/<profile>/config.yaml      # Change Host settings

./install-gestalt-platform <profile>    # Run this if a profile can't be auto-detected.  See ./profiles directory for profiles
```

# Removing Gestalt Platform

Run `./remove.sh` and follow the prompts.


# Troubleshooting

View installer logs:
```
kubectl logs --namespace gestalt-system  gestalt-installer
```

Get a shell to the installer Pod:
```
kubectl exec --namespace gestalt-system -ti gestalt-installer -- bash
```

View logs:
```
ls logs/*
```

Run diagnostics:
```
./run-diagnostics
```
