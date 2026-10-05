# Lecture 3 reporting experiment evidence

These starting figures come from the sample data, before the tests. Amounts are in DKK, dates use UTC, and the count includes only captured payments.

Before the tests, captured payments totalled:

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

After refreshing, the materialized view showed the current result. After rebuilding, the trigger summary showed it too. The database also rejected a second payment with the same gateway reference.

The six test cases were run using [`reporting_cases.sql`](../../../database/postgres/experiments/reporting_cases.sql).
