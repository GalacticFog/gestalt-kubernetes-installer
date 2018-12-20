# General Gestalt Install Procedure for Kubernetes

1\. Verify your cluster is available:
```sh
kubectl cluster-info
```

2\. Edit the configuration file parameters to match your target environment:
```sh
vi ./profiles/<target env>/env.conf
```

3\. Run the installer using one of the provided configuration files:
```sh
./install-gestalt-platform [target profile]
```
