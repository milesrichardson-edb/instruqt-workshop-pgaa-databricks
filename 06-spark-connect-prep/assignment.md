---
slug: spark-connect-prep
id: hkhgeadmzbbn
type: challenge
title: Spark Connect prerequisites — Databricks side
teaser: Confirm a Unity-Catalog-compatible cluster, capture the cluster ID, reuse
  the PAT.
tabs:
- id: wxwjxm5faeyk
  title: Lab terminal
  type: terminal
  hostname: lab
difficulty: basic
timelimit: 600
enhanced_loading: null
---

# What you'll do

This challenge is **Databricks-only** — there's nothing to paste against
the local sandbox. The local lab already has Spark Connect running on
`spark-connect:15002` (we'll use it in the next challenge). What you need
to do here is make sure your Databricks side is set up the same way.

You should already have most of this from challenge 02. This is a focused
checklist for Spark Connect specifically.

---

## ✅ Cluster: Unity-Catalog-compatible

Per PDF §5 Step A:

1. **Compute** in the sidebar → **Create compute** (or pick an existing
   cluster that meets these requirements).
2. **Policy:** Personal Compute or Shared.
3. **Access mode:** **Single User** or **Shared** — Unity Catalog requires
   one of these two. Other access modes (Custom, No isolation shared) will
   not work with Spark Connect against UC.
4. **Databricks Runtime Version:** **13.3 LTS or higher**.
5. Click **Create compute** and wait for the green dot (Running).

Spark Connect support landed in Spark 3.4 / Databricks Runtime 13.x — earlier
runtimes don't speak the gRPC protocol we need.

---

## ✅ Cluster ID

Per PDF §5 Step B, two ways to get it:

- **Via URL:** with the cluster open, the ID is the slug after `…/clusters/`.
  Example: `0401-121120-abcd123`.
- **Via UI:** Configuration tab → Advanced Options → Tags tab → `ClusterId`.

You'll paste this into the `x-databricks-cluster-id` field of the Spark
Connect URL in the next challenge.

---

## ✅ PAT — same one as before

Per PDF §5 Step C, the Spark Connect URL uses **the same PAT** you put in
`pgaa.add_catalog`'s `token` field in challenge 03. Don't generate a new one;
reuse the existing one.

---

## Summary checklist

You should now have:

```
WORKSPACE_URL = https://adb-________________.__.azuredatabricks.net
CLUSTER_ID    = ____-______-________
PAT           = dapi________________________
```

The next challenge wires these three into a single `SPARK_REMOTE` URL.

## What's pre-arranged in the sandbox

The local Spark Connect server is already running on `spark-connect:15002`
inside the docker network and `localhost:15002` from the sandbox VM's
perspective. No auth, no cluster ID — those are Databricks-side concepts.
You'll see the difference between the two URLs in the next challenge.

Click **Check** to continue.
