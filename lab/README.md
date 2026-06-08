# Local lab stack (vendored)

This directory contains the local Iceberg + Postgres stack the Instruqt sandbox
runs to mirror the real Postgres-host-against-Databricks workflow. Every
implementation challenge has a "paste here on the Instruqt sandbox" block that
talks to *this* stack instead of Databricks Unity Catalog.

## What's running

| Service           | Image                                    | Purpose                                    | Port  |
| ----------------- | ---------------------------------------- | ------------------------------------------ | ----- |
| `pgd`             | `converged-analytics-pgd` (built local)  | PGD 6 with PGAA — the SQL surface          | 7432  |
| `lakekeeper`      | `quay.io/lakekeeper/catalog:v0.10.3`     | Iceberg REST catalog (UC stand-in)         | 8181  |
| `lakekeeper-postgres` | `postgres:17.4`                      | Lakekeeper's metadata DB                   | 9054  |
| `minio`           | `minio/minio:latest`                     | S3-compatible object storage               | 9000  |
| `minio` console   | (same)                                   | UI                                         | 9001  |
| `spark-master`    | `spark:3.5.6-java17`                     | Spark cluster master                       | 7077  |
| `spark-connect`   | `spark:3.5.6-java17`                     | Spark Connect server (matches Databricks) | 15002 |
| `spark-worker-0`  | `spark:3.5.6-java17`                     | Worker                                     | —     |

After `docker compose up -d` settles, two bootstraps run automatically:

1. `lakekeeper-bootstrap` accepts Lakekeeper's EULA via the management API.
2. `initialwarehouse` creates a warehouse named `demo-warehouse` backed by the
   `warehouse` MinIO bucket — this is what challenge 03's local block registers.

The PGD entrypoint then reads `CATALOG_*` env vars from `.env.docker`, registers
`local_lakekeeper` as a catalog, and creates `pgaa` extension on first boot.

The seed in `seed/010_source_schema.sql` is applied by
`track_scripts/setup-lab` after PGD is healthy — it creates a TPC-H-shaped
`source_schema.region` (5 rows) and `source_schema.lineitem` (~10 rows) so the
CTAS examples in challenges 04, 05, and 07 succeed against the local catalog.

## Vendored from where

```
~/vvv/converged-analytics-internal/components/catalog/         → components/catalog/
~/vvv/converged-analytics-internal/components/transactional-db/ → components/transactional-db/
~/vvv/converged-analytics-internal/components/spark/            → components/spark/
```

The reference repo is **read-only**. To refresh, re-run the equivalent of:

```bash
SRC=~/vvv/converged-analytics-internal
DST=$(git rev-parse --show-toplevel)/lab
cp -R "$SRC/components/catalog/."          "$DST/components/catalog/"
cp -R "$SRC/components/transactional-db/." "$DST/components/transactional-db/"
cp -R "$SRC/components/spark/."            "$DST/components/spark/"
```

## What we trimmed (from the reference repo's root `docker-compose.yml`)

The reference repo includes a much wider stack. We dropped these components —
all out of scope for this workshop:

- `components/analytics-db/` (WHPG / Greenplum fork)
- `components/monitoring/` (Prometheus, Loki, Grafana, Mailpit)
- `components/wem/` (PGD WEM admin UI)
- `components/proxy/` (Caddy reverse proxy)
- `demos/call-center-demo/`
- `components/spark/docker-compose-gpu.yml` and `components/spark/docker/spark-rapids/` (NVIDIA RAPIDS variant)

If you ever need to bring those back, copy them in from the reference repo and
add their compose paths to `lab/docker-compose.yml`.

## EDB subscription token: runtime build

`components/transactional-db/Dockerfile` builds with an `EDB_SUBSCRIPTION_TOKEN`
BuildKit secret to install `edb-pgd6-expanded-pgextended17` and
`edb-postgresextended-17-pgaa` from EDB's authenticated apt repositories.
The Instruqt sandbox VM gets the token via an Instruqt **sandbox secret**
(declared in `config.yml` under `secrets:`), set in the Instruqt UI under
**Track → Settings → Secrets** — same approach as the WHPG workshop.

Flow:

1. `config.yml` declares `secrets: - name: EDB_SUBSCRIPTION_TOKEN`.
2. The track operator enters the actual token value in the Instruqt UI.
3. Instruqt injects it as an env var on the `lab` VM at sandbox start.
4. `track_scripts/setup-lab` exports it and runs `docker compose build pgd`.
5. The vendored `lab/components/transactional-db/docker-compose.yml`
   already declares the BuildKit secret wired to that env var:

   ```yaml
   secrets:
     edb_token:
       environment: EDB_SUBSCRIPTION_TOKEN
   ```

6. The Dockerfile mounts it as `--mount=type=secret,id=edb_token` — the
   token is never persisted in image layers.

First-boot cost: ~3–5 min for the PGD image build. Subsequent `compose up`
calls reuse the cached image, so per-challenge `setup-host` scripts are
fast.

If the token isn't set in the Instruqt UI, `setup-lab` logs a clear error
and the PGD service will fail to build — that's the intended UX.

## Quick local-only verification

```bash
# Bring the stack up
cd lab && docker compose up -d

# Wait for everyone to settle
docker compose ps

# Confirm Lakekeeper is alive
curl -fsS http://localhost:8181/health && echo OK

# Confirm PGD + PGAA + the local catalog
PGPASSWORD=secret psql -h localhost -p 7432 -U postgres -d demo \
  -c "SELECT name, type FROM pgaa.list_catalogs();"
# Expected: local_lakekeeper | iceberg-rest

# Apply the source-schema seed (idempotent)
PGPASSWORD=secret psql -h localhost -p 7432 -U postgres -d demo \
  -f seed/010_source_schema.sql
```

If the `pgaa.list_catalogs()` call comes back empty, check the PGD logs for the
catalog-registration step in the entrypoint — the most common cause is
Lakekeeper not being healthy when PGD first booted.
