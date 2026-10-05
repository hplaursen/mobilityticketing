# Lecture 2 implementation lab: Make invalid states difficult to store

## Purpose

Strengthen the initial PostgreSQL schema for ticket purchase and validation. The focus is not API validation. The focus is what the database can guarantee when writes arrive from different applications, scripts, or future services.

## Starting point

The course starter infrastructure contains a deliberately weak schema for trips, products, tickets, payments, and validations. It accepts several states that conflict with the MobilityTicketing case.

Read the supplied DDL before changing anything. Add constraints through a new migration. Do not edit the starter DDL.

## Tasks

1. Extract at least ten domain invariants from the scenario and schema.
2. Classify each invariant as one of:
   - directly enforceable with a column or table constraint;
   - enforceable with a unique or exclusion rule;
   - dependent on more than one row or an external system;
   - currently ambiguous and requiring a domain decision.
3. Implement the constraints that belong in this lecture.
4. Write negative tests that attempt invalid inserts or updates.
5. Record at least two important invariants that cannot be solved by a simple constraint. Keep them for the transactions lecture.

## Minimum invariants to consider

- Capacity cannot be negative.
- Reserved seats cannot be negative or greater than capacity.
- Ticket price and payment amount cannot be negative.
- Currency must be present and consistently represented.
- Ticket codes must support unambiguous lookup.
- A payment must refer to an existing ticket.
- A validation must refer to an existing ticket.
- A ticket validity end cannot be earlier than its start.
- Status values must come from a known set.
- An external payment reference should not be recorded twice when it represents one captured payment.
- A validation must not combine the identifier of one ticket with the code of another.

## Required evidence

For every implemented invariant, include:

- the rule in plain language;
- the DDL used to enforce it;
- one write that succeeds;
- one write that fails;
- the database error or result that demonstrates enforcement.

Assert PostgreSQL SQLSTATE codes in automated tests where possible. Matching an English error string is brittle and language-dependent.

## State-transition trace

Trace ticket purchase and ticket validation at the row and relationship level. Describe which rows are inserted or updated and which references must already exist. Do not analyse concurrency yet.

## Delete and update behaviour

Inspect the relationships for historical tickets, payments, and validations. For each relationship, state whether deletion should be restricted, cascaded, soft-deleted, or governed by a retention policy. Also state whether an update should be allowed or rejected when it would change historical meaning.

## Integrity map

Create an integrity map that connects each business rule to its current owner, affected tables, expected failure behaviour, and remaining limitation.

## Important boundary

A row-level check can protect `reserved_seats <= capacity` for one row. It cannot arbitrate two concurrent purchases that both observe the same remaining capacity. Do not claim that this migration solves that race.

Payment capture across an external gateway and PostgreSQL also needs workflow design. A disabled-user purchase rule may be a domain or transaction policy depending on the case decision. Classify these limits explicitly.

## Answers to the Lecture 2 tasks

### 1–2. Extract and classify at least ten domain invariants

The table puts each rule in the matching category.

| Invariant | Classification from the task |
|---|---|
| Trip capacity cannot be negative. | Directly enforceable with a column constraint |
| Reserved seats cannot be negative or exceed capacity. | Directly enforceable with a table constraint |
| Product, ticket, and payment amounts cannot be negative. | Directly enforceable with a column constraint |
| Currency must be present and use three uppercase letters. | Directly enforceable with a column constraint |
| Tickets must refer to an existing user, trip, and product. | Directly enforceable with a table constraint |
| Ticket codes must be present and unique. | Directly enforceable with a column constraint (`NOT NULL`) and a table constraint (`UNIQUE`) |
| Ticket validity must end after it starts. | Directly enforceable with a table constraint |
| Ticket and payment statuses must use known values. | Directly enforceable with a column constraint |
| Payments must refer to an existing user and ticket. | Directly enforceable with a table constraint |
| External payment references must be unique. | Enforceable with a unique or exclusion rule |
| A validation's ticket ID and code must identify the same ticket. | Directly enforceable with a table constraint |
| A validation must refer to an existing stop. | Directly enforceable with a table constraint |
| Whether a disabled user may buy a ticket. | Currently ambiguous and requiring a domain decision |
| Two purchases cannot reserve the same final seat. | Dependent on more than one row |
| Payment capture and database writes must stay consistent. | Dependent on an external system |

See the [integrity map](integrity-map-template.md) for affected data and expected failures.

### 3. Implement the constraints for this lecture

The constraints are in [`011_ticketing_integrity.sql`](../database/postgres/migrations/011_ticketing_integrity.sql). It adds checks, foreign keys, unique rules, and required fields.

### 4. Write negative tests for invalid inserts and updates

Invalid writes are in [`constraints_should_fail.sql`](../database/postgres/experiments/constraints_should_fail.sql). Valid writes are in [`constraints_should_succeed.sql`](../database/postgres/experiments/constraints_should_succeed.sql). All 21 invalid writes failed. The [evidence report](evidence/lecture02/README.md) lists the SQLSTATE codes.

### 5. Record invariants for the transactions lecture

1. **Capacity and ticket creation:** Reserve a seat and create the ticket together. Concurrent purchases must not exceed capacity.
2. **Payment and database consistency:** A database transaction cannot include the external payment gateway's action. We need a plan for failures and retries.

The [integrity map](integrity-map-template.md) covers the related rules and limitations.

### Minimum invariants to consider

The migration enforces these rules:

- Capacity cannot be negative. Reserved seats must be between zero and capacity.
- Ticket prices and payment amounts cannot be negative.
- Currency is required and must use three uppercase letters.
- Ticket codes are required and unique.
- Payments must refer to an existing ticket. Validations must refer to an existing ticket and stop.
- A ticket's end time must be after its start time.
- Ticket and payment statuses must use the allowed values.
- External payment references must be unique.
- A validation's ticket ID and code must identify the same ticket.

### Required evidence for implemented invariants

The [migration](../database/postgres/migrations/011_ticketing_integrity.sql) contains the DDL. The [valid-write script](../database/postgres/experiments/constraints_should_succeed.sql) has valid trip, user, ticket, payment, and validation writes. The [negative-test script](../database/postgres/experiments/constraints_should_fail.sql) has 21 invalid writes. The [integrity map](integrity-map-template.md) links rules to failing tests. The [evidence report](evidence/lecture02/README.md) lists the SQLSTATE codes.

One valid write can show that several rules work. The evidence does not give each rule its own successful write. PostgreSQL's SQLSTATE codes were recorded, but the scripts do not check those codes automatically.

### State-transition trace

**Ticket purchase**

1. Read the user's row in `users`, the trip's row in `trips`, and the product's row in `products`. These rows must already exist. Check `reserved_seats` against `capacity` in the trip row.
2. Update that trip's `reserved_seats` in `trips`.
3. Insert a row in `tickets` with the user ID, trip ID, and product code.
4. Insert a row in `payments` with the user ID and new ticket ID.
5. Commit the transaction. If a database write fails, roll back the update and inserts.

**Ticket validation**

1. Read the ticket's row in `tickets` using its ID and code. They must identify the same ticket.
2. Read the stop's row in `stops`. The stop must already exist.
3. Insert a row in `validations` with the ticket ID, ticket code, and stop ID, plus the validation details.

The foreign keys check that the ticket and stop exist. The composite foreign key rejects a ticket ID paired with another ticket's code.

### Delete and update behaviour

For these relationships, keep the historical row and restrict deletion of a row it refers to:

- `tickets.user_id` → `users.id`: restrict deletion. Reject changing the ticket to a different user.
- `tickets.trip_id` → `trips.id`: restrict deletion. Reject changing the ticket to a different trip.
- `tickets.product_code` → `products.code`: restrict deletion. Reject changing the ticket to a different product.
- `payments.user_id` → `users.id`: restrict deletion. Reject changing the payment to a different user.
- `payments.ticket_id` → `tickets.id`: restrict deletion. Reject changing the payment to a different ticket.
- `validations.(ticket_id, ticket_code)` → `tickets.(id, ticket_code)`: restrict deletion. Reject changing the validation to a different ticket.
- `validations.stop_id` → `stops.id`: restrict deletion. Reject changing the stop recorded for a validation.

The foreign keys restrict deletion, but they do not prevent changing a reference to another existing row. The application must reject changes that would rewrite history. The database also does not stop someone changing a ticket's price or currency, so keep the values the customer paid and record corrections separately. Use a retention policy or soft deletion if records need to be hidden.
