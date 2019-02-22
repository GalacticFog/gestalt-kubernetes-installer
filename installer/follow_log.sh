. gestalt.conf
. helpers/tool-functions.sh

RELEASE_NAMESPACE=$( find_namespace ${RELEASE_NAMESPACE} )
RELEASE_NAME=$( find_release ${RELEASE_NAME} )

kubectl logs -n ${RELEASE_NAMESPACE} ${RELEASE_NAME}-installer --follow
