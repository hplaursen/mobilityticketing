# Lecture 3 — Moodle answers

## Tasks

1. **Reference query:** The direct query is in [`base_revenue.sql`](../database/postgres/queries/base_revenue.sql). On the supplied seed data it returned 36 DKK and one captured payment for each operator on 2026-04-29.

2. **SQL function:** [`020_reporting_function.sql`](../database/postgres/migrations/020_reporting_function.sql) defines `captured_revenue_for_day`. It runs the aggregate against `payments` whenever called and returns 0 / 0 when the selected operator and date have no captured payments.

3. **Materialized view:** [`022_daily_captured_revenue.sql`](../database/postgres/migrations/022_daily_captured_revenue.sql) creates a stored aggregate and refreshes it at setup. It becomes stale after a payment insert, correction, or deletion, and is current again after `REFRESH MATERIALIZED VIEW`.

4. **Trigger summary:** [`021_daily_revenue_trigger.sql`](../database/postgres/migrations/021_daily_revenue_trigger.sql) maintains a summary for captured payment inserts and backfills the seed data. It does not adjust the summary for later status corrections or deletes; [`rebuild_daily_revenue_for`](../database/postgres/migrations/021_daily_revenue_trigger.sql) repairs it manually.

5. **Test cases:** All six required changes are in [`reporting_cases.sql`](../database/postgres/experiments/reporting_cases.sql), with the four results printed after every case. The direct query and function reflect corrections immediately. The materialized view waits for refresh. The insert-only trigger misses corrections and deletion. A repeated external reference is accepted by the starter schema and counted again; [`payment_reference_guard.sql`](../database/postgres/experiments/payment_reference_guard.sql) demonstrates rejecting it with a unique constraint.

6. **Comparison and recommendation:** The run results and comparison are in [the evidence report](evidence/lecture03/README.md). For this case, use the SQL function with `payments` as the source of truth. It keeps the calculation in one place and reflects corrections without a separate stored total to repair. If reads become costly, consider a materialized view with a clear refresh schedule and monitoring. Do not use the supplied insert-only trigger unless it is extended to handle corrections and deletes and given a reliable rebuild process.

7. **Required evidence:** The SQL definitions, before-and-after output, example disagreement, comparison, and final recommendation are linked above and documented in [the evidence report](evidence/lecture03/README.md).
