FROM debian:bookworm-slim
ARG TIDB_VERSION=v8.5.2

# Install curl
RUN apt-get update && \
    apt-get install -y curl default-mysql-client-core && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install tiup
RUN curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh

# Add tiup to PATH
ENV PATH="/root/.tiup/bin:${PATH}"

# Install TiDB
RUN tiup install playground tidb:${TIDB_VERSION} pd:${TIDB_VERSION} tikv:${TIDB_VERSION}

# Create sql directory
RUN mkdir -p /sql

COPY start.sh /root/start.sh
RUN chmod +x /root/start.sh

# Expose TiDB port
EXPOSE 4000 2379

# Set environment variable for TIDB_VERSION
ENV TIDB_VERSION=${TIDB_VERSION}

# Set the working directory
WORKDIR /root
CMD ["/root/start.sh"]
