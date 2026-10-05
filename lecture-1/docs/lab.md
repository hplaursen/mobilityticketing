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



## Answers to the Lecture 1 tasks

### ER diagram

ER diagram can be found here: [`er-diagram.md`](../database/postgres/er-diagram.md). It shows the tables, identifiers, relationships, and cardinalities.

### Modelling assumption

A route can visit the same stop more than once. Each visit has its own `stop_sequence`, so `route_stops` uses `(route_id, stop_sequence)` as its primary key. This supports loop routes.

### System context

MobilityTicketing brings bus, tram, and train information together. Customers search for journeys, check departures, and see delays. Operators maintain routes and timetables. Lecture 1 covers operators, routes, stops, route positions, and trips. Ticket sales and live availability are not included yet.

### Access-pattern map

| Workload | Main data used | What matters most |
|---|---|---|
| Journey search | Routes, stops, route positions, trips | Fast reads; slightly old data is okay. |
| Ticket purchase | Trips, products, capacity, tickets, payments | Correct price and availability. Do not oversell. |
| Ticket validation | Tickets and validations | Quick ticket checks when passengers board. |
| Timetable maintenance | Routes and trips | Operators can update schedules. Searches should show updates. |
| Real-time availability | Trips and remaining capacity | Search can use an estimate. Purchase needs a reliable check. |
| Reporting | Tickets, payments, validations | Correct history; a small delay is okay. |

Lecture 1 only implements route and timetable data. The other workloads may be added later.

### Functional dependency

In `route_stops`, `(route_id, stop_sequence)` determines `stop_id`. Each route position has one stop. The sequence is part of the key because a route can visit the same stop more than once.

Stop names and city IDs are stored once in `stops`. This avoids repeating and updating the same stop details in several rows.

### Comparing implemented schema with ER diagram

The diagram matches the five tables and their keys in `database/postgres/001_relational_baseline.sql`. Both use `(route_id, stop_sequence)` for `route_stops`. A route can have no stops yet. In the seed data, M2 and 5C have stops; 8B does not.

### What the implementation proves and what remains unknown

This implementation shows that trips belong to routes and route positions point to routes and stops. It does not cover ticket purchases, live capacity, or timetable validity.

### Representative results for the three workload queries

Verified by running [`database/postgres/003_workload_queries.sql`](../database/postgres/003_workload_queries.sql) against the Lecture 1 database.

1. `LINE-5C` returned two trips: `TRIP-5C-2024-06-01-09:00` at 07:00 UTC and `TRIP-5C-2024-06-01-09:15` at 07:15 UTC.
2. `LINE-5C` stops, in order: Copenhagen Central Station, Kongens Nytorv, Nørreport.
3. On `2024-06-01`, trip counts were M2: 2, 5C: 2, and 8B: 0. Route 8B was included even though it had no trips.
