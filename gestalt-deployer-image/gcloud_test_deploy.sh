# Set the registry to your project GCR repo.
export PROJECT=$(gcloud config get-value project | tr ':' '/')
export REGISTRY=gcr.io/${PROJECT}
export APP_NAME=gestalt

kubectl create namespace test-ns

mpdev /scripts/install \
  --deployer=$REGISTRY/$APP_NAME/deployer \
  --parameters='{"name": "test-deployment", "namespace": "test-ns"}'

echo "You should see the project has been deployed at https://console.cloud.google.com/kubernetes/application?project=${PROJECT}"
