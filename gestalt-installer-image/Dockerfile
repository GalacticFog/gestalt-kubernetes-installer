FROM nginx:alpine

LABEL vendor="Galactic Fog IP, Inc."
LABEL com.galacticfog.version="release-2.3.0"

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

# inject kubectl
COPY ./deps/kubectl /usr/local/bin/kubectl
RUN chmod 755 /usr/local/bin/kubectl

# inject kubectl
COPY ./deps/fog /usr/local/bin/fog
RUN chmod 755 /usr/local/bin/fog

# Inject gestalt files
COPY ./scripts /scripts

# Inject binaries
COPY ./bin /bin

# Inject 
COPY ./gestalt /gestalt

# Inject resource templates
COPY ./resource_templates /resource_templates

# define entrypoint
ENTRYPOINT ["/scripts/install.sh"]
