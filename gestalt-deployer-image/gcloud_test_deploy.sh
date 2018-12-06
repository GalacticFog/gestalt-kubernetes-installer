# From https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/building-deployer-helm.md#first-deployment
#
# First: git clone git@github.com:GoogleCloudPlatform/marketplace-k8s-app-tools.git
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
echo "PROJECT: ${PROJECT}"
# Set the registry to your project GCR repo.
export REGISTRY=gcr.io/${PROJECT}
echo "REGISTRY: ${REGISTRY}"
# export APP_NAME=gestalt
export DEPLOYER_TAG="$REGISTRY/gestalt-deployer:testing"
echo "DEPLOYER TAG: ${DEPLOYER_TAG}"

export TEST_NAME="gestalt"
export TEST_NAMESPACE="gestalt-system"

# Create the test namespace if it doesn't already exist
FOUND_NS=$(kubectl get ns -o=name | grep ${TEST_NAMESPACE} | wc -l)
[ $FOUND_NS -eq 0 ] && kubectl create namespace ${TEST_NAMESPACE}

# Apply the GCP Marketplace Application CRD
kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml" --validate=false

# Run `mpdev doctor` to diagnose and set up your environment
# mpdev /scripts/doctor.py

# Run `mpdev install` to kick off your deployer
mpdev /scripts/install --deployer="${DEPLOYER_TAG}" --parameters="{\"name\": \"${TEST_NAME}\", \"namespace\": \"${TEST_NAMESPACE}\", \"reportingSecret\": \"iweuniweubniewubn\"}"

echo "Project ${PROJECT} install complete..."
echo "You should see the project has been deployed at https://console.cloud.google.com/kubernetes/application?project=${PROJECT}"

kubectl -n $TEST_NAMESPACE get application

# Should be able to delete the deployed application my deleting the Application resource (again - NOT TESTED with GESTALT YET!)
# kubectl delete application <APPLICATION DEPLOYMENT NAME>
