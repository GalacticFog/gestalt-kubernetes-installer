# From https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/building-deployer-helm.md#first-deployment
#
# Requires the `mpdev` tool pre-installed. See the `gcloud_get_mpdev.sh` script.
#
# See: https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/tool-prerequisites.md
# Container image with all the required tools: docker pull gcr.io/cloud-marketplace-tools/k8s/dev
# 
# Docs for `mpdev`: https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/mpdev-references.md
#
# WARNING! I have not tested this - just pulled from the docs page above and keeping it here for future reference
#
export PROJECT=$(gcloud config get-value project | tr ':' '/')
# Set the registry to your project GCR repo.
export REGISTRY=gcr.io/${PROJECT}
export APP_NAME=gestalt

kubectl create namespace test-ns

# Apply the GCP Marketplace Application CRD
kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"

# Run `mpdev doctor` to diagnose and set up your environment
mpdev /scripts/doctor.py

# Run `mpdev install` to kick off your deployer
mpdev /scripts/install --deployer=$REGISTRY/$APP_NAME/deployer --parameters='{"name": "test-deployment", "namespace": "test-ns"}'

echo "Project ${PROJECT} install complete..."
echo "You should see the project has been deployed at https://console.cloud.google.com/kubernetes/application?project=${PROJECT}"

# Should be able to delete the deployed application my deleting the Application resource (again - NOT TESTED with GESTALT YET!)
# kubectl delete application <APPLICATION DEPLOYMENT NAME>
