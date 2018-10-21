# Installation Steps

## Step 1: Pre-Install Configuration

1. Modify `credentials.conf` and `gestalt.conf` to match your target environment, and ensure `gestalt-license.json` is present.
2. Ensure the kubectl current context is set to the target Kubernetes cluster.  Check with `kubectl config current-context`, and set with `kubectl config use-context <context name>`.
3. Run `./configure.sh`

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

1. Run `./stage.sh`

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


# Cheatsheet

### GF re-build Image
```
# your local code repo base folder
REPO_BASE="/galactic-fog/src/gitlab/000-active-work/gestalt-platform-installer"
```

```
# navigate and build with repulling dependenies
cd ${REPO_BASE}/gestalt-installer-image
./dependencies-process.sh -c "clean"
./dependencies-process.sh
#Specify all applicable tags
./build_and_publish.sh "3.0.0" "3"
```


### Client Side

- Paste your Gestalt License Contents into "gestalt-license.json"
- Set credentials in "credentials.conf"
- Set gestalt configuration in "gestalt.conf"
- If you choose custom resources
    - Set gestalt_custom_resources=true in "gestalt.conf"
    - create "resource_templates" folder
    - create all custom resource templates in "resource_templates" folder
    - create appropriate cusom resource promotion script  "create_gestalt_resources.sh" in "resource_templates" folder

- Run configure and install:
```
# your local code repo base folder
REPO_BASE="/galactic-fog/src/gitlab/000-active-work/gestalt-platform-installer"
```
```
# Cleanup, configure and install
cd ${REPO_BASE}/client
kubectl delete namespace gestalt-system
kubectl create namespace gestalt-system
./configure.sh
./stage.sh
./install.sh
sleep 3
INSTALLER_POD=$(kubectl get pods --namespace gestalt-system | grep installer | awk '{print $1}')
kubectl describe pod ${INSTALLER_POD} --namespace gestalt-system
kubectl logs --namespace gestalt-system  ${INSTALLER_POD}
```
```
# Get on installer in interactove shell 
kbash ()  {      kubectl exec --namespace $1 -ti $2 -- bash; }
kbash gestalt-system gestalt-installer
```
