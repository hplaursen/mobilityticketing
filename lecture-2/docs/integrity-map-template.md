# Lecture 2 integrity map

The migration provides the database checks listed below. Invalid writes are in [`constraints_should_fail.sql`](../database/postgres/experiments/constraints_should_fail.sql), and valid example writes are in [`constraints_should_succeed.sql`](../database/postgres/experiments/constraints_should_succeed.sql). Results are recorded in [Lecture 2 evidence](evidence/lecture02/README.md).

| Invariant | Affected data | Classification and current owner | Expected failure / limitation | Evidence |
| --- | --- | --- | --- | --- |
| Trip capacity is zero or greater. | `trips.capacity` | Column check in PostgreSQL. | Negative value: CHECK, SQLSTATE `23514`. | Test 1 |
| Reserved seats are from zero through capacity. | `trips.reserved_seats`, `trips.capacity` | Row check in PostgreSQL. | Negative or over-capacity value: CHECK, `23514`. Concurrent booking still needs transaction handling. | Test 2; issue 1 |
| Product price is zero or greater. | `products.price` | Column check in PostgreSQL. | Negative value: CHECK, `23514`. | Test 8 |
| Ticket price is zero or greater. | `tickets.price` | Column check in PostgreSQL. | Negative value: CHECK, `23514`. | Test 9 |
| Payment amount is zero or greater. | `payments.amount` | Column check in PostgreSQL. | Negative value: CHECK, `23514`. | Test 11 |
| Currency is present and uses three uppercase letters. | Product, ticket, and payment currency | NOT NULL and format checks in PostgreSQL. | Missing value: NOT NULL, `23502`; malformed value: CHECK, `23514`. | Tests 9 and 21 cover malformed and missing values |
| A ticket refers to an existing user, trip, and product. | `tickets.user_id`, `trip_id`, `product_code` | Foreign keys in PostgreSQL. | Missing parent: FOREIGN KEY, `23503`. | Tests 3–4 and 18 |
| Ticket codes are present and unique. | `tickets.ticket_code` | NOT NULL and UNIQUE in PostgreSQL. | Missing code: NOT NULL, `23502`; duplicate code: UNIQUE, `23505`. | Tests 6 and 20 |
| Ticket validity ends after it starts. | `tickets.valid_from_utc`, `valid_to_utc` | Row check in PostgreSQL. | Reversed or equal times: CHECK, `23514`. | Test 5 |
| Ticket and payment statuses use the accepted values. | `tickets.status`, `payments.status` | CHECK constraints in PostgreSQL. | Unknown status: CHECK, `23514`. | Tests 7 and 13 |
| A payment refers to an existing user and ticket. | `payments.user_id`, `ticket_id` | Foreign keys in PostgreSQL. | Missing parent: FOREIGN KEY, `23503`. | Tests 11 and 19 |
| An external payment reference is recorded at most once. | `payments.external_payment_reference` | NOT NULL and UNIQUE in PostgreSQL. | Repeated reference: UNIQUE, `23505`. This prevents duplicate rows for one reference but does not make an external charge and database commit atomic. | Test 14; issue 2 |
| A validation's ticket ID and ticket code identify the same ticket. | `validations.ticket_id`, `ticket_code` | Composite foreign key in PostgreSQL. | Unknown or mismatched identity: FOREIGN KEY, `23503`. | Tests 15–16 |
| A validation refers to an existing stop. | `validations.stop_id` | Foreign key in PostgreSQL. | Missing stop: FOREIGN KEY, `23503`. | Test 17 |
| A disabled user cannot buy a ticket. | `users.is_disabled`, `tickets.user_id` | Cross-row business rule; application/transaction policy for this lecture. | A simple CHECK cannot read the referenced user row. Decide enforcement in the transactions lecture. | Open question |

## Invariants for the transactions lecture

### Issue 1: Reserve capacity together with ticket creation

- **Evidence:** `trips` stores `capacity` and `reserved_seats`; a CHECK rejects a row where reserved seats exceed capacity.
- **Problem:** Two purchases can compete for the final seat. The CHECK protects a row value but does not by itself define a safe purchase transaction.
- **Consequence:** The booking flow must coordinate the capacity update and ticket insert so a failed purchase does not leave a reservation behind.
- **Next:** Test concurrent purchases and choose an atomic update or locking strategy.

### Issue 2: Payment gateway and database commit

- **Evidence:** `payments.external_payment_reference` is unique in the database.
- **Problem:** A database constraint cannot make a remote payment capture and a PostgreSQL transaction commit as one atomic operation.
- **Consequence:** A timeout or retry could leave a captured charge without a matching local state, or cause a duplicate request.
- **Next:** Define idempotent payment requests and a reconciliation or retry process.

## State-transition trace

### Ticket purchase

1. Check that the user, trip, and product exist, and determine the agreed price.
2. Confirm capacity and create the ticket and payment record as one logical operation.
3. If any database write fails, roll back the local changes. External payment capture still needs its own workflow.

### Ticket validation

1. Find the ticket by its ID and code; the composite foreign key prevents pairing one ticket ID with another ticket's code.
2. Check whether the ticket may be used at this time. The current schema does not enforce this time/status policy.
3. Insert a validation linked to the ticket identity and stop.

## Delete and update decisions

Foreign keys use PostgreSQL's default `NO ACTION` behavior: referenced users, trips, products, tickets, and stops cannot be deleted while dependent records remain. This is appropriate for preserving ticket, payment, and validation history. Product codes and ticket identities should not be changed when doing so would alter the meaning of historical records; use a staged migration or a new record instead.
