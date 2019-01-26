
echo "Cleaning up..."
[ -d gestalt-gcp-marketplace ] && rm -rf gestalt-gcp-marketplace

echo "Cloning repo..."
git clone https://github.com/GalacticFog/gestalt-gcp-marketplace

echo "Clearning out repo contents..."
rm -rf gestalt-gcp-marketplace/*

echo "Populating repo"
cp -r GCP-Install-Guide.md LICENSE.txt images src functional_tests gestalt-gcp-marketplace/

echo "Done."

echo "To review changes and publish:"
echo
echo "  cd gestalt-gcp-marketplace"
echo "  git status"
echo "  git diff"
echo "  git add ."
echo "  git commit -m \"Update on \`date\`\""
echo "  git push"
echo
