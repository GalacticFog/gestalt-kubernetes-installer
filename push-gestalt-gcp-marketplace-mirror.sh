set -e

target=https://github.com/GalacticFog/gestalt-gcp-marketplace

if [ -d gestalt-gcp-marketplace ]; then 
    echo "Mirroring to $target"
    cd gestalt-gcp-marketplace
    git push --mirror $target
else 
    echo "Can't find gestalt-gcp-marketplace directory, aborting"
fi