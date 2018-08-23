FROM anapsix/alpine-java:latest

LABEL vendor="Galactic Fog IP, Inc."
LABEL com.galacticfog.version="release-2.3.0"

ENV BUILD_DEPS="gettext"  \
    RUNTIME_DEPS="libintl"

# Add dependent packages
RUN apk add --update $RUNTIME_DEPS && \
    apk add --virtual build_deps $BUILD_DEPS &&  \
    cp /usr/bin/envsubst /usr/local/bin/envsubst && \
    apk del build_deps && \
    apk add --update \
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

# inject kubectl
COPY ./deps/kubectl /usr/local/bin/kubectl
RUN chmod 755 /usr/local/bin/kubectl

# Inject gestalt files
COPY ./scripts /scripts

# Inject binaries
COPY ./bin /bin

# Inject 
COPY ./gestalt /gestalt


# define entrypoint
ENTRYPOINT ["/scripts/install.sh"]
