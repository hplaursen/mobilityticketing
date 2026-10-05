# Lecture 2 integrity map

The migration provides database constraints for the rules owned by PostgreSQL. The disabled-user purchase rule remains a domain or application policy. Invalid writes are in [`constraints_should_fail.sql`](../database/postgres/experiments/constraints_should_fail.sql), and valid example writes are in [`constraints_should_succeed.sql`](../database/postgres/experiments/constraints_should_succeed.sql). Results are recorded in [Lecture 2 evidence](evidence/lecture02/README.md).

Here, **business rule** means the domain rule expressed as an invariant. **Owner** means the component responsible for enforcing it, such as PostgreSQL, the application, a transaction workflow, or an external service.

| Business rule (invariant) | Current owner | Affected tables | Expected failure behaviour | Remaining limitation |
| --- | --- | --- | --- | --- |
| Trip capacity is zero or greater. | PostgreSQL CHECK constraint. | `trips` | Negative value: CHECK violation, SQLSTATE `23514`. | None for this row-level rule. |
| Reserved seats are from zero through capacity. | PostgreSQL CHECK constraint. | `trips` | Negative or over-capacity value: CHECK violation, `23514`. | Concurrent bookings need transaction handling. |
| Product price is zero or greater. | PostgreSQL CHECK constraint. | `products` | Negative value: CHECK violation, `23514`. | None for this row-level rule. |
| Ticket price is zero or greater. | PostgreSQL CHECK constraint. | `tickets` | Negative value: CHECK violation, `23514`. | None for this row-level rule. |
| Payment amount is zero or greater. | PostgreSQL CHECK constraint. | `payments` | Negative value: CHECK violation, `23514`. | None for this row-level rule. |
| Currency is present and uses three uppercase letters. | PostgreSQL NOT NULL and CHECK constraints. | `products`, `tickets`, `payments` | Missing value: NOT NULL violation, `23502`; malformed value: CHECK violation, `23514`. | The three-letter uppercase format is the chosen currency rule. |
| A ticket refers to an existing user, trip, and product. | PostgreSQL foreign keys. | `tickets`, `users`, `trips`, `products` | Missing parent row: FOREIGN KEY violation, `23503`. | None for these references. |
| Ticket codes are present and unique. | PostgreSQL NOT NULL and UNIQUE constraints. | `tickets` | Missing code: NOT NULL violation, `23502`; duplicate code: UNIQUE violation, `23505`. | None for ticket-code lookup. |
| Ticket validity ends after it starts. | PostgreSQL CHECK constraint. | `tickets` | Reversed or equal times: CHECK violation, `23514`. | None for this row-level rule. |
| Ticket and payment statuses use the accepted values. | PostgreSQL CHECK constraints. | `tickets`, `payments` | Unknown status: CHECK violation, `23514`. | The accepted status lists may need a domain decision later. |
| A payment refers to an existing user and ticket. | PostgreSQL foreign keys. | `payments`, `users`, `tickets` | Missing parent row: FOREIGN KEY violation, `23503`. | Does not ensure an external payment was captured. |
| An external payment reference is recorded at most once. | PostgreSQL NOT NULL and UNIQUE constraints. | `payments` | Repeated reference: UNIQUE violation, `23505`. | Does not make an external charge and database commit atomic. |
| A validation's ticket ID and ticket code identify the same ticket. | PostgreSQL composite foreign key. | `validations`, `tickets` | Unknown or mismatched identity: FOREIGN KEY violation, `23503`. | None for matching the stored ticket identity. |
| A validation refers to an existing stop. | PostgreSQL foreign key. | `validations`, `stops` | Missing stop: FOREIGN KEY violation, `23503`. | Does not decide which stop a validation should record. |
| Whether a disabled user may buy a ticket. | Domain decision; application or transaction policy until decided. | `users`, `tickets` | The purchase should be rejected if the policy forbids disabled users. | A simple CHECK cannot read the referenced user row. |

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

1. Read the existing user row in `users`, trip row in `trips`, and product row in `products`. Check the trip's `reserved_seats` against its `capacity`.
2. Update `trips.reserved_seats` for that trip.
3. Insert the ticket row in `tickets`, referencing the user, trip, and product.
4. Insert the payment row in `payments`, referencing the user and new ticket.
5. Commit the database transaction. If a write fails, roll back the update and inserts.

### Ticket validation

1. Read the ticket row in `tickets` by ID and code. Both must identify the same ticket.
2. Read the existing stop row in `stops`.
3. Insert a validation row in `validations`, referencing the ticket and stop.

## Delete and update decisions

The database blocks deleting a user, trip, product, ticket, or stop if another row refers to it. It also blocks changing an ID while other rows use it. This keeps the links between records intact. The database does not stop someone changing a ticket's price or currency, so keep the values the customer paid and record corrections separately. Use a retention policy or soft deletion if records need to be hidden.
