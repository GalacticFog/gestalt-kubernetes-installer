# Set the registry to your project GCR repo.
export REGISTRY=gcr.io/$(gcloud config get-value project | tr ':' '/')
export APP_NAME=gestalt

docker build --tag $REGISTRY/$APP_NAME/deployer .
docker push $REGISTRY/$APP_NAME/deployer
