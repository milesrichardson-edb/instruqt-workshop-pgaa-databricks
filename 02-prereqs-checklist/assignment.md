---
slug: prereqs-checklist
id: oh51eoupgg0d
type: challenge
title: Prereqs — what you need from Databricks before you start
teaser: Confirm you have the workspace URL, cluster ID, PAT, and EXTERNAL USE SCHEMA
  grant.
tabs:
- id: c3yrbz8ngthd
  title: Lab terminal
  type: terminal
  hostname: lab
difficulty: basic
timelimit: 600
enhanced_loading: null
---

# Before you can paste anything against your real workspace

PGAA against Databricks Unity Catalog needs **four** things from the Databricks
side. None of them can be done from inside Instruqt — they're all in the Azure
portal or the Databricks UI. The full walkthrough is in
`prep-docs/guide-databricks-setup.pdf` §1–3; this challenge is a checklist so
you don't reach `03-register-catalog` and discover something is missing.

## ✅ Checklist

### 1. Workspace URL

You need the full HTTPS URL of your Azure Databricks workspace, e.g.:

```
https://adb-7405618805881351.11.azuredatabricks.net
```

You'll paste this into the catalog `url` and the Spark Connect URL.

### 2. Unity Catalog with a real catalog created on it

Per PDF §3 Steps A–C, you need:

- A **storage credential** wrapping an Access Connector for Azure Databricks.
- An **external location** at `abfss://<container>@<account>.dfs.core.windows.net/`.
- A **catalog** (e.g. `prod_data`) of type **Standard**, backed by that
  external location.

In challenge 03 the warehouse path you pass to PGAA is `catalogs/<catalog_name>`.

### 3. EXTERNAL USE SCHEMA grant

The Iceberg REST endpoint will refuse PGAA's reads/writes unless your
principal has the **EXTERNAL USE SCHEMA** privilege on the catalog. This
privilege is **not** included in `ALL PRIVILEGES`.

Per PDF §3 Step D:

1. **Catalog** → ⚙ gear → **Metastore** → toggle **External data access** to
   **Enabled**.
2. Click your catalog → **Permissions** → **Grant** → pick the principal →
   tick **EXTERNAL USE SCHEMA** → grant.

If you skip this, you'll see HTTP 403 from PGAA in the next challenge.

### 4. Personal Access Token (PAT)

Per PDF §3 Step E:

1. Top right → your username → **Settings**.
2. **Developer** → **Access tokens** → **Generate new token**.
3. Comment it `pgaa-workshop`, set an expiration, generate.
4. **Copy it immediately.** Databricks will not show it again.

The same token serves two purposes:

- The catalog `token` field in challenge 03.
- The `token` URL parameter in `SPARK_REMOTE` in challenge 07.

### 5. Cluster ID (for challenge 07)

You'll need this in challenge 07, but generate it now if you can — clusters
take a minute or two to start.

1. **Compute** in the sidebar → **Create compute**.
2. Policy: **Personal Compute** or **Shared**.
3. Access mode: **Single User** or **Shared** (Unity Catalog requires one of
   these two).
4. Runtime: **13.3 LTS** or higher.
5. Once it's **Running** (green dot), copy the ID — it's the slug after
   `…/clusters/` in the URL, or under **Configuration → Tags → ClusterId**.

Looks like: `0401-121120-abcd123`.

## What you should have collected

A scratchpad with:

```
WORKSPACE_URL = https://adb-________________.__.azuredatabricks.net
CATALOG_NAME  = ________________   # e.g. prod_data
PAT           = dapi________________________
CLUSTER_ID    = ____-______-________
```

Keep that handy — the next challenge wires the first three of them into PGAA.

## What's pre-arranged in the sandbox

The local "second column" lab inside Instruqt has none of those steps to do.
Lakekeeper's already running, the warehouse is named `demo-warehouse`, and no
auth is required. That's deliberate — this column is what UC *would* look
like if it were running locally, so you can see the API at work without
external dependencies.
