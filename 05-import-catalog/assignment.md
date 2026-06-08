---
slug: import-catalog
id: p9sbpyhezj49
type: challenge
title: Import an entire catalog namespace
teaser: pgaa.import_catalog() pulls every table in a namespace into Postgres in one
  call.
tabs:
- id: 45mbzjh48qql
  title: Lab terminal
  type: terminal
  hostname: lab
- id: 2w1wxcoiezq7
  title: Lab DB (psql)
  type: terminal
  hostname: lab
  cmd: PGPASSWORD=secret psql -h localhost -p 7432 -U postgres -d demo
difficulty: intermediate
timelimit: 600
enhanced_loading: null
---

# What you'll do

In challenge 04 we created **one** Iceberg table via CTAS. In real life, a
Unity Catalog namespace might hold dozens of tables that already exist —
you don't want to write `CREATE TABLE … USING PGAA WITH (…)` for each one.

`pgaa.import_catalog(catalog_name, namespace_filter)` does the bulk import
in a single call: it walks the catalog, lists every table in the namespace,
and creates a matching PGAA table in PostgreSQL with auto-discovered
columns.

---

## On your VM (importing the UC namespace)

After challenge 04, your `prod_data.test_schema` (UC) namespace contains the
`region` table you wrote. Drop the local PGAA shadow first (so the import
has work to do) and re-import:

```sql
-- Optional: drop the table we created in challenge 04 to prove the import works.
DROP TABLE IF EXISTS test_schema.region;

SELECT pgaa.import_catalog('databricks_unity_catalog', 'test_schema');

-- See what landed:
SELECT schema_name, table_name, catalog_name, catalog_namespace, catalog_table
FROM pgaa.list_analytics_tables()
WHERE catalog_name = 'databricks_unity_catalog';

-- Query the imported table:
SELECT * FROM test_schema.region;
SELECT count(*) FROM test_schema.region;
```

Two things worth noticing:

1. The imported relations live in a Postgres schema named after the
   catalog namespace (`test_schema`).
2. PGAA pulled the column types from the Iceberg metadata — you didn't
   specify them.

---

## On the Instruqt sandbox (importing the local Lakekeeper namespace)

```sql
DROP TABLE IF EXISTS test_schema.region;

SELECT pgaa.import_catalog('local_lakekeeper', 'test_schema');

SELECT schema_name, table_name, catalog_name, catalog_namespace
FROM pgaa.list_analytics_tables()
WHERE catalog_name = 'local_lakekeeper';

SELECT * FROM test_schema.region;
SELECT count(*) FROM test_schema.region;
```

Again, the only thing that changed is the catalog name in the first arg.

---

## Why both

`pgaa.import_catalog(...)` is the operation that scales: a single call covers
N tables, and the call shape is invariant under "which catalog am I talking
to?". A team that imports their UC namespaces nightly with this function in a
cron job reuses the exact same SQL when their data team stands up a local
Lakekeeper for dev — they just swap the catalog name.

## What this changes day-to-day

- Analysts can browse all of UC from a Postgres client.
- BI tools that already know how to talk to Postgres get UC for free.
- New tables created in UC by Databricks notebooks become visible to
  Postgres consumers via a periodic re-import.

Click **Check** to verify the imported table is queryable locally.
