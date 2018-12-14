# Installation Steps

## Step 1: Pre-Install Configuration

1. Ensure `config/gestalt-license.json` is present.
2. Modify `config/install-config.yaml` for the target environment and desired configuration.
3. Ensure the kubectl current context is set to the target Kubernetes cluster.  Check with `kubectl config current-context`, and set with `kubectl config use-context <context name>`.
4. Run `./configure.sh`

This step generates the following:
- `installer.yaml` - To deploy the installer pod to the Kubernetes cluster
- `install-config.json` - Installer settings
- `./configmaps/gestalt/values.yaml` - Generated helm chart configuration

**Advanced configuration:**

4. Modify `install-config.json` to change any fine-grained settings.
5. Modify the Resource Templates at `./configmaps/resource_templates/*` if necessary.
6. Modify the Helm chart at `./configmaps/gestalt/*` if necessary.
7. Modify the `installer.yaml` if necessary.

## Step 2: Stage the Install Configuration

1. Run `kubectl create namespace gestalt-system` to create the installation namespace.
2. Run `./stage.sh`

This step creates the following configmaps for the installer:
- `installer-config` - The `install-config.json` file.
- `gestalt-license` - The `gestalt-license.json` file.
- `gestalt-targz` - The Gestalt helm chart (tar.gz file).
- `gestalt-resources` - The gestalt resource templates
- `installer-scripts` - The installation scripts (in `../gestalt-installer-image/scripts`)

## Step 3: Initiate the Installation

1. Run `./install.sh`

This step deploys `installer.yaml` to the Kubernetes cluster, which runs an installer Pod.  The Pod utilizes the ConfigMap resources defined in the previous step.

2. Run `./follow_log.sh` to follow the Gestalt installation logs emitted by the installer Pod.  When the installation is complete (or fails), press `Ctrl-C` to stop following the logs.

Installation is now complete.

# Removing Gestalt Platform

Run `./remove.sh` and follow the prompts.

# Building the `gestalt-installer` Docker Image 

```
cd ./gestalt-installer-image

# build with repulling dependenies
./dependencies-process.sh -c "clean"
./dependencies-process.sh

# Specify all applicable tags
./build_and_publish.sh "3.0.0" "3"
```

# Troubleshooting

View installer logs:
```
kubectl logs --namespace gestalt-system  ${INSTALLER_POD}
```

Get a shell to the installer Pod:
```
kubectl exec --namespace gestalt-system -ti gestalt-installer -- bash
```
