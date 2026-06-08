# Catalog Component: Lakekeeper + MinIO

This component provides the Iceberg REST Catalog (Lakekeeper) and S3-compatible object storage (MinIO) for the converged analytics demo.

## Components

- **MinIO**: S3-compatible object storage for Iceberg data files
- **Lakekeeper**: Iceberg REST Catalog server (v0.10.3) for metadata management
- **Lakekeeper Postgres**: PostgreSQL 17.4 database for Lakekeeper metadata
- **Lakekeeper Migrate**: Database migration service (runs once on startup)
- **Lakekeeper Bootstrap**: EULA acceptance service (runs once on startup)
- **Create Buckets**: MinIO bucket initialization (creates `warehouse` bucket)

## Quick Start

```bash
just up-catalog       # Start catalog stack
just logs-catalog     # View Lakekeeper logs
just down-catalog     # Stop
```

Or for the full stack: `just up` starts everything including the catalog.

## Accessing Services

- **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin)
- **MinIO API**: http://localhost:9000
- **Lakekeeper REST API**: http://localhost:8181
- **Lakekeeper Health Check**: http://localhost:8181/catalog/v1/config
- **Lakekeeper Postgres**: localhost:9054 (postgres/password)

Via Caddy reverse proxy:
- **Lakekeeper UI**: http://localhost:8888/ui/
- **Lakekeeper Catalog**: http://localhost:8888/catalog

## Network

All compose files use `converged-analytics-network` with `external: true`.
The network is created by the `_ensure-network` Justfile recipe before any
services start.

## Volumes

- `minio-data`: Persistent storage for MinIO data
- `lakekeeper-db-data`: Persistent storage for Lakekeeper metadata

## Troubleshooting

```bash
# Check if MinIO is healthy
docker exec minio mc admin info local

# Check Lakekeeper logs
docker logs lakekeeper

# Check migration logs
docker logs lakekeeper-migrate

# Check if bucket was created
docker logs createbuckets

# Check if EULA was accepted
docker logs lakekeeper-bootstrap

# Restart
docker restart lakekeeper
```

## Notes

- Lakekeeper uses `allowall` authorization backend for demo purposes (no authentication required)
- The database migration service (`lakekeeper-migrate`) runs once on startup and exits
- MinIO bucket creation (`createbuckets`) runs once on startup and exits
- Lakekeeper waits for both migration and bucket creation to complete before starting
