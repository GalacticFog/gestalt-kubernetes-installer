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
export TEST_NAME="gestalt"
export TEST_NAMESPACE="gestalt-system"

KBIN="kubectl"
KCMD="${KBIN} -n ${TEST_NAMEPSACE}"

${KCMD} delete application ${TEST_NAME}
${KCMD} delete pvc ${TEST_NAME}-postgresql

echo "Project ${PROJECT} deletion complete..."
echo "You should no longer see the project listed at https://console.cloud.google.com/kubernetes/application?project=${PROJECT}"

${KCMD} get application,all

${KCMD} get pv,pvc

${KBIN} delete ns ${TEST_NAMESPACE}
