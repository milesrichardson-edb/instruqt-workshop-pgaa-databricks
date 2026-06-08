---
slug: overview
id: fwmyi1cmptgr
type: challenge
title: Overview — what you'll build, and the two-track mental model
teaser: PGAA + Databricks Unity Catalog, demonstrated against your real workspace
  AND a parallel local lab.
notes:
- type: text
  contents: |
    Welcome. While you read this, the sandbox is bringing up a local
    Iceberg catalog (Lakekeeper), MinIO object storage, a PGD database
    with PGAA installed, and a Spark Connect server. That whole stack
    will be ready by the time you reach challenge 03.
tabs:
- id: dnkefegl5xhz
  title: Lab terminal
  type: terminal
  hostname: lab
- id: qewryzhgersl
  title: Lab DB (psql)
  type: terminal
  hostname: lab
  cmd: docker exec -it pgd bash -c "PGPASSWORD=secret psql -U postgres -d demo"
- id: 7eustotod2vt
  title: Lakekeeper UI
  type: service
  hostname: lab
  port: 8181
- id: mpcyixsrz8o1
  title: MinIO console
  type: service
  hostname: lab
  port: 9001
difficulty: basic
timelimit: 600
enhanced_loading: null
---

# What this workshop demonstrates

Two things, end-to-end:

1. **PGAA can read and write Databricks Unity Catalog as an Iceberg REST catalog.**
   You'll register Unity Catalog, create tables via `CREATE TABLE … AS SELECT`,
   import a whole namespace, and query it — all from `psql`.
2. **Databricks Spark Connect can be the execution engine** behind those PGAA
   queries. You'll switch `pgaa.executor_engine` from the default `seafowl` to
   `spark_connect`, point it at a Databricks cluster, and watch the same SQL
   route through Spark on Databricks.

# Why this matters

Your analysts already know SQL and already use Postgres. PGAA lets you keep
that surface while delegating storage to Unity Catalog (governed, audited,
shared with every other Databricks consumer) and delegating heavy compute to
Databricks Spark. No data is copied out, no new dialect is introduced.

# The two-track mental model

Every implementation challenge from `03-register-catalog` onwards has **two
copy-paste blocks side by side**:

| **On your own Postgres host (against Databricks UC)** | **On the Instruqt sandbox (against local Lakekeeper)** |
| ----------------------------------------------------- | ------------------------------------------------------ |
| Real workspace, real Unity Catalog, real ADLS Gen2. The block has placeholders for your workspace URL / PAT / cluster ID. | Same PGAA SQL, pointed at a local Lakekeeper instance running in this Instruqt sandbox. No external dependencies. |

The blocks differ **only in the catalog JSON** — `add_catalog`'s URL, warehouse
path, and token change; everything else is identical. That's the proof: PGAA
treats Unity Catalog the same way it treats any other Iceberg REST catalog.

# What you need to bring (next challenge)

- **Databricks workspace URL** — `https://adb-…azuredatabricks.net`
- **Cluster ID** — `0401-121120-abcd123` from the Compute page URL
- **Personal Access Token (PAT)** — generated in Settings → Developer
- **Unity Catalog** with `EXTERNAL USE SCHEMA` granted to your principal

If any of those are missing, see `prep-docs/guide-databricks-setup.pdf` §1–3
for the Azure portal walkthrough. We don't repeat that part of the guide here
because Azure portal work isn't something Instruqt can drive.

# Layout of the rest of the track

| # | Challenge                       | What happens                                                         |
| - | ------------------------------- | -------------------------------------------------------------------- |
| 02 | Prereqs checklist              | Confirm you have the URL / cluster ID / PAT / EXTERNAL USE SCHEMA   |
| 03 | Register the catalog           | `pgaa.add_catalog(...)` against UC and Lakekeeper                    |
| 04 | Create schema + CTAS           | `CREATE SCHEMA test_schema; CREATE TABLE … USING PGAA AS SELECT …`   |
| 05 | Import the catalog             | `pgaa.import_catalog(...)` + `SELECT count(*)`                       |
| 06 | Spark Connect prerequisites    | Cluster ID, runtime, PAT — Databricks-only checklist                 |
| 07 | Spark Connect as executor      | `SET pgaa.executor_engine = 'spark_connect'` + query                 |
| 08 | Recap + Known Limitations      | Views endpoint, decimal/numeric, when to choose which engine         |

Click **Check** to continue.
