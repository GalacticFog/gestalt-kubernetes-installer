# Kubernetes CLI

[Obtain and Setup kubectl binary]: https://docs.docker.com/ee/ucp/user-access/kubectl/#install-the-kubectl-binary
Based on article we will package for Linux in ./client/bin/

```sh
# Set the Kubernetes version as found in the UCP Dashboard or API
k8sversion=v1.8.11
# Get the kubectl binary.
curl -LO https://storage.googleapis.com/kubernetes-release/release/$k8sversion/bin/linux/amd64/kubectl
# Make the kubectl binary executable.
chmod +x ./kubectl
```


