## Generate config file install-config.json

echo "Obtaining kubeconfig from context '`kubectl config current-context`'..."

./bin/kubectl config view --raw --minify --flatten | base64 > kubeconfig.b64

source ./gestalt.conf

source ./credentials.conf

. ./scripts/build-config.sh > install-config.json

. ./scripts/build-installer-spec.sh > installer.yaml
