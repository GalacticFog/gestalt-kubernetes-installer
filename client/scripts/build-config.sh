#!/bin/bash

## LDAP Config

# First remove the existing file so it won't get staged
[ -f ../resource_templates/ldap-config.yaml ] && \
  rm ../resource_templates/ldap-config.yaml

if [ "$configure_ldap" == "Yes" ]; then
  echo "Will configure LDAP, copying LDAP config from ldap-config.yaml"
  cp ldap-config.yaml ../resource_templates/ldap-config.yaml
  exit_on_error "Failed to copy ldap-config.yaml"
fi

## CACERTS file

# First, delete the original file so it won't be staged
[ -f ./configmaps/cacerts ] && \
  rm ./configmaps/cacerts

# Copy the file
if [ ! -z "$gestalt_security_cacerts_file" ]; then
  cp $gestalt_security_cacerts_file ./configmaps/cacerts
  exit_on_error "Failed to copy $gestalt_security_cacerts_file"
fi