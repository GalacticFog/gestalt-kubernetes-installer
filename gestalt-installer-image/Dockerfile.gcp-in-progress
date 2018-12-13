FROM ${base_image}

ARG component_label=gestalt-installer
LABEL application=gestalt
LABEL component=${component_label}
LABEL build.phase=target
LABEL vendor="Galactic Fog IP, Inc."
LABEL com.galacticfog.version=${version_label}

WORKDIR /app

COPY /app /app

RUN pwd && \
    echo "--------------------------------------------------" && \
    find /app -type f && \
    echo "--------------------------------------------------" && \
    echo "DEPLOYER BUILD DONE." && \
    echo "--------------------------------------------------"

# The entrypoint script should launch the installer scripts.
ENTRYPOINT ["/app/entrypoint.sh"]
