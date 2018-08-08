
# Check that the generated files exist, otherwise abort (User should have run ./configure.sh first)

# Check that the `gestalt-system` namespace exists.  If not, print some commands to create it

# Create a configmap with the generated install config
kubectl create configmap -n gestalt-system installer-config --from-file install-config.json

# Optionally, create a config map from the sample resource files
# TODO

# Run the install container with ConfigMaps
kubectl apply -n gestalt-system -f installer.yaml
