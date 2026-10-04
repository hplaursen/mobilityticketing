# Lecture 1 implementation lab

## Purpose

Build the smallest relational model that supports route maintenance and upcoming-trip queries. The implementation is not expected to represent the complete MobilityTicketing platform. It should make your modelling assumptions executable.

## Timebox

Approximately 90 minutes.

## Work in this lecture

1. Create tables for operators, routes, stops, route stops, and trips.
2. Decide the primary key of the route-stop relation and explain the decision.
3. Add primary-key and foreign-key relationships.
4. Insert the supplied seed data.
5. Write the three workload queries in `database/postgres/003_workload_queries.sql` (the starter skeleton is `database/postgres/003_queries.sql.example`).
6. Compare the implemented schema with your ER diagram and record any difference.

## Workload queries

1. Show the next 20 scheduled trips for a route after a supplied timestamp.
2. Show the ordered stops belonging to a route.
3. Show all routes and the number of scheduled trips on a supplied service date, including routes with no trips.

## Do not implement yet

Do not add MongoDB, Redis, caching, event queues, payment logic, validation logic, reporting tables, or performance indexes. Those decisions are introduced later.

## Required evidence

- A schema that can be recreated from an empty database.
- Seed data that can be loaded more than once without manual editing.
- The three queries and representative results.
- A short note identifying one modelling assumption that may change later.
- A system context, access-pattern map, ER diagram, and one functional dependency note.

## Submission checklist

- [ ] Describe the customers, operators, and city transport context without naming a database product.
- [ ] Cover route search, ticket purchase, ticket validation, timetable updates, real-time availability, and reporting in the access-pattern map.
- [ ] Include identifiers, relationships, and cardinalities in the ER diagram.
- [ ] Explain one functional dependency and what normalization prevents.
- [ ] State what the implementation proves and what remains unknown.
- [ ] Commit the implementation under `database/postgres/`.

## Student submission: model and assumption

The ER diagram for the Lecture 1 implementation is in [`database/postgres/er-diagram.md`](../database/postgres/er-diagram.md). It models the five implemented tables and their identifiers, relationships, and cardinalities.

**Assumption:** A route may visit the same stop more than once. Each visit is a distinct route position, identified by its `stop_sequence`; therefore, `route_stops` uses `(route_id, stop_sequence)` as its primary key instead of `(route_id, stop_id)`. This supports loop routes where the same stop can occur at multiple points in the route.

## System context

MobilityTicketing brings bus, tram, and train information together in one city transport platform. Customers use it to search for journeys, see departures, and check delays. Transport operators maintain routes and timetables. The Lecture 1 database covers the small relational part needed for operators, routes, stops, route positions, and trips. It does not yet implement ticket sales or live availability.

## Workload map

| Workload | Main data used | What matters most |
|---|---|---|
| Journey search | Routes, stops, route positions, trips | Fast reads; slightly old information can be acceptable. |
| Ticket purchase | Trips, products, capacity, tickets, payments | Correct price and availability; avoid selling beyond capacity. |
| Ticket validation | Tickets and validations | Find and check a ticket quickly while passengers board. |
| Timetable maintenance | Routes and trips | Operators can change schedules; searches should see updates. |
| Real-time availability | Trips and remaining capacity | Search can use a recent estimate; purchase needs a trustworthy check. |
| Reporting | Tickets, payments, validations | Historical results should be correct; a small delay is acceptable. |

Lecture 1 implements route and timetable data only. The other workloads are included to show what the larger system may need later.

## Functional dependency

In `route_stops`, `(route_id, stop_sequence)` determines `stop_id`: for a given route position, there is one stop. The sequence is part of the key because a route can visit the same stop more than once. Using only `(route_id, stop_id)` would incorrectly prevent that.

Stop names and city IDs are stored once in `stops`, rather than repeated for every route position. This avoids having to update the same stop details in several rows if its name changes.

## Compare the diagram with the implementation

The diagram matches the five tables and their primary and foreign keys in `database/postgres/001_relational_baseline.sql`. The `route_stops` key is `(route_id, stop_sequence)`, as shown in both. One detail is that the database does not require every route to have a stop yet; the diagram therefore allows a route to have zero or more route-stop rows. The seed data gives the M2 and 5C routes stop rows, while 8B currently has none.

This implementation proves that stored trips belong to routes and that each stored route position points to a route and a stop. It does not yet model ticket purchases, live capacity, or whether a timetable is operationally valid.

## Representative query results

The following are expected results from the current seed data and the queries in [`database/postgres/003_workload_queries.sql`](../database/postgres/003_workload_queries.sql). They have not been recorded from a database run.

1. For route `LINE-5C` after `2024-06-01 00:00:00+00`, the query should return its two seeded trips: `TRIP-5C-2024-06-01-09:00` and `TRIP-5C-2024-06-01-09:15`.
2. The ordered stops for `LINE-5C` should be Copenhagen Central Station, Kongens Nytorv, then Nørreport.
3. For service date `2024-06-01`, the scheduled trip counts should be M2: 2, 5C: 2, and 8B: 0. Route 8B should still appear because the query uses a left join and keeps the date and status filters in its `ON` clause.
