-- Seed the source-side data the workshop CTAS examples read FROM.
--
-- The PDF (§4 Step C) shows:
--   CREATE TABLE test_schema.region USING PGAA WITH (...) AS
--   ( SELECT * FROM source_schema.region );
--
-- We provide a TPCH-shaped `source_schema.region` (5 rows) plus a tiny
-- `source_schema.lineitem` so the count(*) in challenges 05 and 07 returns
-- something interesting. The shapes match TPC-H so anyone who's seen Greenplum
-- or DuckDB benchmarks recognizes the columns immediately.
--
-- Idempotent: safe to re-run from track_scripts/setup-lab.

CREATE SCHEMA IF NOT EXISTS source_schema;

CREATE TABLE IF NOT EXISTS source_schema.region (
    r_regionkey  integer        PRIMARY KEY,
    r_name       varchar(25)    NOT NULL,
    r_comment    varchar(152)
);

INSERT INTO source_schema.region (r_regionkey, r_name, r_comment) VALUES
    (0, 'AFRICA',      'lar deposits. blithely final packages cajole. regular waters are final requests'),
    (1, 'AMERICA',     'hs use ironic, even requests. s'),
    (2, 'ASIA',        'ges. thinly even pinto beans ca'),
    (3, 'EUROPE',      'ly final courts cajole furiously final excuse'),
    (4, 'MIDDLE EAST', 'uickly special accounts cajole carefully blithely close requests')
ON CONFLICT (r_regionkey) DO NOTHING;

-- Trimmed lineitem — TPCH columns, just enough rows for count(*) to be
-- non-trivial. Decimal columns intentionally use `double precision` here so
-- the same table can be written to Databricks UC later (UC's Iceberg
-- implementation does not currently support numeric/decimal — see the
-- "Known Limitations" challenge).
CREATE TABLE IF NOT EXISTS source_schema.lineitem (
    l_orderkey       bigint           NOT NULL,
    l_partkey        bigint           NOT NULL,
    l_suppkey        bigint           NOT NULL,
    l_linenumber     integer          NOT NULL,
    l_quantity       double precision NOT NULL,
    l_extendedprice  double precision NOT NULL,
    l_discount       double precision NOT NULL,
    l_tax            double precision NOT NULL,
    l_returnflag     char(1)          NOT NULL,
    l_linestatus     char(1)          NOT NULL,
    l_shipdate       date             NOT NULL,
    l_commitdate     date             NOT NULL,
    l_receiptdate    date             NOT NULL,
    l_shipinstruct   varchar(25)      NOT NULL,
    l_shipmode       varchar(10)      NOT NULL,
    l_comment        varchar(44)      NOT NULL,
    PRIMARY KEY (l_orderkey, l_linenumber)
);

INSERT INTO source_schema.lineitem VALUES
    (1, 155190, 7706, 1, 17.0, 21168.23, 0.04, 0.02, 'N', 'O', '1996-03-13', '1996-02-12', '1996-03-22', 'DELIVER IN PERSON', 'TRUCK',  'egular courts above the'),
    (1, 67310,  7311, 2, 36.0, 45983.16, 0.09, 0.06, 'N', 'O', '1996-04-12', '1996-02-28', '1996-04-20', 'TAKE BACK RETURN',  'MAIL',   'ly final dependencies: slyly bold '),
    (1, 63700,  3701, 3,  8.0, 13309.60, 0.10, 0.02, 'N', 'O', '1996-01-29', '1996-03-05', '1996-01-31', 'TAKE BACK RETURN',  'REG AIR','riously. regular, express dep'),
    (2, 106170, 1191, 1, 38.0, 44694.46, 0.00, 0.05, 'N', 'O', '1997-01-28', '1997-01-14', '1997-02-02', 'TAKE BACK RETURN',  'RAIL',   'ven requests. deposits breach a'),
    (3, 4297,   1798, 1, 45.0, 54058.05, 0.06, 0.00, 'R', 'F', '1994-02-02', '1994-01-04', '1994-02-23', 'NONE',              'AIR',    'ongside of the furiously brave acco'),
    (3, 19036,  6540, 2, 49.0, 46796.47, 0.10, 0.00, 'R', 'F', '1993-11-09', '1993-12-20', '1993-11-24', 'TAKE BACK RETURN',  'RAIL',   ' unusual accounts. eve'),
    (3, 128449, 3474, 3, 27.0, 39890.88, 0.06, 0.07, 'A', 'F', '1994-01-16', '1993-11-22', '1994-01-23', 'DELIVER IN PERSON', 'SHIP',   'nal foxes wake. '),
    (3, 29380,  1883, 4,  2.0,  2618.76, 0.01, 0.06, 'A', 'F', '1993-12-04', '1994-01-07', '1994-01-01', 'NONE',              'TRUCK',  'y. fluffily pending d'),
    (3, 183095, 8366, 5, 28.0, 32986.52, 0.04, 0.00, 'R', 'F', '1993-12-14', '1994-01-10', '1994-01-01', 'TAKE BACK RETURN',  'FOB',    'ites. quickly ironic requests pre'),
    (3, 62143,  9659, 6, 26.0, 28733.64, 0.10, 0.02, 'A', 'F', '1993-10-29', '1993-12-18', '1993-11-04', 'TAKE BACK RETURN',  'RAIL',   'requests. ironic, bold '),
    (4, 88035,  5560, 1, 30.0, 30690.90, 0.03, 0.08, 'N', 'O', '1996-01-10', '1995-12-14', '1996-01-18', 'DELIVER IN PERSON', 'REG AIR','- quickly regular packages sleep. idly')
ON CONFLICT (l_orderkey, l_linenumber) DO NOTHING;

-- Quick sanity: how many rows did we land?
DO $$
DECLARE
    region_count   bigint;
    lineitem_count bigint;
BEGIN
    SELECT count(*) INTO region_count FROM source_schema.region;
    SELECT count(*) INTO lineitem_count FROM source_schema.lineitem;
    RAISE NOTICE 'source_schema.region rows: %', region_count;
    RAISE NOTICE 'source_schema.lineitem rows: %', lineitem_count;
END
$$;
