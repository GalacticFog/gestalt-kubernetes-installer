# From https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/tool-prerequisites.md
#
# Docs for `mpdev` are here:
# https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/mpdev-references.md
#
# WARNING! I have not tested this - just pulled from the docs page above and keeping it here for future reference
#
docker pull gcr.io/cloud-marketplace-tools/k8s/dev

BIN_FILE="$HOME/bin/mpdev"
docker run gcr.io/cloud-marketplace-tools/k8s/dev cat /scripts/dev > "$BIN_FILE"
chmod +x "$BIN_FILE"

# Test installed `mpdev` command
mpdev
