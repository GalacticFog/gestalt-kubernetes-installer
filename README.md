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
