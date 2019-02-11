#!/bin/bash

# Source common project configuration and utilities
PROJECT_CHECK_FUNCTIONS='./scripts/utilities/utility-project-check.sh'
if [ -f ${PROJECT_CHECK_FUNCTIONS} ]; then
  . ${PROJECT_CHECK_FUNCTIONS}
else
  echo "[ERROR] Project initialization script '${PROJECT_CHECK_FUNCTIONS}' can not be located, aborting. "
  exit 1
fi

echo "=> Launching install Pod ..."
cmd="kubectl create -n ${RELEASE_NAMESPACE} -f ${INSTALLER_CONFIG_FILE}"
$cmd
exit_on_error "Failed install: '$cmd', aborting."

echo
echo "Gestalt Platform installer deployed to '${RELEASE_NAMESPACE}'.  To view the installer progress, run the following:"
echo
echo "  kubectl logs -n gestalt-system gestalt-installer --follow"
echo
echo "Done."
