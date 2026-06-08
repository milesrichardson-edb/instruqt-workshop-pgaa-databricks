# PGAA × Databricks Unity Catalog: Instruqt workshop

A guided Instruqt track that walks a learner through registering Databricks
Unity Catalog as an Iceberg REST catalog in PGAA, importing tables, and
routing query execution through Databricks Spark Connect. Every
implementation step shows two parallel copy-paste blocks: one against the
learner's real Databricks workspace, one against a local Lakekeeper
Iceberg REST catalog running inside the Instruqt sandbox. Same PGAA SQL,
two backends.

## Repo layout

```
.
├── track.yml                       # track metadata
├── config.yml                      # sandbox VM spec + secrets declaration
├── track_scripts/
│   ├── setup-lab                   # clone repo → bring lab up → seed data
│   └── cleanup-lab                 # docker compose down -v
├── 01-overview/                    # workshop intro + two-track model
├── 02-prereqs-checklist/           # Azure-side preflight
├── 03-register-catalog/            # pgaa.add_catalog (dual-block)
├── 04-create-schema-and-ctas/      # CTAS into Iceberg (dual-block)
├── 05-import-catalog/              # pgaa.import_catalog (dual-block)
├── 06-spark-connect-prep/          # Databricks-only checklist
├── 07-spark-connect-executor/      # switch executor engine (dual-block)
├── 08-recap-and-limits/            # Known Limitations + recap
└── lab/                            # local stack (PGD + Lakekeeper + Spark + MinIO)
    ├── README.md                   # what's in here, how to refresh
    ├── docker-compose.yml          # unified entry — `include:`s the components
    ├── .env, .env.docker           # local creds for the LOCAL lab only
    ├── components/
    │   ├── catalog/                # MinIO + Lakekeeper PG + Lakekeeper + bootstrap
    │   ├── transactional-db/       # PGD with PGAA preloaded
    │   └── spark/                  # Spark master + connect server (port 15002)
    └── seed/
        └── 010_source_schema.sql   # TPC-H-shaped region + lineitem source data
```

Each challenge's `assignment.md` carries Instruqt YAML frontmatter (slug,
type, tabs, difficulty, timelimit) followed by Markdown content. Each has a
`check-lab` script that the **Check** button runs to verify the local-side
work succeeded.

## How files reach the sandbox VM

Instruqt only ships `track.yml`, `config.yml`, the per-challenge directories,
and `track_scripts/` to the sandbox. **Arbitrary directories like `lab/` are
NOT auto-uploaded.** This track therefore takes the standard pattern:

1. The track repo is hosted as a public Git repo.
2. `track_scripts/setup-lab` runs `git clone` against that repo at sandbox
   boot to fetch `lab/` onto the VM.
3. `setup-lab` then `cd`s into the cloned `lab/` and runs `docker compose
   build pgd && docker compose up -d`.

The Git URL is configured via the `WORKSHOP_REPO_URL` env var inside
`setup-lab` (defaults to the public repo URL declared at the top of the
script).

## Quick install + push runbook

```bash
# 1. Install the Instruqt CLI (macOS)
brew install instruqt/tap/instruqt

# 2. Authenticate
instruqt auth login

# 3. Set the destination team (matches `owner:` in track.yml)
instruqt config set team edb

# 4. Validate locally
instruqt track validate

# 5. Push to Instruqt
instruqt track push --force

# 6. Test the full lifecycle (boots a real sandbox; ~5 min)
instruqt track test --skip-fail-check --keep-running

# 7. Open the deployed track
instruqt track open
```

## EDB subscription token: runtime build via Instruqt sandbox secret

The PGD+PGAA image is built **at sandbox boot** using a BuildKit secret.
We don't pre-build (no shared registry) and don't ship the token in the
repo.

`config.yml` declares the secret:

```yaml
secrets:
  - name: EDB_SUBSCRIPTION_TOKEN
```

This is an org-wide Instruqt secret; set it once under **Org → Settings →
Secrets** in the Instruqt UI. Every sandbox launch gets it as an env var on
the `lab` VM. `track_scripts/setup-lab` exports it and runs
`docker compose build pgd` (~3–5 min cold), then brings the rest of the
stack up.

If the secret is unset, `setup-lab` logs a clear error and the PGD build
fails — that's the intended UX.

`lab/components/transactional-db/docker-compose.yml` wires the BuildKit
secret to this env var (`secrets.edb_token.environment:
EDB_SUBSCRIPTION_TOKEN`); no changes needed there.

## Iterating

```bash
# Edit a challenge
$EDITOR 04-create-schema-and-ctas/assignment.md

# Validate
instruqt track validate

# Push (force overwrites remote)
instruqt track push --force

# If you changed lab/, also push to the public Git repo so the next sandbox
# boot sees the changes
git add lab/ && git commit -m "lab: ..." && git push
```

If you change `lab/`, you can also verify locally without involving Instruqt:

```bash
cd lab && docker compose down -v && DOCKER_BUILDKIT=1 docker compose build pgd && docker compose up -d
docker compose ps
PGPASSWORD=secret psql -h localhost -p 7432 -U postgres -d demo -tAc \
  "SELECT name, type, status FROM pgaa.list_catalogs();"
# → local_lakekeeper | iceberg-rest | attached
```

## Background

The workshop is structured around copy-pasteable blocks because the typical
deployment scenario is: the learner's Postgres host is theirs (often inside
a corporate network), not something Instruqt can SSH to. So Instruqt drives
a parallel local lab in a sandbox VM, and the learner pastes the same SQL
into both their own host and the sandbox to compare. The PDF in
`prep-docs/guide-databricks-setup.pdf` is the source of truth for the
SQL/shell content of challenges 03–08.
