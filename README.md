


## Usage

Run the installer
```sh

# Create a config map from the configuration
kubectl create configmap gestalt-installer-config --from-file install-config.yaml

# Optionally, create a config map from the sample resource files
TODO

# Run the install container with ConfigMaps
kubectl apply -f installer.yaml

```
