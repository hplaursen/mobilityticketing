#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
mkdir -p docs/evidence/lecture04
log_file="docs/evidence/lecture04/run-output.txt"

for attempt in {1..30}; do
    if docker compose exec -T postgres pg_isready -U mobility -d mobility >/dev/null 2>&1; then
        break
    fi
    sleep 1
done
docker compose exec -T postgres pg_isready -U mobility -d mobility

run_sql() {
    printf '\n===== %s =====\n' "$1"
    docker compose exec -T postgres psql -X -U mobility -d mobility \
        -v ON_ERROR_STOP=1 -a -f "/work/$1"
}

{
    echo "Lecture 4 product identity migration experiment"
    echo "Database: compose service postgres, database mobility"
    echo "Assumption: freshly seeded Lecture 4 database; do not rerun without reset."
    run_sql database/postgres/experiments/lecture04/baseline.sql
    run_sql database/postgres/experiments/lecture04/unsafe_change.sql
    run_sql database/postgres/migrations/030_expand_product_identity.sql
    run_sql database/postgres/experiments/lecture04/immutable_product_id_probe.sql
    run_sql database/postgres/experiments/lecture04/old_reader.sql
    run_sql database/postgres/experiments/lecture04/old_writer.sql
    run_sql database/postgres/experiments/lecture04/new_reader.sql
    run_sql database/postgres/experiments/lecture04/require_before_backfill.sql
    run_sql database/postgres/migrations/031_backfill_ticket_product.sql
    run_sql database/postgres/migrations/031_backfill_ticket_product.sql
    run_sql database/postgres/experiments/lecture04/verify.sql
    run_sql database/postgres/experiments/lecture04/late_old_writer.sql
    run_sql database/postgres/migrations/031_backfill_ticket_product.sql
    run_sql database/postgres/experiments/lecture04/verify.sql
    run_sql database/postgres/experiments/lecture04/mismatch_probe.sql
    run_sql database/postgres/experiments/lecture04/new_writer.sql
    run_sql database/postgres/migrations/032_require_ticket_product.sql
    run_sql database/postgres/experiments/lecture04/old_writer_after_require.sql
    run_sql database/postgres/experiments/lecture04/remove_legacy.sql
} 2>&1 | tee "$log_file"

printf '\nFull run output saved to %s\n' "$log_file"
