FROM debian:bookworm-slim
ARG TIDB_VERSION=v8.5.6

# Add tiup to PATH
ENV HOME="/home/tidb"
ENV PATH="/home/tidb/.tiup/bin:${PATH}"

# Install build-time tools and runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl default-mysql-client-core && \
    useradd --create-home --shell /bin/bash tidb && \
    chown -R tidb:tidb /home/tidb && \
    mkdir -p /sql && \
    chmod 755 /sql && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER tidb
WORKDIR /home/tidb

# Install TiDB components as the runtime user
RUN curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh && \
    tiup install playground tidb:${TIDB_VERSION} pd:${TIDB_VERSION} tikv:${TIDB_VERSION}

USER root

# Keep curl out of the runtime image
RUN apt-get purge -y --auto-remove curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=tidb:tidb start.sh /home/tidb/start.sh
COPY --chown=tidb:tidb tidb.toml /home/tidb/tidb.toml
RUN chmod +x /home/tidb/start.sh

# Expose TiDB SQL port only
EXPOSE 4000

# Set environment variable for TIDB_VERSION
ENV TIDB_VERSION=${TIDB_VERSION}

USER tidb
CMD ["/home/tidb/start.sh"]
