# The first section is an intermediate image which downloads dependencies
# for the target container image down below.
#
# You can change the container image from which this one is built by passing
# the docker build command "base_tag" or "base_image" build arguments:
#
#     docker build --build-arg base_tag="latest" \
#                  --build-arg base_image="galacticfog/gestalt-installer-base:latest"" \
#
# You can test building only the builder image stage by invoking the
# docker build command with a target build stage like this:
#
#     docker build --target builder
#
ARG base_tag=testing
ARG base_image=gcr.io/galacticfog-public/gestalt-installer-base:${base_tag}
FROM ${base_image} as builder

# Make sure to update this version_lavel and keep consistent with the version tag
ARG version_label=gcp-marketplace
ENV version_label=${version_label}
ENV KUBECONFIG=/app/configure/.kubeconfig

ARG component_label=gestalt-deployer
LABEL application=gestalt
LABEL component=${component_label}
LABEL build.phase=builder
LABEL vendor="Galactic Fog IP, Inc."
LABEL com.galacticfog.version=${version_label}

WORKDIR /app/configure

COPY ./gestalt /gestalt
COPY . .

# Invoke the scripts to build configs and installer script files here.
# Any required tools should be part of the gestalt-installer-base image.
# If you need to add a new dependency that won't change often or isn't 
# different for different providers, please add it to the base image layer
# rather than the installer or installer build layer.
RUN pwd && ./configure.sh && \
    echo "--------------------------------------------------" && \
    find . -type f && \
    echo "--------------------------------------------------" && \
    echo "BUILDER RUN DONE." && \
    echo "--------------------------------------------------"

# This second section is the target container image that gets copies of the 
# configuration and script files built in the builder container above, but 
# doesn't need the tools the builder used to create those configs or scripts.
#
# The target container performs the actual work of installing Gestalt on
FROM ${base_image}

ENV KUBECONFIG=/app/deploy/.kubeconfig

ARG component_label=gestalt-deployer
LABEL application=gestalt
LABEL component=${component_label}
LABEL build.phase=target
LABEL vendor="Galactic Fog IP, Inc."
LABEL com.galacticfog.version=${version_label}

WORKDIR /app/deploy

# Copy in Kubernetes and Gestalt resource definition files from the builder stage
# COPY --from=builder ./gestalt /gestalt
# Copy in scripts and utilities in from the builder stage
COPY --from=builder /app/configure /app/deploy

RUN pwd && \
    echo "--------------------------------------------------" && \
    find /app -type f && \
    echo "--------------------------------------------------" && \
    echo "DEPLOYER BUILD DONE." && \
    echo "--------------------------------------------------"

# The entrypoint script should launch the installer scripts.
ENTRYPOINT ["/app/deploy/scripts/entrypoint.sh"]
