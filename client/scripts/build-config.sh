#!/bin/bash

## CACERTS file

# First, delete the original file so it won't be staged
[ -f ./configmaps/cacerts ] && \
  rm ./configmaps/cacerts

# Copy the file
if [ ! -z "$gestalt_security_cacerts_file" ]; then
  echo "Copying $gestalt_security_cacerts_file to ./stage/cacerts ..."
  cp $gestalt_security_cacerts_file ./stage/cacerts
  exit_on_error "Failed to copy $gestalt_security_cacerts_file"
fi