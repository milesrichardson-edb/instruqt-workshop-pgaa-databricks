FROM ubuntu:24.04

# Build arguments (no credentials — EDB token is a BuildKit secret)
ARG PLATFORM=linux/amd64
# Which repo to install PGAA from: "enterprise" (stable) or "dev" (latest, EDB-internal)
# Use `just check-versions` to see what's available in each repo.
ARG PGAA_REPO=enterprise

# Install dependencies
RUN apt-get update && apt-get install -y \
  curl \
  gnupg \
  lsb-release \
  python3 \
  python3-pip \
  python3-venv \
  && rm -rf /var/lib/apt/lists/*

# Add EDB repos and install PGD
# Token is mounted as a BuildKit secret — never persisted in image layers.
RUN --mount=type=secret,id=edb_token \
  EDB_SUBSCRIPTION_TOKEN=$(cat /run/secrets/edb_token) && \
  curl -1sLf "https://downloads.enterprisedb.com/$EDB_SUBSCRIPTION_TOKEN/postgres_distributed/setup.deb.sh" | bash && \
  curl -1sLf "https://downloads.enterprisedb.com/$EDB_SUBSCRIPTION_TOKEN/enterprise/setup.deb.sh" | bash
RUN apt-get update && apt-get install -y \
  edb-pgd6-expanded-pgextended17 \
  && rm -rf /var/lib/apt/lists/*

# Install PGAA (separate step — repo may differ from PGD)
RUN --mount=type=secret,id=edb_token \
    EDB_SUBSCRIPTION_TOKEN=$(cat /run/secrets/edb_token) && \
    if [ "$PGAA_REPO" = "dev" ]; then \
      curl -1sLf "https://downloads.enterprisedb.com/$EDB_SUBSCRIPTION_TOKEN/dev/setup.deb.sh" | bash; \
    fi && \
    apt-get update && apt-get install -y \
      edb-postgresextended-17-pgaa \
    && rm -rf /var/lib/apt/lists/*

# Remove EDB repo configs so no token or repo URL leaks into image layers
RUN rm -f /etc/apt/sources.list.d/enterprisedb-*.list \
          /etc/apt/sources.list.d/downloads_enterprisedb_com_*.list && \
    apt-get clean

# Python is used by the entrypoint for JSON parsing (warehouse ID lookup)
RUN python3 -m pip install --break-system-packages psycopg2-binary

# Create directories and set ownership
RUN mkdir -p /var/lib/postgresql/db /var/lib/postgresql/pgd-analytics && \
  chown -R postgres:postgres /var/lib/postgresql

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set environment
ENV PGDATA=/var/lib/postgresql/db
ENV PATH=/usr/lib/edb-pge/17/bin:$PATH
ENV POSTGRES_PASSWORD=secret

# Expose ports
EXPOSE 5432 6432 6433

USER postgres

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["postgres"]
