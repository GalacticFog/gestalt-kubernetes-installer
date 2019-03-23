#!/bin/bash

############################################
# Dependencies
############################################

# Needs ./utilities/utility-bash.sh
# Needs ./utilities/utility-image-initialize.sh

############################################
# Index
############################################

get_kubectl() {

  if [ ! -f ${dependencies_folder}/kubectl ]; then
    echo "Getting kubectl from '${kubectl_download_url}'"
    curl -sL ${kubectl_download_url} -o ${dependencies_folder}/kubectl
    exit_on_error "Failed to get kubectl from '${kubectl_download_url}' to '${dependencies_folder}', aborting."
    chmod +x ${dependencies_folder}/kubectl
    exit_on_error "Failed to make kubectl executable '${dependencies_folder}/kubectl', aborting."   
    echo "kubectl_version=${kubectl_version}" >> "${dependencies_folder}/versions.txt"
  else
    log_info "OK - 'kubectl' already present, skipping"
  fi
}

get_fog_cli() {

  if [ ! -f ${dependencies_folder}/fog ]; then
    
    echo "Getting fog from '${fog_download_url}'"
    curl -sL ${fog_download_url} -o ${dependencies_folder}/fog.zip
    exit_on_error "Failed to get fog cli from '${kubectl_download_url}' to '${dependencies_folder}', aborting."
    cd ${dependencies_folder}
    exit_on_error "Failed to navigate to '${dependencies_folder}', aborting."
    unzip -qq fog.zip
    exit_on_error "Failed to extract fog cli zip, aborting."
    rm fog.zip
    exit_on_error "Failed to cleanup fog cli zip, aborting."    
    cd ~-
    exit_on_error "Failed to navigate back to main folder, aborting."
    chmod +x ${dependencies_folder}/fog
    exit_on_error "Failed to make fog cli executable '${dependencies_folder}/fog', aborting."
    echo "fog_version=${fog_version}" >> "${dependencies_folder}/versions.txt"

  else
    log_info "OK - 'fog' already present, skipping"
  fi
}

get_helm() {

  if [ ! -f ${dependencies_folder}/helm ]; then
    
    echo "Getting helm from '${helm_download_url}'"
    curl -sL ${helm_download_url} -o ${dependencies_folder}/helm.tar.gz
    exit_on_error "Failed to get helm from '${helm_download_url}' to '${dependencies_folder}', aborting."
    tar xfz ${dependencies_folder}/helm.tar.gz -C ${dependencies_folder} --strip-components 1 --exclude=README.md --exclude=LICENSE
    exit_on_error "Failed to extract helm archive', aborting."
    rm ${dependencies_folder}/helm.tar.gz
    exit_on_error "Failed to cleanup helm archive, aborting."  
    chmod +x ${dependencies_folder}/helm
    exit_on_error "Failed to make helm executable '${dependencies_folder}/helm', aborting."
    echo "helm_version=${helm_version}" >> "${dependencies_folder}/versions.txt"

  else
    log_info "OK - 'helm' already present, skipping"
  fi

}

get_yaml2json() {

  if [ ! -f ${dependencies_folder}/yaml2json ]; then
    echo "Getting yaml2json from '${source_yaml2json}'"
    cp ${source_yaml2json} ${dependencies_folder}/yaml2json
    exit_on_error "Failed to get yaml2json from '${sources_folder}/yaml2json' to '${dependencies_folder}', aborting." 
    chmod +x ${dependencies_folder}/yaml2json
  else
    log_info "OK - 'yaml2json' already present, skipping"
  fi
  
}

get_jinja2format() {

  if [ ! -f ${dependencies_folder}/jinja2format ]; then
    echo "Getting jinja2format from '${source_jinja2format}'"
    cp ${source_jinja2format} ${dependencies_folder}/jinja2format
    exit_on_error "Failed to get jinja2format from '${sources_folder}/jinja2format' to '${dependencies_folder}', aborting." 
    chmod +x ${dependencies_folder}/jinja2format
  else
    log_info "OK - 'jinja2format' already present, skipping"
  fi
  
}

############################################
# END
############################################