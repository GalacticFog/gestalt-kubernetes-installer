## What the installer does

* Creates a `gestalt-system` namespace, and `ClusterRoleBinding` for `gestalt-system\default` to the `cluster-admin` role.
* Creates an installer ConfigMap and runs the Gestalt installer Pod in the `gestalt-system` namespace.
* The installer Pod deploys Gestalt Platform and default Gestalt Platform provider services (Gestalt LASER, Gestalt Policy, Kong API Gateway, etc).
