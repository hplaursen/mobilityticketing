# Implementation lab: Where should reporting logic execute?

## Purpose

Implement and compare a direct SQL query, a user-defined function, a materialized view, and a trigger-maintained summary for daily captured revenue. Use the differences to decide where the responsibility belongs.

The aim is not to simply choose the option with the most or the least SQL. Make a fair comparison of the options. Take into account execution timing, dependencies, transaction scope, freshness, and recovery.

## Scenario

Operators need daily captured revenue. The initial design proposes a `daily_revenue_by_operator` table maintained when payments are inserted. Reports may also be calculated directly from the transactional tables or exposed through a materialized view.

The `payments` table is the authority for this experiment. Treat the stored reporting results as derived data.

## Before you start

Start the database from the repository root:

```bash
docker compose up -d
docker compose ps
```

Run the base query in [`../database/postgres/queries/base_revenue.sql`](../database/postgres/queries/base_revenue.sql) and save its result. Do not edit the files in `database/postgres/init/`.

## Tasks

1. Run the reference revenue query and verify its result from the base tables.
2. Wrap the read logic in a SQL function.
3. Create a materialized view and observe when it becomes stale.
4. Create the supplied trigger-maintained summary.
5. Test all four approaches against:
   - a captured payment insert;
   - a failed payment insert;
   - a status correction from `Failed` to `Captured`;
   - a correction from `Captured` to `Refunded`;
   - deletion or replacement of test data;
   - duplicate delivery of the same external payment reference.
6. Produce a responsibility matrix comparing correctness, freshness, write cost, read cost, hidden side effects, rebuildability, and operational complexity.
7. Recommend one approach for the current case. A hybrid answer is allowed, but each stored copy must have a clear authority and rebuild path.

The migration examples identify the intended object names. Complete them in dependency order and apply them from the repository root:

```bash
docker compose exec -T postgres psql -U mobility -d mobility < database/postgres/migrations/020_reporting_function.sql
docker compose exec -T postgres psql -U mobility -d mobility < database/postgres/migrations/021_daily_revenue_trigger.sql
docker compose exec -T postgres psql -U mobility -d mobility < database/postgres/migrations/022_daily_captured_revenue.sql
```

To reset to the original seed state, remove the database volume. Then reapply migrations `020`, `021`, and `022` in order before rerunning the experiment:

```bash
docker compose down -v
docker compose up -d
```

## Required evidence

- SQL object definitions for all four approaches.
- Output before and after each test case.
- One captured example where two approaches disagree.
- A side-effect trace showing everything caused by one payment write.
- A responsibility matrix with a named authority, freshness rule, and rebuild path.
- One issue in the issue register and one defended decision record.

## Side-effect trace

For one `INSERT INTO payments`, record:

1. constraints or references checked;
2. trigger execution, if any;
3. summary-table writes;
4. rows or locks touched, where observable;
5. commit or rollback behaviour;
6. the point at which each report becomes current;
7. what the application can observe.

## Your recommendation

What's your final recommendation?

It's important to not **only** choose the fastest option. Think about the effects on coupling, correction behavior, duplicate delivery, observability and recovery.

Remember that the lab does not require a final architecture. We will address problems like ticket-purchase concurrency and payment capture in later lectures.

## Answers to the Lecture 3 tasks

### 1. Reference revenue query

The query is in [`base_revenue.sql`](../database/postgres/queries/base_revenue.sql). 
On the seed data, it returns 36 DKK and one captured payment per operator for 2026-04-29.

### 2. SQL function

[`020_reporting_function.sql`](../database/postgres/migrations/020_reporting_function.sql) defines `captured_revenue_for_day`. 
It runs the query when called, so payment corrections appear right away. 

### 3. Materialized view

[`022_daily_captured_revenue.sql`](../database/postgres/migrations/022_daily_captured_revenue.sql) stores the daily totals. 
It becomes stale after a payment insert, correction, or delete. Refresh it to update the results.

### 4. Trigger-maintained summary

[`021_daily_revenue_trigger.sql`](../database/postgres/migrations/021_daily_revenue_trigger.sql) updates the summary for captured payment inserts. It misses later status corrections and deletes. The rebuild function can repair it.

### 5. Compare the four approaches against the test cases

The test cases are in [`reporting_cases.sql`](../database/postgres/experiments/reporting_cases.sql); results are in the [evidence report](evidence/lecture03/README.md). After a failed payment was corrected to captured, the query and function returned 122 DKK / 3 payments. The trigger summary returned 72 DKK / 2, and the materialized view remained at 36 DKK / 1 until refreshed.

The starter schema accepts duplicate external payment references. A unique constraint rejects a repeated reference with SQLSTATE `23505`, as shown in [`payment_reference_guard.sql`](../database/postgres/experiments/payment_reference_guard.sql).

### 6. Responsibility matrix

| Approach | Correctness and freshness | Cost and side effects | Rebuild or upkeep |
|---|---|---|---|
| Direct query | Current when queried. | Aggregates source rows on every read. No extra writes. | No stored result to rebuild. |
| SQL function | Same result and freshness as the query. | Same query cost. Keeps the logic in one place. | No stored result to rebuild. |
| Materialized view | Current only after refresh. | Fast reads; refresh does the aggregation. | Refresh from `payments`; set a schedule and monitor it. |
| Trigger summary | Correct for captured inserts; stale after corrections or deletes. | Adds hidden writes to payment transactions. | Needs correction handling, monitoring, and a rebuild path. |

No performance timings were collected. The comparison is based on behavior and responsibilities.

### 7. Recommend an approach

Use the SQL function for now, with `payments` as the source of truth. It reflects corrections and avoids a stored total that can go stale. If reports become slow, measure them and consider a materialized view with a refresh schedule and monitoring.

### Side-effect trace: captured payment insert

1. PostgreSQL checks the row's types and primary key. The starter schema does not check the ticket reference or payment-reference uniqueness.
2. The trigger looks up the ticket's trip and route. For a captured payment, it inserts or updates one daily summary row. For a failed payment, it does nothing.
3. The payment and summary writes commit or roll back together. Writes for the same operator and date can contend on the summary row.
4. After commit, the query and function see the payment. The trigger summary includes a captured insert. The materialized view stays at its last refresh.
5. The application sees the payment result. The trigger's summary write is hidden within that transaction.
