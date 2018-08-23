#!/bin/bash

############################################
# Dependencies
############################################

# Needs ./utilities/utility-bash.sh

############################################
# Index
############################################

# 






############################################
# START
############################################

helm_download_for_target() {

  [[ $# -ne 3 ]] && echo \ 
    && echo "Function '${FUNCNAME[0]}' expects 3 parameters: 'version' 'consumer_os' 'target_folder' " \
    && echo \ 
    && echo "Only $# provided: [$@]" \
    && exit_with_error "Function '${FUNCNAME[0]}' expects 3 parameters, aborting."

  f_version=$1
  f_target_os=$2
  f_target_location=$3

  echo "yyy"

helm_os="linux"
helm_version="2.9.1"
url="https://storage.googleapis.com/kubernetes-helm/helm-v$helm_version-$helm_os-amd64.tar.gz"
curl -L $url -o helm.tar.gz
tar xfzv helm.tar.gz
cp linux-amd64/helm /bin/
chmod +x /bin/helm

echo "yyyyyyy2222"


}



  # echo "Checking for existing Kubernetes namespace '$install_namespace'..."
  kubectl get namespace ${f_namespace_name} > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo ""
    echo "Kubernetes namespace '${f_namespace_name}' doesn't exist, aborting.  To create the namespace, run the following command:"
    echo ""
    echo "  kubectl create namespace ${f_namespace_name}"
    echo ""
    echo "Then ensure that 'Full Control' grants are provided for the '${f_namespace_name}/default' service account."
    echo ""
    exit_with_error "Kubernetes namespace '${f_namespace_name}' doesn't exist, aborting."
  fi
  echo "OK - Kubernetes namespace '${f_namespace_name}' is present."
}




check_for_required_namespace() {

  [[ $# -ne 1 ]] && echo && exit_with_error "Function '${FUNCNAME[0]}' expects 1 parameter ($# provided) [$@], aborting."
  f_namespace_name=$1

  # echo "Checking for existing Kubernetes namespace '$install_namespace'..."
  kubectl get namespace ${f_namespace_name} > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo ""
    echo "Kubernetes namespace '${f_namespace_name}' doesn't exist, aborting.  To create the namespace, run the following command:"
    echo ""
    echo "  kubectl create namespace ${f_namespace_name}"
    echo ""
    echo "Then ensure that 'Full Control' grants are provided for the '${f_namespace_name}/default' service account."
    echo ""
    exit_with_error "Kubernetes namespace '${f_namespace_name}' doesn't exist, aborting."
  fi
  echo "OK - Kubernetes namespace '${f_namespace_name}' is present."
}



kubectl_os


helm_version="2.9.1"
helm_download_url='https://storage.googleapis.com/kubernetes-helm/helm-v$helm_version-$helm_os-amd64.tar.gz'

curl -s https://github.com/helm/helm/releases/latest | awk -F '"' '{print $2}' | awk -F'/v' '{print $NF}'
2.9.1


kubectl_version="stable"
kubectl_version_url_latest="https://storage.googleapis.com/kubernetes-release/release/latest.txt"
kubectl_version_url_stable="https://storage.googleapis.com/kubernetes-release/release/stable.txt"
kubectl_download_url='https://storage.googleapis.com/kubernetes-release/release/${kubectl_version}/bin/linux/amd64/kubectl'



https://storage.googleapis.com/kubernetes-helm/release/stable.txt





get_kubectl() {
  kube_version=`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`
  kube_url=https://storage.googleapis.com/kubernetes-release/release/${kube_version}/bin/linux/amd64/kubectl

  # Get Kubectl
  if [ ! -f ./deps/kubectl ]; then
    echo "Getting kubectl from $kube_url..."
    curl -L $kube_url -o ./deps/kubectl
    exit_on_error "Failed to get kubectl, aborting."
  else
    echo "OK - kubectl already present, skipping"
  fi
}


helm


download_helm() {
    echo "Checking for 'helm'"

    if [ ! -f ./helm ]; then
        local os=`uname`

        if [ "$os" == "Darwin" ]; then
            local helm_os="darwin"
        elif [ "$os" == "Linux" ]; then
            local helm_os="linux"
        else
            echo
            echo "Warning: unknown OS type '$os', treating as Linux"
            local helm_os="linux"
        fi

        local helm_version="2.9.1"

        local url="https://storage.googleapis.com/kubernetes-helm/helm-v$helm_version-$helm_os-amd64.tar.gz"

        if [ ! -z "$url" ]; then
            echo
            echo "Downloading helm version $helm_version..."

            curl -L $url -o helm.tar.gz
            exit_on_error "Failed to download helm, aborting."

            echo
            echo "Extracting..."

            tar xfzv helm.tar.gz
            exit_on_error "Failed to unzip helm package, aborting."

            if [ "$os" == "Darwin" ]; then
                cp darwin-amd64/helm .
                rm -r darwin-amd64
            elif [ "$os" == "Linux" ]; then
                cp linux-amd64/helm .
                rm -r linux-amd64
            else
                echo
                echo "Warning: unknown OS type '$os', treating as Linux"
                cp linux-amd64/helm .
            fi
            chmod +x ./helm
            helm="./helm"

            rm helm.tar.gz
        fi
    else
      helm=./helm
    fi


    echo "OK - $helm present."
}


############################################
# END
############################################