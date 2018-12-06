# From https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/building-deployer-helm.md
#
# Requires the `docker` and the `gcloud` CLI pre-installed.
# You'll also want to connect to the GCP cluster. https://console.cloud.google.com/kubernetes/list?project=galacticfog-public
#
# See also the `gcloud_get_mpdev.sh` script.
# Container image with all the required tools: docker pull gcr.io/cloud-marketplace-tools/k8s/dev
#
# WARNING! I have not tested this - just pulled from the docs page above and keeping it here for future reference
#
export REGISTRY=gcr.io/$(gcloud config get-value project | tr ':' '/')
export APP_NAME=gestalt

docker build --tag $REGISTRY/$APP_NAME/deployer .
docker push $REGISTRY/$APP_NAME/deployer
