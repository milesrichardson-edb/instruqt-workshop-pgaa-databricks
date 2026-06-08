---
slug: spark-connect-executor
id: xmfss9nc3bvg
type: challenge
title: Switch the executor engine to Spark Connect
teaser: SET pgaa.executor_engine = 'spark_connect' — same query, now offloaded to
  Spark.
tabs:
- id: fqnk3fv4ftnh
  title: Lab terminal
  type: terminal
  hostname: lab
- id: rbaatao1snud
  title: Lab DB (psql)
  type: terminal
  hostname: lab
  cmd: PGPASSWORD=secret psql -h localhost -p 7432 -U postgres -d demo
- id: ckkwjaus03x2
  title: Spark UI
  type: service
  hostname: lab
  port: 4040
difficulty: advanced
timelimit: 1200
enhanced_loading: null
---

# What you'll do

Tell PGAA to stop using its embedded Seafowl executor and instead route
analytical queries through a Spark Connect endpoint. On your VM that endpoint
is your Databricks cluster; in the sandbox it's the local `spark-connect`
container.

The query SQL you run **doesn't change**. Only the GUC and the URL do.

---

## On your VM (routing through Databricks Spark Connect)

The token must be supplied via the `SPARK_REMOTE` environment variable on the
**PostgreSQL server process**, so it never appears in SQL or `pg_settings`.
On your Postgres host, edit your systemd unit (or whatever supervises
Postgres) and add:

```bash
export SPARK_REMOTE="sc://<workspace>.azuredatabricks.net:443/;token=<your_token>;use_ssl=true;x-databricks-cluster-id=<cluster_id>"
```

Replace:

- `<workspace>` — your workspace hostname **without** `https://`,
  e.g. `adb-7405618805881351.11.azuredatabricks.net`.
- `<your_token>` — the PAT from challenge 02.
- `<cluster_id>` — the cluster ID from challenge 06.

Restart Postgres so the new environment is picked up. Then in `psql`:

```sql
SET pgaa.executor_engine = 'spark_connect';

-- Same SQL as challenge 04 — but now executed on Databricks:
SELECT * FROM test_schema.region;
SELECT count(*) FROM test_schema.region;
```

If you can't restart Postgres (or want to override per-session), use the
GUC instead — note the token goes in the URL:

```sql
SET pgaa.executor_engine = 'spark_connect';
SET pgaa.spark_connect_url =
  'sc://<workspace>.azuredatabricks.net:443/;token=<your_token>;use_ssl=true;x-databricks-cluster-id=<cluster_id>';

SELECT * FROM test_schema.region;
SELECT count(*) FROM test_schema.region;
```

If `pgaa.spark_connect_url` is set, it takes priority over `SPARK_REMOTE`.

---

## On the Instruqt sandbox (routing through local Spark Connect)

The local Spark Connect server has no auth and no cluster ID — those are
Databricks-isms. The URL is just `sc://spark-connect:15002`:

```sql
SET pgaa.executor_engine = 'spark_connect';
SET pgaa.spark_connect_url = 'sc://spark-connect:15002';

SELECT * FROM test_schema.region;
SELECT count(*) FROM test_schema.region;
```

Open the **Spark UI** tab (port 4040) and you'll see the query show up in
the **Jobs** list — proof that PGAA offloaded execution to Spark instead of
running it via Seafowl.

To switch back to the default engine for the rest of your session:

```sql
SET pgaa.executor_engine = 'seafowl';
```

---

## Why both

URL parameter handling for Spark Connect is identical between Databricks
and a vanilla Spark Connect server. The Databricks URL just has more
parameters:

| Parameter                  | Required for Databricks | Required for local |
| -------------------------- | ----------------------- | ------------------ |
| `token=...`                | yes (PAT)               | no                 |
| `use_ssl=true`             | yes                     | no                 |
| `x-databricks-cluster-id=` | yes                     | n/a                |

Anything that isn't a well-known Spark Connect key (`token`, `use_ssl`,
`user_id`, `user_agent`, `session_id`) is passed through to the Spark
Connect server as a gRPC header. That's how `x-databricks-cluster-id`
routes the request to a specific cluster — it's just a header.

## What this changes day-to-day

- Heavy aggregations that don't fit in PGAA's embedded executor get pushed
  to Databricks compute (which is what you're paying Databricks for anyway).
- Costs follow Databricks' cluster billing model, not Postgres CPU.
- Per-session opt-in: small queries stay on Seafowl (local, fast), big
  queries `SET pgaa.executor_engine = 'spark_connect'` and run on
  Databricks.

Click **Check** to verify the local Spark Connect engine works.
