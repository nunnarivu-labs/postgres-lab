#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE=""
SIZE_MB=""
RESET=0
BATCH_SIZE=100000

FULL_ROWS=50000000
FULL_SIZE_MB=$((130 * 1024))

usage() {
  cat <<'EOF'
Usage: scripts/seed.sh [--profile smoke|medium|full | --size-mb N] [--batch-size N] [--reset]

Profiles are rows per ordinary table and per physical partition:
  smoke   100,000  (default)
  medium  1,000,000
  full    50,000,000 (500 million total rows across all datasets)
  --size-mb N  estimate rows for an approximate database size in MiB

The script can be rerun after an interruption; existing IDs are skipped.
Profiles can be increased without resetting. Use --reset before starting over
or changing to a smaller profile.
The custom size estimate is calibrated from a 130 GiB full-profile database;
the largest supported custom target is 133120 MiB (the full profile).
EOF
}

while (($#)); do
  case "$1" in
    --profile)
      (($# >= 2)) || { usage >&2; exit 2; }
      PROFILE="$2"
      shift 2
      ;;
    --size-mb)
      (($# >= 2)) || { usage >&2; exit 2; }
      SIZE_MB="$2"
      shift 2
      ;;
    --batch-size)
      (($# >= 2)) || { usage >&2; exit 2; }
      BATCH_SIZE="$2"
      shift 2
      ;;
    --reset)
      RESET=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -n "$SIZE_MB" && -n "$PROFILE" ]]; then
  printf 'Choose either --profile or --size-mb, not both.\n' >&2
  exit 2
elif [[ -n "$SIZE_MB" ]]; then
  if ! [[ "$SIZE_MB" =~ ^[1-9][0-9]*$ ]]; then
    printf 'Target size must be a positive integer number of MiB.\n' >&2
    exit 2
  fi
  if ((SIZE_MB > FULL_SIZE_MB)); then
    printf 'Custom targets are limited to %s MiB; use the full profile for the maximum supported size.\n' "$FULL_SIZE_MB" >&2
    exit 2
  fi
  ROWS=$((SIZE_MB * FULL_ROWS / FULL_SIZE_MB))
  if ((ROWS < 1)); then ROWS=1; fi
  PROFILE="custom:${SIZE_MB}MiB"
elif [[ -z "$PROFILE" ]]; then
  PROFILE="smoke"
fi

if [[ -z "$SIZE_MB" ]]; then
  case "$PROFILE" in
    smoke) ROWS=100000 ;;
    medium) ROWS=1000000 ;;
    full) ROWS=50000000 ;;
    *) printf 'Unknown profile: %s\n' "$PROFILE" >&2; usage >&2; exit 2 ;;
  esac
fi

if ! [[ "$BATCH_SIZE" =~ ^[1-9][0-9]*$ ]]; then
  printf 'Batch size must be a positive integer.\n' >&2
  exit 2
fi

compose() {
  docker compose -f "$ROOT_DIR/compose.yaml" "$@"
}

psql_in_container() {
  compose exec -T postgres psql -X -v ON_ERROR_STOP=1 -U lab -d commerce_lab "$@"
}

printf 'Starting the PostgreSQL service...\n'
compose up -d postgres

ready=0
for attempt in $(seq 1 60); do
  if compose exec -T postgres pg_isready -U lab -d commerce_lab >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
if ((ready == 0)); then
  printf 'PostgreSQL did not become ready within 60 seconds.\n' >&2
  exit 1
fi

if ((RESET == 1)); then
  printf 'Reset requested: dropping the lab schema and all of its data.\n'
  psql_in_container -c 'DROP SCHEMA IF EXISTS lab CASCADE;'
fi

psql_in_container -f - < "$ROOT_DIR/sql/schema.sql"

if [[ "$PROFILE" == full ]]; then
  printf 'Full profile: 50M rows per ordinary table and per partition; 500M total rows.\n'
  printf 'Confirm Docker Desktop has at least 1 TB free for the database and load headroom.\n'
fi
if [[ -n "$SIZE_MB" ]]; then
  printf 'Custom target: %s MiB; estimated %s rows per ordinary table and per partition.\n' "$SIZE_MB" "$ROWS"
  printf 'This is a rough estimate calibrated from the observed 130 GiB full-profile database size.\n'
  if ((RESET == 0)); then
    printf 'Existing data is retained; use --reset for a clean dataset sized from scratch.\n'
  fi
fi
printf 'Seeding profile=%s rows-per-table-or-partition=%s batch-size=%s\n' "$PROFILE" "$ROWS" "$BATCH_SIZE"

start_id=1
while ((start_id <= ROWS)); do
  end_id=$((start_id + BATCH_SIZE - 1))
  if ((end_id > ROWS)); then end_id="$ROWS"; fi

  psql_in_container \
    -v start_id="$start_id" \
    -v end_id="$end_id" \
    -v rows="$ROWS" \
    -f - < "$ROOT_DIR/sql/seed-batch.sql"

  printf 'Loaded ID range %s..%s of %s\n' "$start_id" "$end_id" "$ROWS"
  start_id=$((end_id + 1))
done

psql_in_container -f - < "$ROOT_DIR/sql/finalize.sql"
printf 'Seed complete. Row counts:\n'
psql_in_container -f - < "$ROOT_DIR/sql/counts.sql"
