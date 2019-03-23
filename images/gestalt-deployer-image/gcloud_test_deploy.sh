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
export REGISTRY="gcr.io/${PROJECT}/gestalt"
echo "REGISTRY: ${REGISTRY}"
export IMAGE_TAG="test"
export DEPLOYER_IMAGE="$REGISTRY/deployer:${IMAGE_TAG}"

export ADMIN_USER="gcpadmin"
export ADMIN_PASS="gcpG35t@lt1n5t@ll"
export TEST_NAME="gcptest"
export TEST_NAMESPACE="gcptest-system"
export INSTALLER_TAG="${IMAGE_TAG}"
export INSTALLER_IMAGE="${REGISTRY}/gestalt-installer:${INSTALLER_TAG}"
export EULA_NAME="Galactic Fog"
export EULA_EMAIL="example@galacticfog.com"
export EULA_COMPANY="Galactic Fog, LLC"
export INSTALL_DOMAIN="yourdomain.com"
export UI_HOSTNAME="portal.${INSTALL_DOMAIN}"
export UI_STATIC_IP="35.245.210.40"
export API_HOSTNAME="api.${INSTALL_DOMAIN}"
export API_STATIC_IP="35.245.250.210"
export PROVISION_DB="true"
export DB_HOST="35.221.1.43"
export DB_PORT="5432"
export DB_NAME="postgres"
export DB_USERNAME="postgres"
export DB_PASSWORD="9mfwC8dI6Axyf4qz"

# Create the test namespace if it doesn't already exist
create_ns() {
  local NS_NAME=$1
  echo "Creating namespace '$TEST_NAMESPACE'..."
  kubectl create namespace $NS_NAME
}

create_namespace() {
  echo "Checking for existing Kubernetes namespace '$TEST_NAMESPACE'..."
  kubectl get namespace $TEST_NAMESPACE > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    create_ns "$TEST_NAMESPACE"

    # Wait for namespace to be created
    sleep 5
    echo "Namespace $TEST_NAMESPACE created."
  fi
}

create_namespace $TEST_NAMESPACE

kubectl create secret generic iweuniweubniewubn --from-literal=entitlement-id=test-entitlement-id --from-literal=consumer-id=project:test-consumer-id --from-literal=reporting-key=ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsCiAgInByb2plY3RfaWQiOiAiZ2FsYWN0aWNmb2ctcHVibGljIiwKICAicHJpdmF0ZV9rZXlfaWQiOiAiZjczMzk2ZDgzZWY1MDkyOTVjNGNmZWQ3MGUxZDBhNDg3MGVhYTk1OCIsCiAgInByaXZhdGVfa2V5IjogIi0tLS0tQkVHSU4gUFJJVkFURSBLRVktLS0tLVxuTUlJRXZBSUJBREFOQmdrcWhraUc5dzBCQVFFRkFBU0NCS1l3Z2dTaUFnRUFBb0lCQVFDL3ZRUjZ0dGN1SWYzUVxuYWlWVnRoNEV4QWZKZEVkdGp1M1Y4cFZVUG5wSGtmNnBQWkF1S2x5RVBDWVdGaEJEcGpQOEtIVHVEWmVFeVhDY1xuYXI1Z0xpQU1RMU14V0lmaFFnVmJjdHU0UmZ4SVZjV1JXVjdxYnZZUlFsWWloZVJxcEo2M0UzTnprWTlMUkdGbFxubmdiVzFjNGdPMGVLT2lmbHpobEpkRVUwREpBa2c4VklLaDhUYkpHdWRyMXUwUS9UY2pBbFVvSFpHU01KTEppV1xuMXNtdXpNM29YYytxeUo4aFBwZzk3cExqRGVxOGRDY2FLZVQ2Z3pYNG9PQ0NwWXJ1eHNabTJyOG8vUk93VUdCUFxuRm1aVW1EbldOOE1Zd1dkWXF0MUNMQlZ5QzJFTTNsZk93NXhUeUYra3RCT0xIS2kyZThwWnBJQ1NabGNVZGRLdVxuSUdCL3NUZnBBZ01CQUFFQ2dnRUFDQlNTRVVGMHdFQ3BFZlR5YW5JeVFkMWIxOW9VaTFVaysyTWczVldFVVI0SVxuRW9ZQjlqVG5CRHBzVEJQSWp4WVdIOE01NlgzMjhqaU1QM211OG1yb3o5aEtHaVpmcmYxME1DUzR1WkE5ZktkUFxuNk9HMnoyYWRoZXpoUWMwQUhtazMwZWhUcElwOUo4TmdlSnRZTVFxWU80ZTBCRGZGYUJKaWoyMXByTXlRdlZlSVxuWGtKckpqRXB1cXRybmxiQXpmaThuNTFVRVBRd2s2RmR4dEpkdExaN3hCaTVWOEgwZGt2VEFKWnRCVnNuQWJlZlxubGxyeU1pcnB5UDJ6MFlhTnhHK1FHU2JUNklmOXk1QnZid1ZkOTFERXdVK0tmWjBVNUtOSWphK2dOcHdLbzVSd1xuYzI0MkhlMjE1Rm95ME5kZFFLZk13OFRxWlgwVTExVEc0RHZsZjQwZFp3S0JnUUR0c1kzOHFMT3psYUdqWk0wdlxuUDJTWGRDMWVNNHQyellBZnBnUkEraWRNWUlibGd0Z0YwZFFEL2gzbXFENVhzMUx0cnN0bjZ1K3VqMjJ4bHFHWFxuR3dLRXdsS2tCUWN3Wk5McWtsZ2JsYWVRZkx5OStNeENaMUh6SGpubWJQU2tRcnlJMFpTcUE1QXpma1p2VTQ0ZFxubHhoZ2lYVFhGeVoxbUtPQlNEbWsyTncrWHdLQmdRRE9nV1Q1VTVYcjZmM2VKL0FqdXRTb1ZVLzkxTFZ6MGZtOFxuN2dkS1hVdnV1SmhrU1N0YVpadUhXdU1nWStsM1VLQy9HNS84MTMwanRFQ0ZQY241d3FUZVZWOUZSWlJCVjVMeVxuRTFESHVKMk1uaHZETjZJVmwyNWRKTHhlTnRsUkVxQjFBaTdQOTlQdmorM0FRdUttbUJNcmZkQ0hSTzBVQnJtUFxuVXJlUngzNmV0d0tCZ0NOMHlPbFhnUGJZNnpPa1piY1dqYnJKNmJxVGxjb3kvVm03T2djM1NZVnJJTFE3d0YyZFxuM3pKNVJaeVNuRG9ZMWRYK3JQampZcjEzUjdXbDhwVEh3cWhyRkVqRE56OVF5dVdTenZIT2NTQnNldnNia2R5VlxuN1BPSEhydndwTTJiNXVQQjM1czh6Tlhoa0VBckJwZ0RZZStFa1psRUtzaC83R1Bza2l5MDdLV2hBb0dBZklSZlxuTzB1Z1FjRTA5NmpEVHZnUDFIU2txQnlEVVJRU2IwNWpqUDZXazVveElYOVJLYy9NcVNBdmhjOVk3ajNxdjNGTFxuMWV5bG8wckVBTk9TSHd5ejF2QkpZdjZpZDRmenJnM2hqcHdPTzhUMlhvOEVKOXJJakZkalViZm03OUM0ZWZWWFxuL3NTandYYmEyQ3c4ZUZHSWRaZ0dqaG9NamgvRDhkemhuWUJhSkI4Q2dZQXZmMk9BejZRZU5EclI1aEQ1c2V2a1xuQVVqMDhZUU1wMUpheXZQVW9TWnlnNGxvUFlzc0U2WlNPc1lvNVpucTdTU2xxaHhoSnJxQkxqKzVSY1R5TnpWNVxudDRqWWlaMGd5UWJJeUt6YzBIQ1Z0QmIvb3A2dFdjdFpod2tRQjBpMVVLcTRXNVF4a1NNdjRkOEF0SFdWR2YvK1xuQm1PSGJLT3pxbGpsQjNsWHdXWTZZZz09XG4tLS0tLUVORCBQUklWQVRFIEtFWS0tLS0tXG4iLAogICJjbGllbnRfZW1haWwiOiAidWJiLWFnZW50QGdhbGFjdGljZm9nLXB1YmxpYy5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbSIsCiAgImNsaWVudF9pZCI6ICIxMDA5MTMzNDU2OTIyODIyNDMxMDUiLAogICJhdXRoX3VyaSI6ICJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20vby9vYXV0aDIvYXV0aCIsCiAgInRva2VuX3VyaSI6ICJodHRwczovL29hdXRoMi5nb29nbGVhcGlzLmNvbS90b2tlbiIsCiAgImF1dGhfcHJvdmlkZXJfeDUwOV9jZXJ0X3VybCI6ICJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9vYXV0aDIvdjEvY2VydHMiLAogICJjbGllbnRfeDUwOV9jZXJ0X3VybCI6ICJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9yb2JvdC92MS9tZXRhZGF0YS94NTA5L3ViYi1hZ2VudCU0MGdhbGFjdGljZm9nLXB1YmxpYy5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbSIKfQo= -n ${TEST_NAMESPACE}

# Apply the GCP Marketplace Application CRD
kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml" --validate=false

# Run `mpdev doctor` to diagnose and set up your environment
# mpdev /scripts/doctor.py

# Run `mpdev install` to kick off your deployer
mpdev /scripts/install --deployer="${DEPLOYER_IMAGE}" \
--parameters="{\"name\": \"${TEST_NAME}\", \
 \"namespace\": \"${TEST_NAMESPACE}\", \
 \"reportingSecret\": \"iweuniweubniewubn\", \
 \"meta.image\": \"gcr.io/galacticfog-public/gestalt/gestalt-meta:test\", \
 \"laser.image\": \"gcr.io/galacticfog-public/gestalt/gestalt-laser:test\", \
 \"common.name\": \"${EULA_NAME}\", \
 \"common.email\": \"${EULA_EMAIL}\", \
 \"common.companyName\": \"${EULA_COMPANY}\", \
 \"installer.image\": \"${INSTALLER_IMAGE}\", \
 \"ui.ingress.host\": \"${UI_HOSTNAME}\", \
 \"ui.ingress.staticIP\": \"${UI_STATIC_IP}\", \
 \"api.gateway.host\": \"${API_HOSTNAME}\", \
 \"api.gateway.staticIP\": \"${API_STATIC_IP}\", \
 \"secrets.adminUser\": \"${ADMIN_USER}\", \
 \"secrets.adminPassword\": \"${ADMIN_PASS}\", \
 \"postgresql.provisionInstance\": ${PROVISION_DB}, \
 \"db.host\": \"${DB_HOST}\", \
 \"db.port\": \"${DB_PORT}\", \
 \"db.name\": \"${DB_NAME}\", \
 \"db.username\": \"${DB_USERNAME}\", \
 \"db.password\": \"${DB_PASSWORD}\"}"

echo "Project ${PROJECT} install complete..."
echo "You should see the project has been deployed at https://console.cloud.google.com/kubernetes/application?project=${PROJECT}"

kubectl -n $TEST_NAMESPACE get application

# Should be able to delete the deployed application my deleting the Application resource (again - NOT TESTED with GESTALT YET!)
# kubectl delete application <APPLICATION DEPLOYMENT NAME>
