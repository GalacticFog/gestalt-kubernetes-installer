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

kubectl create secret generic iweuniweubniewubn --from-literal=entitlement-id=test-entitlement-id --from-literal=consumer-id=project:test-consumer-id --from-literal=reporting-key=ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsCiAgInByb2plY3RfaWQiOiAiZ2FsYWN0aWNmb2ctcHVibGljIiwKICAicHJpdmF0ZV9rZXlfaWQiOiAiZjczMzk2ZDgzZWY1MDkyOTVjNGNmZWQ3MGUxZDBhNDg3MGVhYTk1OCIsCiAgInByaXZhdGVfa2V5IjogIi0tLS0tQkVHSU4gUFJJVkFURSBLRVktLS0tLVxuTUlJRXZBSUJBREFOQmdrcWhraUc5dzBCQVFFRkFBU0NCS1l3Z2dTaUFnRUFBb0lCQVFDL3ZRUjZ0dGN1SWYzUVxuYWlWVnRoNEV4QWZKZEVkdGp1M1Y4cFZVUG5wSGtmNnBQWkF1S2x5RVBDWVdGaEJEcGpQOEtIVHVEWmVFeVhDY1xuYXI1Z0xpQU1RMU14V0lmaFFnVmJjdHU0UmZ4SVZjV1JXVjdxYnZZUlFsWWloZVJxcEo2M0UzTnprWTlMUkdGbFxubmdiVzFjNGdPMGVLT2lmbHpobEpkRVUwREpBa2c4VklLaDhUYkpHdWRyMXUwUS9UY2pBbFVvSFpHU01KTEppV1xuMXNtdXpNM29YYytxeUo4aFBwZzk3cExqRGVxOGRDY2FLZVQ2Z3pYNG9PQ0NwWXJ1eHNabTJyOG8vUk93VUdCUFxuRm1aVW1EbldOOE1Zd1dkWXF0MUNMQlZ5QzJFTTNsZk93NXhUeUYra3RCT0xIS2kyZThwWnBJQ1NabGNVZGRLdVxuSUdCL3NUZnBBZ01CQUFFQ2dnRUFDQlNTRVVGMHdFQ3BFZlR5YW5JeVFkMWIxOW9VaTFVaysyTWczVldFVVI0SVxuRW9ZQjlqVG5CRHBzVEJQSWp4WVdIOE01NlgzMjhqaU1QM211OG1yb3o5aEtHaVpmcmYxME1DUzR1WkE5ZktkUFxuNk9HMnoyYWRoZXpoUWMwQUhtazMwZWhUcElwOUo4TmdlSnRZTVFxWU80ZTBCRGZGYUJKaWoyMXByTXlRdlZlSVxuWGtKckpqRXB1cXRybmxiQXpmaThuNTFVRVBRd2s2RmR4dEpkdExaN3hCaTVWOEgwZGt2VEFKWnRCVnNuQWJlZlxubGxyeU1pcnB5UDJ6MFlhTnhHK1FHU2JUNklmOXk1QnZid1ZkOTFERXdVK0tmWjBVNUtOSWphK2dOcHdLbzVSd1xuYzI0MkhlMjE1Rm95ME5kZFFLZk13OFRxWlgwVTExVEc0RHZsZjQwZFp3S0JnUUR0c1kzOHFMT3psYUdqWk0wdlxuUDJTWGRDMWVNNHQyellBZnBnUkEraWRNWUlibGd0Z0YwZFFEL2gzbXFENVhzMUx0cnN0bjZ1K3VqMjJ4bHFHWFxuR3dLRXdsS2tCUWN3Wk5McWtsZ2JsYWVRZkx5OStNeENaMUh6SGpubWJQU2tRcnlJMFpTcUE1QXpma1p2VTQ0ZFxubHhoZ2lYVFhGeVoxbUtPQlNEbWsyTncrWHdLQmdRRE9nV1Q1VTVYcjZmM2VKL0FqdXRTb1ZVLzkxTFZ6MGZtOFxuN2dkS1hVdnV1SmhrU1N0YVpadUhXdU1nWStsM1VLQy9HNS84MTMwanRFQ0ZQY241d3FUZVZWOUZSWlJCVjVMeVxuRTFESHVKMk1uaHZETjZJVmwyNWRKTHhlTnRsUkVxQjFBaTdQOTlQdmorM0FRdUttbUJNcmZkQ0hSTzBVQnJtUFxuVXJlUngzNmV0d0tCZ0NOMHlPbFhnUGJZNnpPa1piY1dqYnJKNmJxVGxjb3kvVm03T2djM1NZVnJJTFE3d0YyZFxuM3pKNVJaeVNuRG9ZMWRYK3JQampZcjEzUjdXbDhwVEh3cWhyRkVqRE56OVF5dVdTenZIT2NTQnNldnNia2R5VlxuN1BPSEhydndwTTJiNXVQQjM1czh6Tlhoa0VBckJwZ0RZZStFa1psRUtzaC83R1Bza2l5MDdLV2hBb0dBZklSZlxuTzB1Z1FjRTA5NmpEVHZnUDFIU2txQnlEVVJRU2IwNWpqUDZXazVveElYOVJLYy9NcVNBdmhjOVk3ajNxdjNGTFxuMWV5bG8wckVBTk9TSHd5ejF2QkpZdjZpZDRmenJnM2hqcHdPTzhUMlhvOEVKOXJJakZkalViZm03OUM0ZWZWWFxuL3NTandYYmEyQ3c4ZUZHSWRaZ0dqaG9NamgvRDhkemhuWUJhSkI4Q2dZQXZmMk9BejZRZU5EclI1aEQ1c2V2a1xuQVVqMDhZUU1wMUpheXZQVW9TWnlnNGxvUFlzc0U2WlNPc1lvNVpucTdTU2xxaHhoSnJxQkxqKzVSY1R5TnpWNVxudDRqWWlaMGd5UWJJeUt6YzBIQ1Z0QmIvb3A2dFdjdFpod2tRQjBpMVVLcTRXNVF4a1NNdjRkOEF0SFdWR2YvK1xuQm1PSGJLT3pxbGpsQjNsWHdXWTZZZz09XG4tLS0tLUVORCBQUklWQVRFIEtFWS0tLS0tXG4iLAogICJjbGllbnRfZW1haWwiOiAidWJiLWFnZW50QGdhbGFjdGljZm9nLXB1YmxpYy5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbSIsCiAgImNsaWVudF9pZCI6ICIxMDA5MTMzNDU2OTIyODIyNDMxMDUiLAogICJhdXRoX3VyaSI6ICJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20vby9vYXV0aDIvYXV0aCIsCiAgInRva2VuX3VyaSI6ICJodHRwczovL29hdXRoMi5nb29nbGVhcGlzLmNvbS90b2tlbiIsCiAgImF1dGhfcHJvdmlkZXJfeDUwOV9jZXJ0X3VybCI6ICJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9vYXV0aDIvdjEvY2VydHMiLAogICJjbGllbnRfeDUwOV9jZXJ0X3VybCI6ICJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9yb2JvdC92MS9tZXRhZGF0YS94NTA5L3ViYi1hZ2VudCU0MGdhbGFjdGljZm9nLXB1YmxpYy5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbSIKfQo= -n gestalt-system

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
