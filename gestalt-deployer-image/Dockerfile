FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm/onbuild:latest

COPY marketplace-k8s-app-tools/scripts /scripts
COPY chart /chart
COPY schema.yaml /data/schema.yaml
# COPY chart/gestalt/values.yaml /data/values.yaml
# RUN mkdir -p /data/values
