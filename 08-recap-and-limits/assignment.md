---
slug: recap-and-limits
id: drtpe14yxfwd
type: challenge
title: Recap + Known Limitations
teaser: What you've built, what you can't (yet) do, and which engine to choose for
  what.
tabs:
- id: c1bmt6gn9ydq
  title: Lab terminal
  type: terminal
  hostname: lab
- id: dxshjupachre
  title: Lab DB (psql)
  type: terminal
  hostname: lab
  cmd: PGPASSWORD=secret psql -h localhost -p 7432 -U postgres -d demo
difficulty: basic
timelimit: 600
enhanced_loading: null
---

# What you've built

By the end of challenge 07 you have, **on both your real Databricks workspace
and the local sandbox**:

1. A registered Iceberg REST catalog. (`pgaa.add_catalog`)
2. A `test_schema.region` table written via PGAA's CTAS path. The same data
   is queryable from Postgres and from any other Iceberg/Unity-Catalog client.
3. The whole namespace re-imported in one call. (`pgaa.import_catalog`)
4. The query path routed to Spark Connect, with no other SQL changes.

The same six SQL statements (give or take catalog names) cover both backends.
That's the deliverable: **PGAA over Unity Catalog is a drop-in for PGAA over
any other Iceberg REST catalog**, so anything you build in dev against
Lakekeeper is going to behave the same way against UC in prod.

# Known Limitations (PDF §4 callout, paraphrased)

These are the gotchas to budget for.

## 1. Views endpoint

Databricks Unity Catalog **does not implement the standard Iceberg `/views`
endpoint** — it returns 404. PGAA's REST catalog client treats this as "no
views" and continues, so reads of tables aren't affected. **But** if you
have UC views you want to surface in PGAA, they aren't reachable through
the views endpoint — UC currently exposes views via `/tables` instead.

Practical impact: if your team's Databricks workflow leans heavily on UC
views, plan to either materialize them into tables for PGAA consumption,
or accept that PGAA will only see UC tables.

## 2. Numeric / Decimal types

Databricks UC's Iceberg implementation **does not currently support
`numeric` or `decimal`**. If your CTAS source has decimal columns, the
write to UC will fail. Workaround: cast to `double precision` or `real`.

This is why the `source_schema.lineitem` seed in this workshop uses
`double precision` for `l_quantity`, `l_extendedprice`, etc. instead of
the canonical TPC-H `numeric(15,2)`.

## 3. Spark integration is read-only

PGAA + Spark Connect routes **read** queries to Spark. Writes
(CTAS, replication, INSERT) still go through PostgreSQL / PGAA's writer.
You can't run `INSERT INTO test_schema.region …` and have it execute on
Databricks Spark.

## 4. CTAS source uses CompatScan, not DirectScan

When the source side of `CREATE TABLE … AS SELECT` is itself a PGAA table,
PGAA falls back to its CompatScan path (the row-by-row PostgreSQL
executor) rather than DirectScan (Arrow Flight from Seafowl). For large
CTAS jobs prefer running them as Spark SQL via `pgaa.spark_sql(...)` and
recording the result as a new catalog table.

# Which engine for what

| Workload                                  | Engine            | Why                                          |
| ----------------------------------------- | ----------------- | -------------------------------------------- |
| Small SELECTs (catalog metadata, lookup)  | `seafowl`         | Local, no network hop, sub-second            |
| Medium aggregations (under a few GB)      | `seafowl`         | Embedded DataFusion is fast on small data    |
| Heavy joins, terabyte aggregations        | `spark_connect`   | Databricks compute scales horizontally       |
| Anything customers need to bill explicitly | `spark_connect`  | Cluster usage shows up in Databricks billing |

Switch per-session, not globally:

```sql
-- Big query: route to Databricks
SET pgaa.executor_engine = 'spark_connect';
SELECT customer_id, SUM(amount)
FROM analytics.fact_transactions
GROUP BY customer_id;

-- Reset for everything else
RESET pgaa.executor_engine;
```

# Things this workshop did not cover

- The Azure portal walkthrough (PDF §1–3) — workspace, access connector,
  ADLS Gen2 storage account, IAM grants. See the prep PDF.
- PGD replication of transactional tables to Iceberg
  (`pgd.replicate_to_analytics = true`).
- Tiered tables (hot/cold lifecycle).
- WHPG (Greenplum-fork) integration with PGAA.
- Multiple-catalog joins via `pgaa.spark_sql(... ARRAY['cat1','cat2'])`.

These are the natural next steps once the basic UC-as-storage pattern is
working in your environment.

# Where to go from here

- The full PGAA reference (every GUC, every catalog option) is in EDB's
  documentation portal.
- For real-world deploys, the EDB analytics team can help with the catalog
  registration JSON if your org has non-trivial OAuth or networking
  constraints.

Click **Check** to finish the workshop.
