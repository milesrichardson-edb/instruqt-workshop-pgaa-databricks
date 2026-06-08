---
slug: create-schema-and-ctas
id: zmfoukihxkkx
type: challenge
title: Create a schema and write a table via CTAS
teaser: CREATE TABLE … USING PGAA AS SELECT * FROM source — once into UC, once into
  Lakekeeper.
tabs:
- id: sexrqyjvg6cd
  title: Lab terminal
  type: terminal
  hostname: lab
- id: b5fwdomzmnqx
  title: Lab DB (psql)
  type: terminal
  hostname: lab
  cmd: PGPASSWORD=secret psql -h localhost -p 7432 -U postgres -d demo
- id: cyistnmuwagl
  title: MinIO console
  type: service
  hostname: lab
  port: 9001
difficulty: intermediate
timelimit: 900
enhanced_loading: null
---

# What you'll do

Two writes: a fresh `test_schema.region` Iceberg table populated from
`source_schema.region`, written via `CREATE TABLE … USING PGAA AS SELECT`.
Once into Databricks Unity Catalog (your VM), once into the local Lakekeeper
warehouse (the sandbox).

The CTAS triggers four things behind the scenes:

1. PGAA registers the new table with the catalog (UC or Lakekeeper).
2. PGAA writes Parquet data files into the catalog's storage backend.
3. PGAA writes Iceberg manifest + metadata files alongside.
4. PGAA creates a PostgreSQL relation pointing at the new Iceberg table.

After the CTAS, querying `test_schema.region` from PostgreSQL reads back
through Iceberg. You don't have to think about it — the table behaves like
any other Postgres relation.

---

## On your VM (writing into Databricks Unity Catalog)

```sql
CREATE SCHEMA test_schema;

CREATE TABLE test_schema.region
USING PGAA WITH (
  pgaa.managed_by = 'databricks_unity_catalog',
  pgaa.catalog_table = 'region',
  pgaa.catalog_namespace = 'test_schema',
  pgaa.format = 'iceberg',
  pgaa.purge_data_if_exists = 'true'
)
AS ( SELECT * FROM source_schema.region );

SELECT * FROM test_schema.region;
SELECT count(*) FROM test_schema.region;
```

After the CTAS:

- In the Databricks UI, navigate to **Catalog → prod_data → test_schema** —
  you should see the `region` table appear.
- The data files land under your ADLS Gen2 container at
  `abfss://…/__unitystorage/catalogs/<catalog-id>/tables/<table-id>/`.

Note `pgaa.purge_data_if_exists = 'true'`: re-running the CTAS will drop any
existing data at that catalog path. Useful for iteration; remove it for prod.

---

## On the Instruqt sandbox (writing into local Lakekeeper)

In the **Lab DB (psql)** tab:

```sql
CREATE SCHEMA IF NOT EXISTS test_schema;

CREATE TABLE test_schema.region
USING PGAA WITH (
  pgaa.managed_by = 'local_lakekeeper',
  pgaa.catalog_table = 'region',
  pgaa.catalog_namespace = 'test_schema',
  pgaa.format = 'iceberg',
  pgaa.purge_data_if_exists = 'true'
)
AS ( SELECT * FROM source_schema.region );

SELECT * FROM test_schema.region;
SELECT count(*) FROM test_schema.region;
```

The first `SELECT *` should return five rows (AFRICA, AMERICA, ASIA, EUROPE,
MIDDLE EAST), seeded by `lab/seed/010_source_schema.sql`. The
`count(*)` should be `5`.

Open the **MinIO console** tab (login: `minioadmin` / `minioadmin`) and
browse the `warehouse` bucket — you'll see the new Iceberg table directory
under `test_schema/region/`, with `data/` and `metadata/` subdirectories.

---

## Why both

Compare the two `CREATE TABLE` statements line by line. The **only** thing
that differs is `pgaa.managed_by = '<catalog-name>'`. Source query, target
schema, target table, format — all identical.

That's the contract: PGAA wraps "where does this table live?" behind a
catalog name. Swap the catalog, swap the storage backend, the SQL on top
doesn't move.

## ⚠️ Heads-up: numeric/decimal in UC

The PDF's "Known Limitations" section calls this out (and we'll revisit it
in challenge 08): **Databricks Unity Catalog's Iceberg implementation does
not currently support `numeric` or `decimal` types.** If your source query
includes any, the UC-side CTAS will fail. Cast to `double precision` or
`real` before writing.

The local Lakekeeper backend has no such limitation, which is why `lineitem`
in the seed already uses `double precision`.

Click **Check** to verify the local table exists and has the expected row count.
