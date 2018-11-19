# The first section is an intermediate image which downloads dependencies
# for the target container image down below.
#
# You can specify exact versions of the kubectl, helm and fog CLI tools
# to include in the base gestalt-installer image you're building via the 
# "kubectl_version", "helm_version" and "fog_version" build arguments 
# like this:
#
#     docker build --build-arg fog_version="0.9.2" \
#                  --build-arg kubectl_version="v1.12.1" \
#                  --build-arg helm_version="v2.10.0-rc.3"
#
# You can test building only the builder image stage by invoking the
# docker build command with a target build stage like this:
#
#     docker build --target builder
#
ARG base_tag=alpine
ARG base_image=nginx:${base_tag}
FROM ${base_image} as builder

ARG version_label=SNAPSHOT
ENV version_label=${version_label}

ARG component_label=gestalt-installer-base
LABEL application=gestalt
LABEL component=${component_label}
LABEL build.phase=builder
LABEL vendor="Galactic Fog IP, Inc."
LABEL com.galacticfog.version=${version_label}

WORKDIR /app
COPY . /app

ARG fog_version
ARG helm_version
ARG kubectl_version
ENV BUILD_DEPS="gettext"  \
    RUNTIME_DEPS="libintl" \
    fog_version=${fog_version:-0.10.2} \
    helm_version=${helm_version:-latest} \
    kubectl_version=${kubectl_version:-latest}

# TODO: the builder container probably doesn't need all these packages, but
#       when I tried to use process-of-elimination to reduce them, things 
#       broke and I ran out of time.  Circle back and reduce when you have time.
#
# Add dependent packages
RUN apk upgrade --no-cache && \
    apk add --update $RUNTIME_DEPS && \
    apk add --virtual build_deps $BUILD_DEPS &&  \
    cp /usr/bin/envsubst /usr/local/bin/envsubst && \
    apk del build_deps && \
    apk add --update \
    build-base \
    bash \
    curl \
    jq \
    postgresql-client \
    python \
    py-pip \
    ca-certificates && \
    pip install --upgrade pip && \
    pip install httpie httpie-unixsocket && \
    rm -rf /var/cache/apk/* && \
    ./download_cli_tools.sh \
        -f ${fog_version} \
        -l ${helm_version} \
        -k ${kubectl_version}

# This second section is the target container image that gets a copy of the
# kubectl, helm and fog CLI tools from the builder container, but doesn't
# need the rest of their distro packages.
FROM ${base_image}

ARG component_label=gestalt-installer-base
LABEL application=gestalt
LABEL component=${component_label}
LABEL build.phase=target
LABEL vendor="Galactic Fog IP, Inc."
LABEL com.galacticfog.version="1.0-SNAPSHOT" 

ENV BUILD_DEPS="gettext"  \
    RUNTIME_DEPS="libintl"

COPY --from=builder /app/kubectl /usr/local/bin
COPY --from=builder /app/helm /usr/local/bin
COPY --from=builder /app/fog /usr/local/bin

# Add dependent packages
RUN apk upgrade --no-cache && \
    apk add --update $RUNTIME_DEPS && \
    apk add --virtual build_deps $BUILD_DEPS &&  \
    cp /usr/bin/envsubst /usr/local/bin/envsubst && \
    apk del build_deps && \
    apk add --update \
    build-base \
    bash \
    curl \
    jq \
    postgresql-client \
    python \
    py-pip \
    ca-certificates && \
    pip install --upgrade pip && \
    pip install httpie httpie-unixsocket && \
    rm -rf /var/cache/apk/* && \
    kubectl version --client && \
    helm version -c && \
    fog --version
