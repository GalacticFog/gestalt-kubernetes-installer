#!/bin/bash
set -e

echo "======================================================"
echo "Pre-Build: Step 0: Initialize"
. ./utilities/utility-image-initialize.sh
echo "======================================================"
echo "Pre-Build: Step 1: Gather Dependencies Folder Contents"
if [ -d ${dependencies_folder} ]; then
  rm -r ${dependencies_folder}
  echo "Removed '${dependencies_folder}'"
fi
echo "Next: Create '${dependencies_folder}'"
mkdir -p ${dependencies_folder}
echo "Next: Gather dependencies:"
get_kubectl
get_fog_cli
get_helm
get_yaml2json
echo "======================================================"
echo "Pre-Build: Step 2: Gather Installer App Folder Contents"
if [ -d ./app/install ]; then
  rm -r ./app/install
  echo "Removed './app/install'"
fi
echo "Next: Create './app/install'"
mkdir -p ./app/install
echo "Next: Populate './app/install' with source folders:"
echo "- scripts"
cp -r ../../src/scripts ./app/install/
echo "- resource_templates"
cp -r ../../src/resource_templates ./app/install/
echo "- gestalt-helm-chart"
cp -r ../../src/gestalt-helm-chart ./app/install/
echo "Next: Create './app/install'"
[ -d ./app/install/config ] || mkdir ./app/install/config
echo "Next: Populate './app/install/config' with license and config files:"
cp -r ../../src/providers ./app/install/
echo "======================================================"
