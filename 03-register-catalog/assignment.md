---
slug: register-catalog
id: wqnhknyrukfq
type: challenge
title: Register the Iceberg REST catalog
teaser: pgaa.add_catalog() — same call, two backends. Once for Unity Catalog, once
  for local Lakekeeper.
tabs:
- id: 3isx9pzzuxqs
  title: Lab DB (psql)
  type: terminal
  hostname: lab
  cmd: docker exec -it pgd bash -c "PGPASSWORD=secret psql -U postgres -d demo"
- id: 9pcuaswzx6nz
  title: Lab terminal
  type: terminal
  hostname: lab
- id: yrlysqh6jwhz
  title: Lakekeeper UI
  type: service
  hostname: lab
  port: 8181
difficulty: intermediate
timelimit: 900
enhanced_loading: null
---

# What you'll do

Register an Iceberg REST catalog with PGAA, twice: once against your real
Databricks Unity Catalog (paste into psql on **your VM**), and once against
the local Lakekeeper running in this Instruqt sandbox. Confirm both show up
in `pgaa.list_catalogs()`.

The signature is `pgaa.add_catalog(name, type, options_json)` — the only thing
that changes between the two backends is the JSON. That's the whole point of
this challenge.

---

## On your VM (against Databricks Unity Catalog)

Substitute your **workspace URL**, **catalog name** (e.g. `prod_data`), and
**PAT** from the prereqs checklist. Then paste into `psql` on your own Postgres host:

```sql
SELECT pgaa.add_catalog(
  'databricks_unity_catalog',
  'iceberg-rest',
  '{
    "url": "https://<your-workspace>.azuredatabricks.net/api/2.1/unity-catalog/iceberg-rest",
    "warehouse": "catalogs/prod_data",
    "warehouse_name": "prod_data",
    "token": "<your_databricks_pat>"
  }'
);
```

Confirm it took:

```sql
SELECT name, type, status FROM pgaa.list_catalogs();
```

You should see `databricks_unity_catalog | iceberg-rest | attached`. If you
see `refresh_failed`, the most likely cause is a missing **EXTERNAL USE
SCHEMA** grant — go back to the prereqs checklist.

---

## On the Instruqt sandbox (against local Lakekeeper)

The sandbox already has a catalog named `local_lakekeeper` registered
automatically by the PGD entrypoint at first boot — that's how the lab self-
configures. You can re-register it explicitly to see the same call shape, or
just confirm it's there.

To **see** the registration that already happened, in the **Lab DB (psql)**
tab paste:

```sql
SELECT name, type, status, options FROM pgaa.list_catalogs();
```

Expected:

```
       name        |     type     |  status
-------------------+--------------+----------
 local_lakekeeper  | iceberg-rest | attached
```

To re-register it from scratch (drop + add — useful for muscle memory),
you'll need the warehouse's UUID from Lakekeeper. The UUID is generated
when Lakekeeper creates the warehouse, so it's different in every sandbox.
Look it up first, then paste the registration:

In the **Lab terminal** tab:

```bash
WAREHOUSE_ID=$(
  curl -fsS http://localhost:8181/management/v1/warehouse \
  | python3 -c "import sys,json; print(next(w['id'] for w in json.load(sys.stdin)['warehouses'] if w['name']=='demo-warehouse'))"
)
echo "$WAREHOUSE_ID"
```

In the **Lab DB (psql)** tab — substitute the UUID you just printed for
`<warehouse_id>`:

```sql
SELECT * FROM pgaa.delete_catalog('local_lakekeeper', cascade := true);

SELECT pgaa.add_catalog(
  'local_lakekeeper',
  'iceberg-rest',
  '{
    "url": "http://lakekeeper:8181/catalog",
    "warehouse": "<warehouse_id>",
    "warehouse_name": "demo-warehouse"
  }'
);

SELECT pgaa.attach_catalog('local_lakekeeper');

SELECT name, type, status FROM pgaa.list_catalogs();
```

Note the difference from the UC block above: Lakekeeper takes a UUID for
`warehouse`, while Unity Catalog takes a path like `catalogs/prod_data`.
Both serve the same purpose — telling the catalog which warehouse this
client is talking to. UC also takes a `token` (the PAT), Lakekeeper in
`allowall` mode doesn't need one. Otherwise the calls are identical.

`pgaa.add_catalog` registers the catalog but leaves it `detached` until
the metastore-sync worker refreshes (default ~30s). `pgaa.attach_catalog`
forces an immediate attach so you don't have to wait.

---

## Why both

The function signature is identical. The catalog **type** is identical
(`iceberg-rest`). What differs is the catalog **server**:

- Unity Catalog speaks the Iceberg REST protocol at
  `…/api/2.1/unity-catalog/iceberg-rest` and authenticates with a Databricks
  PAT.
- Lakekeeper speaks the same protocol at `…/catalog` and (in this lab)
  doesn't require auth.

PGAA doesn't care. From PGAA's perspective both are just an Iceberg REST
catalog — which means anything you build on top works against either backend.
That's what makes UC a drop-in for an existing PGAA deployment.

Click **Check** to verify the local registration succeeded.
