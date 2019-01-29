set -e

echo "Cleaning up..."
[ -d gestalt-gcp-marketplace ] && rm -rf gestalt-gcp-marketplace

echo "Initializing Repo"
git init gestalt-gcp-marketplace

echo "Populating repo"
cp -r GCP-Install-Guide.md LICENSE.txt images src functional_tests .gitignore gestalt-gcp-marketplace/

echo "Committing ..."
cd gestalt-gcp-marketplace
git add .
git commit -m "Updated `date`"

echo "Next, run ./push-gestalt-gcp-marketplace-mirror.sh"