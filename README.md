# Compulsory Assignment 1 review guide

**Repository:** [mobilityticketing on GitHub](https://github.com/hplaursen/mobilityticketing). Make sure the lecturer and review group can access it.

**Submitted commit:** Add the exact commit hash to the Moodle form.

**Setup and reset:** Follow the README for the lecture you want to run: [Lecture 1](lecture-1/README.md), [Lecture 2](lecture-2/README.md), [Lecture 3](lecture-3/README.md), or [Lecture 4](lecture-4/README.md). Run commands from that lecture's folder. The ports are 54321 for Lecture 1, 54322 for Lecture 2, 54323 for Lecture 3, and 54324 for Lecture 4. Stop any other service using the same port. To reset the database, run `docker compose down -v` and then `docker compose up -d`.

## Where to find the work

- **Lecture 1 — routes and timetable:** [workload and assumptions](lecture-1/docs/lab.md), [ER diagram](lecture-1/database/postgres/er-diagram.md), [schema](lecture-1/database/postgres/001_relational_baseline.sql), [seed data](lecture-1/database/postgres/002_seed.sql), and [three queries](lecture-1/database/postgres/003_workload_queries.sql).
- **Lecture 2 — database rules:** [integrity map](lecture-2/docs/integrity-map-template.md), [constraints](lecture-2/database/postgres/migrations/011_ticketing_integrity.sql), [accepted writes](lecture-2/database/postgres/experiments/constraints_should_succeed.sql), [rejected writes](lecture-2/database/postgres/experiments/constraints_should_fail.sql), and [results](lecture-2/docs/evidence/lecture02/README.md).
- **Lecture 3 — revenue reports:** [base query](lecture-3/database/postgres/queries/base_revenue.sql), [SQL function](lecture-3/database/postgres/migrations/020_reporting_function.sql), [trigger summary](lecture-3/database/postgres/migrations/021_daily_revenue_trigger.sql), [materialized view](lecture-3/database/postgres/migrations/022_daily_captured_revenue.sql), [tests](lecture-3/database/postgres/experiments/reporting_cases.sql), [decision](lecture-3/docs/lab.md), and [results](lecture-3/docs/evidence/lecture03/README.md).
- **Lecture 4 — safe schema changes:** [lecture notes](lecture-4/docs/lab.md), [migration steps](lecture-4/database/postgres/migrations/), [old and new app tests](lecture-4/database/postgres/experiments/lecture04/), and [results, including ticket-price checks](lecture-4/docs/evidence/lecture04/README.md).

## Two decisions to discuss

1. **Identify each stop on a route by `(route_id, stop_sequence)`.** The alternative, `(route_id, stop_id)`, would not allow a route to visit the same stop twice. The sequence key fits routes with repeated stops and keeps their order clear. See the [ER diagram](lecture-1/database/postgres/er-diagram.md) and [schema](lecture-1/database/postgres/001_relational_baseline.sql).
2. **Use a SQL function to calculate revenue from `payments`.** The alternatives are a materialized view or a trigger summary. They store totals that can become outdated after payment changes. The function reads current payment data, which fits this reporting workload. See the [test results and decision](lecture-3/docs/evidence/lecture03/README.md).

## One limitation

The Lecture 2 capacity rule does not test two customers trying to buy the last seat at the same time. Next, test that situation and decide how the database should handle it. See the [integrity map](lecture-2/docs/integrity-map-template.md) and [test results](lecture-2/docs/evidence/lecture02/README.md).
