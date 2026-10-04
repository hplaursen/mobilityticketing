# Lecture 3 reporting experiment evidence

The results below were collected from the Lecture 3 PostgreSQL seed data after applying migrations `020`, `021`, and `022`. Revenue date is calculated in UTC. Each result is `DKK amount / captured payment count` for `OP-METRO` on `2026-04-29`.

The reference query returned:

| Operator | Date | Amount | Captured payments |
| --- | --- | ---: | ---: |
| OP-BUS | 2026-04-29 | 36.00 DKK | 1 |
| OP-METRO | 2026-04-29 | 36.00 DKK | 1 |

## Results after each test case

| Checkpoint | Direct query | SQL function | Materialized view | Trigger summary |
| --- | ---: | ---: | ---: | ---: |
| Baseline | 36 / 1 | 36 / 1 | 36 / 1 | 36 / 1 |
| 1. Insert captured payment, 36 DKK | 72 / 2 | 72 / 2 | 36 / 1 | 72 / 2 |
| 2. Insert failed payment, 50 DKK | 72 / 2 | 72 / 2 | 36 / 1 | 72 / 2 |
| 3. Change failed payment to captured | 122 / 3 | 122 / 3 | 36 / 1 | 72 / 2 |
| 4. Change new captured payment to refunded | 86 / 2 | 86 / 2 | 36 / 1 | 72 / 2 |
| 5. Delete the corrected payment | 36 / 1 | 36 / 1 | 36 / 1 | 72 / 2 |
| 6. Insert a duplicate gateway reference | 72 / 2 | 72 / 2 | 36 / 1 | 108 / 3 |
| Refresh the materialized view | 72 / 2 | 72 / 2 | 72 / 2 | 108 / 3 |
| Rebuild the trigger summary | 72 / 2 | 72 / 2 | 72 / 2 | 72 / 2 |

The materialized view matched the direct query after refresh. The trigger summary matched after a rebuild. After removing the duplicate test row and adding a unique constraint on `payments.external_payment_reference`, all four approaches returned 36 / 1. A repeated gateway reference was then rejected with SQLSTATE `23505`.

## Commands and files used

- Reference query: [`base_revenue.sql`](../../../database/postgres/queries/base_revenue.sql)
- Four-way comparison query: [`compare_daily_revenue.sql`](../../../database/postgres/queries/compare_daily_revenue.sql)
- Six test cases with a comparison after each: [`reporting_cases.sql`](../../../database/postgres/experiments/reporting_cases.sql)
- Duplicate-reference guard check: [`payment_reference_guard.sql`](../../../database/postgres/experiments/payment_reference_guard.sql)

The valid comparison script completed every case. Refreshing changed the materialized view from its old snapshot to the current base-table result. Rebuilding changed the trigger summary from 108 / 3 to 72 / 2. The duplicate guard cleanup and constraint succeeded, and the repeated-reference assertion reported SQLSTATE `23505` as expected.
