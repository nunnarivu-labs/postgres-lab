# PostgreSQL Learning Plan

## Objective

Use this project as a practical, progressive course in PostgreSQL 18: learn the SQL language, PostgreSQL's native types, relational design, query planning, indexing, concurrency, administration, recovery, and integration. Every module should have an explanation, a runnable example, an exercise, and a way to inspect the result.

PostgreSQL's feature set is larger than a finite checklist: extensions can add new data types, operators, index methods, procedural languages, and server behavior. This roadmap covers the complete core learning path and the major built-in server features. It also marks advanced administrator and extension topics so they can be explored in separate modules.

## Current lab baseline

- PostgreSQL 18 runs in Docker Compose; the host is an M4 Max MacBook Pro with 128 GB unified memory and a 4 TB SSD.
- The full profile has been loaded: 50M rows in each ordinary benchmark table and 50M rows in each physical partition. The observed database size is about 130 GB.
- `lab.events` and `lab.measurements` are range-partitioned by ID. Each has two physical partitions holding IDs 1–50M and 50,000,001–100M. Queries against the parent include both partitions; ID predicates let PostgreSQL prune partitions.
- The data model has customer, product, order, line, event, measurement, document, and type-playground datasets. Foreign keys are added and validated when seeding finishes.
- `scripts/seed.sh` supports smoke, medium, full, and approximate custom-size profiles. `--reset` recreates the `lab` schema; `npm run db:erase` removes the Compose-managed data volume.
- The full dataset's relation storage is about 130 GB. Custom size requests scale row counts against this measurement; they are estimates, not exact disk quotas.

Before a high-load lesson, check `npm run db:size` and `npm run db:table-sizes`. Keep an untouched full-seed baseline when comparing changes; use a clean reseed when the exercise needs to return to that baseline.

## How to work through the course

For each lesson:

1. Read the linked PostgreSQL 18 documentation section.
2. Run the lesson SQL in a dedicated file under `lessons/` (create this directory as the course grows).
3. Predict the result or query plan before running the statement.
4. Compare actual results with the prediction, recording row counts, plans, buffers, and timings where relevant.
5. Reset only the lesson's objects or use a clean reseed when needed. Mark an item complete only after explaining the behavior in your own words.

Use `npm run db:psql` to open `psql`; use `npm run db:counts`, `npm run db:size`, and `npm run db:table-sizes` to inspect the lab. Begin expensive scans at smoke/medium scale and use the full dataset for the final benchmark comparisons.

## Curriculum

### 0. Connect, inspect, and operate the lab

- [ ] Understand Docker Compose service, image tag, port binding, persistent volume, environment variables, and container lifecycle.
- [ ] Connect with `psql`; learn prompts, command history, `\?`, `\h`, `\dt`, `\d+`, `\dx`, `\conninfo`, `\timing`, `\x`, `\i`, `\o`, and `\copy`.
- [ ] Distinguish SQL statements from `psql` meta-commands; understand the current database, schema, role, and `search_path`.
- [ ] Practice seed profiles, resuming, clean reseeding, and deleting the Docker volume. Know which actions destroy data.
- [ ] Inspect PostgreSQL version, server settings, active sessions, database size, relation sizes, and installed extensions.

### 1. SQL foundations and relational thinking

- [ ] Read rows with `SELECT`, `FROM`, `WHERE`, `ORDER BY`, `LIMIT`, `OFFSET`, aliases, expressions, and `CASE`.
- [ ] Understand NULL and three-valued logic: `IS NULL`, `IS DISTINCT FROM`, `COALESCE`, and why `= NULL` does not work.
- [ ] Learn operator precedence, implicit and explicit casts, type resolution, collation-sensitive comparisons, and string/date input formats.
- [ ] Use `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `RETURNING`, and `VALUES` safely inside transactions.
- [ ] Compare PostgreSQL-specific behavior with portable SQL where useful; learn identifier quoting and case folding.

### 2. Data modeling and integrity

- [ ] Create and alter databases, schemas, tables, views, sequences, and types; understand object ownership and dependencies.
- [ ] Compare primary keys, unique constraints, foreign keys, `NOT NULL`, `CHECK`, and exclusion constraints.
- [ ] Learn composite keys, natural vs surrogate keys, referential actions, deferrable constraints, `NOT VALID` and validation, and uniqueness with NULL values.
- [ ] Use defaults, identity columns, sequences, generated columns, and the older `serial` shorthand; understand sequence gaps and `setval`.
- [ ] Practice `ALTER TABLE` changes, locks, backfills, renames, type changes, table rewrites, and safe migration ordering on large relations.
- [ ] Use the current relationships: customer → orders → order items → products; customer → events/measurements.
- [ ] Extend an exercise dataset so one order has multiple order items; the current baseline begins with one item per order.

### 3. PostgreSQL data types

Learn input/output formats, storage implications, operators, comparisons, casts, indexing support, and edge cases for each family.

- [ ] Integers (`smallint`, `integer`, `bigint`), exact `numeric`/`decimal`, approximate `real`/`double precision`, and `money` including locale behavior.
- [ ] `text`, `varchar`, fixed-width `char`, `bytea`, fixed/variable bit strings, and encoding/collation behavior.
- [ ] `boolean`; `date`, `time`, `timetz`, `timestamp`, `timestamptz`, and `interval`; time zones, daylight-saving transitions, and date arithmetic.
- [ ] UUIDs; enumerated types; domains; composite types; automatically generated array types; user-defined base and range types (advanced).
- [ ] Arrays: dimensions, lower bounds, subscripting, slicing, containment, unnesting, and indexing.
- [ ] JSON vs JSONB, JSON operators, containment, subscripting, SQL/JSON path, validation, and GIN operator classes.
- [ ] XML values and XPath; PostgreSQL geometric types (`point`, `line`, `lseg`, `box`, `path`, `polygon`, `circle`).
- [ ] Network types (`inet`, `cidr`, `macaddr`, `macaddr8`) and bitwise/network operators.
- [ ] Ranges and multiranges: bounds, empty/unbounded ranges, containment, overlap, exclusion constraints, and GiST indexing.
- [ ] Full-text types (`tsvector`, `tsquery`), configurations, dictionaries, ranking, highlighting, and index maintenance.
- [ ] Object identifier types, `pg_lsn`, `pg_snapshot`, large objects, and the distinction between usable column types and pseudo/internal types.
- [ ] Type conversion rules, domains over built-ins, custom operators, and how types affect planner estimates and index operator classes.

The existing schema contains examples from most commonly used families. Some specialist types (such as `line`, `lseg`, `box`, `path`, `tsquery`, custom base/range types, and safe catalog types) should be taught with isolated small examples rather than adding more wide columns to every 50M-row record.

### 4. Joins and relational queries

- [ ] `INNER`, `LEFT`, `RIGHT`, `FULL`, and `CROSS` joins; self joins; equality and non-equality joins.
- [ ] Multi-table join paths and aliases; join conditions vs filters; NULL extension and duplicate row behavior.
- [ ] Semi/anti joins with `EXISTS`, `NOT EXISTS`, `IN`, and `NOT IN`; compare NULL semantics and plans.
- [ ] One-to-one, one-to-many, and many-to-many modeling; bridge tables; join fan-out and cardinality estimates.
- [ ] `LATERAL` joins, correlated subqueries, scalar subqueries, and set-returning functions in `FROM`.
- [ ] Aggregate after joins without double-counting; deduplicate at the right stage; use `DISTINCT` only when the semantics require it.
- [ ] Compare join orders and algorithms (nested loop, hash join, merge join); learn when the optimizer can reorder joins.
- [ ] Write an end-to-end query joining customers, orders, order items, and products, then include aggregated event activity for the same customer.

### 5. Aggregation and advanced SQL

- [ ] Aggregates, `GROUP BY`, `HAVING`, aggregate `FILTER`, ordered-set aggregates, and `GROUPING SETS` / `ROLLUP` / `CUBE`.
- [ ] Window functions: partitioning, ordering, frames, ranking, offsets, running totals, and common frame mistakes.
- [ ] CTEs, recursive CTEs, materialization/inlining behavior, cycle detection, and hierarchical traversal.
- [ ] Set operations: `UNION [ALL]`, `INTERSECT`, and `EXCEPT`; ordering and duplicate elimination.
- [ ] `DISTINCT ON`, `FILTER`, `WITH ORDINALITY`, `VALUES`, row constructors, arrays in `FROM`, and `TABLESAMPLE`.
- [ ] `INSERT ... ON CONFLICT`, `MERGE`, upsert races, `RETURNING`, data-modifying CTEs, and `COPY`.
- [ ] Views, security-barrier views, updatable views, materialized views, refresh, and concurrent refresh requirements.
- [ ] Prepared statements, parameter types, generic vs custom plans, plan caching, and bind parameter behavior.

### 6. Indexes and query planning

- [ ] Read `EXPLAIN` plans; use `EXPLAIN (ANALYZE, BUFFERS, WAL, SETTINGS)` carefully and understand execution side effects.
- [ ] Compare estimated and actual rows, startup/total cost, loops, rows removed, buffers, I/O timing, and planning/execution time.
- [ ] Sequential, index, bitmap, index-only, and parallel scans; heap visibility map; when a sequential scan is the right plan.
- [ ] B-tree, hash, GiST, SP-GiST, GIN, and BRIN index capabilities and tradeoffs.
- [ ] Composite/multicolumn, unique, partial, expression, covering (`INCLUDE`), and collated indexes; column order and selectivity.
- [ ] Operator classes/families, sort order, null ordering, index-only scans, lossy bitmap scans, and rechecks.
- [ ] Compare plans before/after an index; compare write cost, index size, cache behavior, and query latency.
- [ ] Statistics: `ANALYZE`, statistics targets, histograms, most-common values, correlation, and extended statistics.
- [ ] Planner choices for joins, aggregation, sorting, `LIMIT`, partition pruning, parallel query, JIT, and incremental sort.
- [ ] Inspect `pg_stat_user_tables`, `pg_stat_user_indexes`, `pg_statio_*`, `pg_stat_statements` (after installing the extension), and `auto_explain` (optional).

Current indexes include primary-key B-trees, a unique SKU index, join-key B-trees, JSONB/full-text GIN indexes, and time-column BRIN indexes. Use these as the baseline; add alternatives in disposable exercise schemas.

### 7. Storage, partitioning, and physical design

- [ ] Understand heap pages, tuples, tuple headers, alignment, page layout, free space, visibility map, FSM, and relation forks.
- [ ] Observe TOAST: inline vs out-of-line values, compression, external storage, and impact of updates.
- [ ] Declarative range/list/hash partitioning; partition keys, bounds, default partitions, pruning, constraints, indexes, and unique-key restrictions.
- [ ] Compare the current ID-range partitioning with time-range partitioning on a disposable table; demonstrate pruning with `EXPLAIN`.
- [ ] Create, attach, detach, exchange/load, archive, and drop partitions; understand operational lock and validation costs.
- [ ] Compare declarative partitioning with table inheritance; learn inheritance caveats and `ONLY`.
- [ ] Temporary, unlogged, and logged tables; durability and crash behavior; `UNLOGGED` staging tradeoffs.
- [ ] Tablespaces and storage parameters, fillfactor, clustering, `CLUSTER`, `VACUUM FULL`, and rewrite/compaction costs.
- [ ] Large objects vs `bytea`; storage costs for wide rows and large payloads.

### 8. Transactions, MVCC, and concurrency

- [ ] `BEGIN`, `COMMIT`, `ROLLBACK`, savepoints, transaction blocks, autocommit, and transaction scope in `psql`/clients.
- [ ] MVCC snapshots, tuple versions, visibility, write amplification, and why updates/deletes create vacuum work.
- [ ] Read Committed, Repeatable Read, Serializable; demonstrate nonrepeatable reads, serialization failures, and retry handling.
- [ ] Row/table locks, lock modes, lock compatibility, blocking, deadlocks, lock timeouts, and `pg_locks` diagnosis.
- [ ] `SELECT ... FOR UPDATE/SHARE`, `NOWAIT`, `SKIP LOCKED`, advisory locks, and queue-consumer patterns.
- [ ] Concurrent updates, lost-update prevention, optimistic concurrency, uniqueness races, and upsert behavior.
- [ ] HOT updates, index changes, bloat, long-running transactions, idle-in-transaction sessions, and vacuum interference.
- [ ] Use two or more `psql` sessions to reproduce and diagnose each concurrency case.

### 9. Functions, procedures, triggers, and extensibility

- [ ] Built-in functions/operators, polymorphic functions, set-returning functions, aggregate functions, and window functions.
- [ ] SQL functions vs procedures; PL/pgSQL variables, control flow, records, exceptions, cursors, dynamic SQL, and transaction control in procedures.
- [ ] Trigger timing/levels, `BEFORE`/`AFTER`/`INSTEAD OF`, transition tables, constraint triggers, recursion, and trigger performance.
- [ ] Event triggers and DDL auditing; understand rules and when modern alternatives are preferable.
- [ ] Create a custom aggregate, operator, operator class, collation, domain, enum, composite type, and range type in isolated lessons.
- [ ] Install, inspect, update, and remove extensions; distinguish core, `contrib`, third-party, and OS-packaged extensions.
- [ ] Explore extension packaging and C-language extensions only as an advanced track.
- [ ] Understand `LISTEN`/`NOTIFY`, notifications' transaction behavior, and why they are not a durable queue.

### 10. Roles, authentication, and security

- [ ] Roles, login roles, group membership, ownership, grants/revokes, default privileges, schema usage, and object privileges.
- [ ] `pg_hba.conf`, local vs host authentication, SCRAM, connection encryption/TLS, and authentication order.
- [ ] Row-level security policies, permissive/restrictive policies, owner bypass, `FORCE ROW LEVEL SECURITY`, and testing as multiple roles.
- [ ] `search_path`, object shadowing, SQL injection, parameterized queries, and `SECURITY DEFINER` safety.
- [ ] Database/schema isolation, least privilege, secret handling, and audit/statement logging.
- [ ] Inspect system catalogs and built-in roles without granting broad privileges to the application role.

### 11. Server operation, configuration, and monitoring

- [ ] PostgreSQL process architecture, client backends, shared memory, shared buffers, WAL buffers, background writer, checkpointer, and autovacuum workers.
- [ ] Configuration sources and precedence, `SHOW`, `ALTER SYSTEM`, reload vs restart settings, context, and `pg_settings`.
- [ ] Connection limits, connection pooling concepts, `work_mem` per operation, `maintenance_work_mem`, `shared_buffers`, and safe memory budgeting.
- [ ] Checkpoints, `max_wal_size`, WAL retention, checkpoint pressure, fsync/synchronous commit, and durability tradeoffs.
- [ ] `VACUUM`, `VACUUM (ANALYZE)`, autovacuum thresholds, freezing, transaction ID wraparound protection, `ANALYZE`, and `REINDEX`.
- [ ] Logs, slow-query logging, wait events, activity views, database statistics, checkpoints, vacuum statistics, and progress views.
- [ ] Monitor connections, locks, table/index sizes, cache hits, temp files, dead tuples, WAL, replication slots, and long transactions.
- [ ] Tune one setting at a time and compare with a repeatable workload; keep a record of configuration and results.

### 12. Backup, restore, and recovery

- [ ] `pg_dump`, `pg_dumpall`, `pg_restore`, plain vs custom/directory formats, parallel dump/restore, and schema-only/data-only dumps.
- [ ] Restore into a fresh database and verify row counts, constraints, indexes, extensions, ownership, and privileges.
- [ ] Physical base backups with `pg_basebackup`, WAL archiving, continuous archiving, and point-in-time recovery.
- [ ] Understand recovery targets, timelines, WAL retention, backup consistency, RPO/RTO, and why copying a running data directory is unsafe.
- [ ] Compare logical backups with physical backups; measure backup size/time and restore time for this dataset.

### 13. Replication and high availability

- [ ] WAL shipping, streaming replication, physical standbys, hot standby, synchronous vs asynchronous replication, and replication lag.
- [ ] Replication slots, WAL retention risk, cascading standbys, read-only query conflicts, and failover concepts.
- [ ] Logical replication publications/subscriptions, initial table copy, row filters/column lists, sequence caveats, and schema changes.
- [ ] Monitor sender/receiver state, replay LSN, lag, slots, and WAL growth.
- [ ] Use a separate Compose profile or disposable second cluster for replication; never risk the only copy of the lab volume.

### 14. Search, external data, and client integration

- [ ] Full-text search: parser/configuration, dictionaries, stemming, ranking, highlighting, GIN/GiST, and update strategy.
- [ ] JSON/JSONB query patterns and indexes; SQL/JSON path and document modeling tradeoffs.
- [ ] Foreign data wrappers, foreign servers/tables, `postgres_fdw`, pushdown, transaction behavior, and remote query plans.
- [ ] `dblink` and database links as an older/optional comparison; `COPY` text/CSV/binary formats and `\copy`.
- [ ] Client protocol basics, connection strings, transactions in a driver, prepared statements, pooling, cancellation, and error/retry handling.
- [ ] Optional extensions such as `pg_stat_statements`, `pg_trgm`, `citext`, `btree_gin`, and PostGIS; check image/package availability before designing a lesson around one.

### 15. Advanced and specialist topics

- [ ] Parallel query safety, worker limits, parallel scans/joins/aggregates, and leader participation.
- [ ] JIT compilation thresholds and workloads; compare plans with JIT enabled/disabled.
- [ ] Planner hints are not built-in; learn statistics/SQL/index changes first, then compare third-party approaches separately.
- [ ] Collations, ICU vs libc, nondeterministic collations, collation versioning, and reindexing after changes.
- [ ] SQL conformance, unsupported/extension-specific features, compatibility boundaries, and PostgreSQL release notes/upgrades.
- [ ] Advanced internals: pageinspect/visibility tools where available, WAL inspection, logical decoding, custom access methods, background workers, and extension APIs.
- [ ] Read PostgreSQL release notes for major-version changes; practice a major upgrade in a disposable copy of the data.

## Benchmark exercises and completion criteria

For each performance exercise, define the query and expected output first, then record:

- result row count and correctness check
- `EXPLAIN (ANALYZE, BUFFERS)` plan and estimated-vs-actual row counts
- elapsed time across repeated runs, distinguishing warm-cache and cold-start behavior
- relation/index size and write cost where relevant
- PostgreSQL settings, profile size, and whether the run was concurrent

The course is complete when you can:

1. Design a normalized schema with correct keys, constraints, types, and security boundaries.
2. Write and explain complex joins, aggregates, window queries, recursive queries, and JSON/full-text queries.
3. Read a query plan, explain why the planner chose it, and improve it with evidence.
4. Diagnose a blocked transaction, deadlock, poor estimate, vacuum issue, or WAL/disk growth.
5. Load, validate, back up, restore, and recover the lab without losing the ability to reproduce it.
6. Explain the tradeoffs of indexes, partitions, types, isolation levels, durability, and replication.
7. Identify which advanced features require an extension, extra server configuration, or a multi-node environment.

## PostgreSQL 18 documentation map

- [Tutorial](https://www.postgresql.org/docs/18/tutorial.html)
- [SQL language and commands](https://www.postgresql.org/docs/18/sql.html)
- [Data types](https://www.postgresql.org/docs/18/datatype.html)
- [Data definition, constraints, schemas, and partitioning](https://www.postgresql.org/docs/18/ddl.html)
- [Queries and table expressions](https://www.postgresql.org/docs/18/queries.html)
- [Functions and operators](https://www.postgresql.org/docs/18/functions.html)
- [Indexes](https://www.postgresql.org/docs/18/indexes.html)
- [Performance tips and database population](https://www.postgresql.org/docs/18/performance-tips.html)
- [Concurrency control and isolation](https://www.postgresql.org/docs/18/mvcc.html)
- [Server administration](https://www.postgresql.org/docs/18/admin.html)
- [Monitoring and statistics](https://www.postgresql.org/docs/18/monitoring.html)
- [Backup and restore](https://www.postgresql.org/docs/18/backup.html)
- [High availability and replication](https://www.postgresql.org/docs/18/high-availability.html)
- [Full-text search](https://www.postgresql.org/docs/18/textsearch.html)
- [Foreign data](https://www.postgresql.org/docs/18/ddl-foreign-data.html)
- [Extension building](https://www.postgresql.org/docs/18/extend.html)
