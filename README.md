# PostgreSQL Lab

A local PostgreSQL 18 lab for learning data types, relational design, joins, indexes, query plans, partitioning, and database operations. The seeder creates deterministic synthetic commerce, event, measurement, document, and type-playground data.

## Requirements

- Docker Desktop with Docker Compose
- Node.js and npm for the shortcuts in `package.json` (you can run the shell seeder directly without npm)

PostgreSQL is published only on `127.0.0.1:5432` by the Compose file.

## Start here

From the project directory, run:

```bash
npm run db:seed:smoke
```

This starts the PostgreSQL container if needed, creates the `lab` schema and tables, inserts 100,000 rows into each ordinary table and each physical partition, then adds/validates foreign keys, builds secondary indexes, runs `ANALYZE`, and prints row counts. The first run can take a little while.

The database connection details are:

| Setting | Value |
| --- | --- |
| Host | `localhost` |
| Port | `5432` |
| Database | `commerce_lab` |
| User | `lab` |
| Password | `lab_password` |

These credentials are for this local development lab only.

## Seed profiles

| Profile | Rows per ordinary table | Rows per partition | Approximate total rows | Approximate database size |
| --- | ---: | ---: | ---: | ---: |
| `smoke` | 100,000 | 100,000 | 1 million | ~0.3 GB |
| `medium` | 1 million | 1 million | 10 million | ~3 GB |
| `full` | 50 million | 50 million | 500 million | ~130 GB |

The `events` and `measurements` datasets each have two physical partitions, so each has twice the profile row count in total. These storage figures are rough estimates scaled from the reported full run, whose database used about 130 GB. They include table, index, and TOAST relation storage; actual size varies with PostgreSQL version and data/index changes. Docker volume usage can be higher because it also includes WAL and other cluster files. Check current usage with `npm run db:size` and `npm run db:table-sizes` before choosing full.

You can grow a dataset from smoke to medium or full. Existing IDs are skipped, and additional IDs are loaded. Rows created at a smaller profile keep the values generated for that profile. To create a clean dataset for a profile, use the matching `db:reseed:*` command below.

The seeder uses deterministic SQL expressions and batches. If a batch fails, it is rolled back; fix the reported error and rerun the same command. Completed rows are skipped, so the script can continue without deleting the data.

## Commands

Run these from the project directory:

| Command | What it does |
| --- | --- |
| `npm run db:up` | Start PostgreSQL in the background. |
| `npm run db:down` | Stop and remove the Compose container and network; keep the database volume. |
| `npm run db:status` | Show the Compose service status. |
| `npm run db:logs` | Follow PostgreSQL logs. Press Ctrl+C to stop following logs. |
| `npm run db:psql` | Open an interactive `psql` session in the database. |
| `npm run db:counts` | Count rows in the benchmark tables and partitions. |
| `npm run db:size` | Show the total size PostgreSQL reports for `commerce_lab`. |
| `npm run db:table-sizes` | List `lab` tables and partitions by total relation size, including indexes and TOAST data. |
| `npm run db:seed` | Run the default smoke profile. |
| `npm run db:seed:smoke` | Seed 100K rows per ordinary table and partition. |
| `npm run db:seed:medium` | Seed 1M rows per ordinary table and partition. |
| `npm run db:seed:full` | Seed 50M rows per ordinary table and partition. |
| `npm run db:seed:size -- N` | Estimate rows for a custom target of `N` MiB and add missing data. |
| `npm run db:reseed:smoke` | Drop and recreate the `lab` schema, then seed smoke data. |
| `npm run db:reseed:medium` | Drop and recreate the `lab` schema, then seed medium data. |
| `npm run db:reseed:full` | Drop and recreate the `lab` schema, then seed full data. |
| `npm run db:reseed:size -- N` | Drop and recreate the `lab` schema, then seed for a custom target of `N` MiB. |
| `npm run db:erase` | Stop the service and delete its Docker volume and data. Project files remain. |

You can also call the shell script directly:

```bash
./scripts/seed.sh --profile smoke
./scripts/seed.sh --profile medium
./scripts/seed.sh --profile full
./scripts/seed.sh --size-mb 1024
./scripts/seed.sh --size-mb 1024 --reset
./scripts/seed.sh --profile full --reset
```

The default batch size is 100,000 IDs. To change it, pass `--batch-size N`, for example `./scripts/seed.sh --profile medium --batch-size 25000`.

### Custom size targets

Pass a positive whole number of MiB with `--size-mb`. For example, `npm run db:seed:size -- 1024` estimates enough rows for a database around 1 GiB; use `npm run db:reseed:size -- 1024` to start clean. The script scales rows across all benchmark tables and partitions using the observed full-profile size of about 130 GiB as its calibration. Since row, index, and database overheads do not scale perfectly, the result is approximate. Check the actual result with `npm run db:size`; if it is short of the target, rerun with a higher target. Existing data is retained when using `db:seed:size`, so use the reseed command when you want the target estimated from an empty lab schema.

The current schema supports custom targets up to 133,120 MiB (about 130 GiB), corresponding to 50 million rows per ordinary table and per physical partition. Targets above that require extending the partition ranges and full-profile row limit first.

## Reset versus erase

- **Clean reseed:** `npm run db:reseed:smoke` drops only the `lab` schema and recreates it. Other databases in the Postgres cluster remain.
- **Erase all database files for this Compose project:** `npm run db:erase` removes the Compose-managed volume as well as the container. The next seed command initializes a fresh PostgreSQL cluster and populates it.
- **Stop and preserve data:** `npm run db:down` removes the container but keeps the volume. Run `npm run db:up` to start the same database again.

Both clean reseed and erase delete data. The erase command does not delete `README.md`, scripts, SQL files, or other project files.

## Check storage use

Run `npm run db:size` for the database's total size as PostgreSQL reports it. This includes the database's tables, indexes, and related relation data. Run `npm run db:table-sizes` to find the largest `lab` tables and partitions; `pg_total_relation_size` includes each relation's indexes and TOAST data. Partitioned parent tables have no storage of their own, so the report is most useful when looking at the physical child partitions.

The database-size result is not the same as the Docker volume's full disk usage. The volume also contains PostgreSQL cluster files such as WAL and may contain other databases. Docker Desktop's storage view reports virtual disk/volume usage at the container level.

## Data model and relationships

The seeder creates these datasets in the `lab` schema:

- `customers` and `products`: large joinable dimensions
- `orders` and `order_items`: commerce relationships and exact numeric values
- `events` and `measurements`: time-oriented partitioned datasets
- `documents`: text, XML, JSON, JSONB, ranges, and full-text search values
- `type_playground`: examples of additional PostgreSQL native and user-defined types

After a successful seed, the finalization step adds and validates these foreign keys:

- `orders.customer_id → customers.customer_id`
- `order_items.order_id → orders.order_id`
- `order_items.product_id → products.product_id`
- `events.customer_id → customers.customer_id`
- `measurements.customer_id → customers.customer_id`

A typical multi-table join follows `customers → orders → order_items → products`. Events and measurements can also be joined through customers. Secondary indexes and full-text/JSONB indexes are built by the finalization step after loading.

Useful files:

- `compose.yaml`: PostgreSQL service and persistent data volume
- `scripts/seed.sh`: startup, batching, recovery, and profile selection
- `sql/schema.sql`: schema, table, type, and partition definitions
- `sql/seed-batch.sql`: deterministic batch generation
- `sql/finalize.sql`: foreign keys, indexes, and statistics
- `sql/counts.sql`: row-count summary
- `PLAN.md`: broader learning plan and capacity notes
