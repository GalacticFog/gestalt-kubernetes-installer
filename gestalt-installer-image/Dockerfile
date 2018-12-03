FROM nginx:alpine

LABEL vendor="Galactic Fog IP, Inc."
LABEL com.galacticfog.version="4.0.4" 
# Make sure to update this version and keep consistent with tag

ENV BUILD_DEPS="gettext"  \
    RUNTIME_DEPS="libintl"

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
    rm -rf /var/cache/apk/*

# inject binaries: kubectl, helm an fog
COPY ./deps/kubectl /usr/local/bin/kubectl
COPY ./deps/helm /usr/local/bin/helm
COPY ./deps/fog /usr/local/bin/fog
RUN chmod 755 /usr/local/bin/*

# scripts and utilities
COPY ./scripts /scripts

# Inject 
COPY ./gestalt /gestalt

# define entrypoint
ENTRYPOINT ["./scripts/entrypoint.sh"]
