# Lecture 3 lab answers

This document answers the full `docs/lab.md`, including its side-effect trace, responsibility matrix, issue, and decision record. The Moodle task list covers the same four approaches and six test cases; the lab spells out more of the evidence expected.

## Result and recommendation

The `payments` table is the source of truth. The direct query and SQL function read that source each time. The materialized view and trigger summary are stored copies, so each needs a freshness rule and a repair path.

For the current workload, I recommend the SQL function. It keeps the calculation in one place and reflects payment corrections immediately. The seed dataset is small and no performance measurements show a need to store a second copy. If reporting reads become expensive, measure them and consider a materialized view with an agreed maximum age, scheduled refresh, failure monitoring, and a rebuild from `payments`. I do not recommend the supplied insert-only trigger for this report because it becomes wrong after corrections and deletes.

## Responsibility matrix

| Approach | Correctness and freshness | Read and write cost | Side effects | Rebuild and operating effort |
| --- | --- | --- | --- | --- |
| Direct query | Current as of the query's database snapshot. | Joins and aggregates on every read; no extra write work. | None beyond reading source rows. | No stored copy to rebuild; simplest option. |
| SQL function | Same result and freshness as the direct query. | Same underlying query cost; no extra write work. | None; it centralizes the read logic. | No stored copy to rebuild; easy to call consistently. |
| Materialized view | Correct as of its last successful refresh; stale until refreshed. | Fast reads from stored totals; refresh pays the aggregation cost. | No work during payment writes. | Rebuild by refreshing from `payments`; needs a refresh schedule, age target, and failure monitoring. |
| Insert-only trigger summary | Immediate for captured inserts; wrong after status corrections and deletes until rebuilt. | Adds a route lookup and summary-row write to each captured payment insert. | Hidden writes and row-lock contention occur inside the payment transaction. | Manual rebuild exists; needs correction/delete handling and operational monitoring to be safe. |

The table describes observed behavior and work involved, not benchmarked speed. No performance timings were collected.

## Test results

The full output after each case is recorded in [Lecture 3 evidence](evidence/lecture03/README.md). One clear disagreement occurred after case 3, when the failed payment was corrected to captured: the direct query and function returned 122 DKK / 3 payments, but the trigger summary still returned 72 DKK / 2. The materialized view remained at its earlier 36 DKK / 1 until refreshed.

The duplicate-reference case shows a different issue. The starter schema accepted the second row with the same gateway reference. The direct query and function then counted 72 DKK / 2, while the trigger summary temporarily counted 108 DKK / 3 because it had already missed earlier corrections and deletion. After refreshing and rebuilding, the four methods agreed at 72 DKK / 2; they all agreed on the duplicate data, which does not prove that the data itself is correct. A unique constraint then rejected a repeated reference with SQLSTATE `23505` after the test duplicate was removed.

## Side-effect trace: one captured payment insert

1. PostgreSQL checks the payment row's primary key and column types. The starter schema has no foreign key from `payments.ticket_id` to `tickets.id` and no uniqueness rule on `external_payment_reference`.
2. The AFTER INSERT trigger runs. For a captured payment, it joins the ticket to its trip and route to find the operator. For a failed payment, it returns without changing the summary.
3. The trigger inserts or increments one `daily_revenue_by_operator` row for that operator and UTC payment date.
4. The payment row and summary update are part of the same transaction. Inserts for the same operator and date can contend on the same summary row.
5. If the trigger fails, the payment insert fails too; rollback undoes both writes. The materialized view is not changed by the payment write.
6. After commit, a direct query and the function see the payment. The trigger summary also reflects a captured insert. The materialized view stays at its last refresh.
7. The application sees success or failure for the payment insert, but the summary update is hidden inside the trigger. The materialized-view refresh is a separate operation.

## Issue register

### Issue: the supplied trigger misses corrections and deletes

- **Evidence:** Cases 3–5 show the direct result changing to 122 / 3, then 86 / 2, then 36 / 1, while the trigger stays at 72 / 2.
- **Problem:** The trigger only handles captured inserts.
- **Consequence:** Reports silently disagree with the authoritative payment rows after normal corrections or deletions.
- **Improvement:** Prefer the SQL function for now. If a stored summary is later justified, handle INSERT, UPDATE, and DELETE and keep a tested rebuild path.
- **Open question:** What freshness target and payment-correction policy should reports promise?

## Decision record

- **Decision:** Use the SQL function for the current reporting workload; keep `payments` authoritative.
- **Alternative:** Use a materialized view refreshed on a schedule, or a trigger-maintained summary.
- **Reason:** The function has one shared definition, follows corrections immediately, and avoids hidden writes. The lab provides no performance evidence that justifies a stored copy.
- **Revisit when:** Measured report cost becomes a problem. If using a materialized view, specify its maximum age and monitor refresh success. If using a trigger summary, prove correction, delete, duplicate, and rebuild behavior first.

## SQL objects and evidence

- Reference query: [`base_revenue.sql`](../database/postgres/queries/base_revenue.sql)
- Function: [`020_reporting_function.sql`](../database/postgres/migrations/020_reporting_function.sql)
- Trigger summary and rebuild function: [`021_daily_revenue_trigger.sql`](../database/postgres/migrations/021_daily_revenue_trigger.sql)
- Materialized view: [`022_daily_captured_revenue.sql`](../database/postgres/migrations/022_daily_captured_revenue.sql)
- Test cases: [`reporting_cases.sql`](../database/postgres/experiments/reporting_cases.sql)
- Duplicate-reference follow-up: [`payment_reference_guard.sql`](../database/postgres/experiments/payment_reference_guard.sql)
- Recorded output: [Lecture 3 evidence](evidence/lecture03/README.md)
