# Installing Gestalt Platform on Kubernetes

Installer repository: [https://github.com/GalacticFog/gestalt-kubernetes-installer](https://github.com/GalacticFog/gestalt-kubernetes-installer)

## Prerequisites

* Kuberntes System requirements:
  - CPUs:   1 required, 2 recommended
  - Memory: 7.5 GiB required, 12 GiB recommended
  - Storage: Kubernetes Volume support or an external PostgreSQL database
  - "Cluster-Admin" access required
* A workstation for running the installer running Mac OS or Linux
* For Hosted installations (EKS, GKE, Azure, Digital Ocean, On-Prem):
  - DNS and Load Balancer / Ingress for Gestalt Portal
  - DNS and Load Balancer / Ingress for Kong API Gateway

## Google Marketplace Installation

Gestalt Platform can be installed on GKE via Google Marketplace.  See the [**GCP Installation Guide**](https://github.com/GalacticFog/gestalt-gcp-marketplace/blob/master/GCP-Install-Guide.md) for details.


## Installation for Local environments (Docker Desktop, Minikube)

Perform the following to install Gestalt Platform to your Kubernetes cluster:
```sh
kubectl config use-context <desired context>    # Change to the desired kubernetes context

git clone https://github.com/GalacticFog/gestalt-kubernetes-installer

cd gestalt-kubernetes-installer/installer

vi credentials.yaml               # Modify Gestalt 'admin' user credentials

./install-gestalt-platform        # Run the installation and follow the on-screen prompts
```

## Installation for Hosted installations (that require DNS)

This applies to AWS/EKS, GKE, AKS, or any environment requiring DNS to access Kubernetes cluster services.  

### Step 1 - Infrastructure Setup

Note that two services (Gestalt Portal, Kong API Gateway) need to be exposed externally on the Kubernetes cluster using either a Load Balancer / Ingress solution, or using NodePorts.  DNS is typically required for Load Balancers / Ingress.


### Step 2 - Configure and Run the Installer
```sh
cd installer


# Step 1 - Create a Profile directory for your enviornment. For example, name the profile 'my-target-cluster'

cp -r profiles/custom profiles/my-target-cluster


# Step 2 - Edit the profile config file with your intended DNS settings:

vi profiles/my-target-cluster/config.yaml

    Change the following to match intended DNS settings:

         GESTALT_URL:    https://portal.yourdomain.com
         KONG_URL:       https://api1.yourdomain.com


# Step 3 - Run the installer with the profile

./install-gestalt-platform my-target-cluster

```

## Additional installation instructions

Refer to the installation instructions appropriate for your environment:

- [Setup notes for Minikube](./docs/readme_minikube.md)


## Additional resources

 - [Gestalt Platform Documentation](http://docs.galacticfog.com)

 - [Galactic Fog Website](http://www.galacticfog.com)
