## This script is the entrypoint to the Gestalt Installer container

## Assume that 'installer-config.json' is present.

# Check if installer-config exists, exit with error if not

# Parse the config file usign jq to get all necessary parameters

database_password="s1lr7nOGQXmTaoaH"

admin_password="BZ2pAcpRQ0pyASMn"

# Check to ensure all required parameters are present
# - kubeconfig (in base64 encoding)
# - db username, password

# Generate helm-config.yaml

echo "Generating helm configuration..."

cat > helm-config.yaml <<EOF
security:
  adminPassword: "$admin_password"

postgresql:
  postgresPassword: "$database_password"

db:
  password: "$database_password"

installer:
  gestaltCliData: `cat kubeconfig.b64`
EOF

# Render the Kubernetes resources using helm
./bin/helm template gestalt --name gestalt -f helm-config.yaml > gestalt.yaml

# Abort if error (consider using pipefail, or detect non-zero exit code and return a specific error message)

# Deploy the core gestalt services
./bin/kubectl apply -n gestalt-system -f gestalt.yaml


# Stage 2 - Orchestrate the Gestalt Platform installation

cd ./scripts
./install-gestalt-platform.sh
