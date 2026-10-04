# Lecture 1 — Moodle answers

This short version answers the six Lecture 1 tasks listed in Moodle. The SQL and ER diagram are kept in their project files and linked below.

## Work in this lecture

1. **Tables:** The schema defines `operators`, `routes`, `stops`, `route_stops`, and `trips` in [`001_relational_baseline.sql`](../database/postgres/001_relational_baseline.sql).

2. **Primary key for `route_stops`:** The primary key is `(route_id, stop_sequence)`. A route may visit the same stop more than once, so `stop_id` cannot identify a route position by itself. The sequence identifies each visit along that route.

3. **Primary and foreign keys:** The schema gives each main entity its own primary key. `routes.operator_id` references `operators`; `trips.route_id` references `routes`; and `route_stops` references both `routes` and `stops`. Its composite primary key is `(route_id, stop_sequence)`. See [`001_relational_baseline.sql`](../database/postgres/001_relational_baseline.sql).

4. **Seed data:** The supplied operators, routes, stops, route-stop positions, and trips are inserted by [`002_seed.sql`](../database/postgres/002_seed.sql).

5. **Workload queries:** The three queries are in [`003_workload_queries.sql`](../database/postgres/003_workload_queries.sql): the next 20 scheduled trips for a route, that route's stops in sequence, and scheduled-trip counts for all routes on a service date, including routes with no trips.

6. **Schema and ER diagram comparison:** The diagram in [`er-diagram.md`](../database/postgres/er-diagram.md) matches the five implemented tables, their keys, and their relationships. One detail is that the database permits a route to have no stop positions; route `LINE-8B` in the seed data has none. The diagram reflects this by allowing zero or more route-stop positions for a route.
