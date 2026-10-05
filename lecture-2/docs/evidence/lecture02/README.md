# Lecture 2 database evidence

The integrity migration was applied to the Lecture 2 PostgreSQL database with `ON_ERROR_STOP=1`. PostgreSQL completed all statements and committed the transaction.

## Valid writes

Ran [`constraints_should_succeed.sql`](../../../database/postgres/experiments/constraints_should_succeed.sql). The capacity update and the user, ticket, payment, and validation inserts all succeeded. The script then rolled back the transaction, so the example rows were not retained.

## Rejected writes

Ran [`constraints_should_fail.sql`](../../../database/postgres/experiments/constraints_should_fail.sql). All 21 invalid writes were rejected by their named constraints. With verbose psql errors enabled, PostgreSQL reported:

| SQLSTATE | Meaning | Cases |
| --- | --- | --- |
| `23514` | CHECK violation | 1, 2, 5, 7, 8, 9, 10, 12, 13 |
| `23503` | Foreign-key violation | 3, 4, 11, 15, 16, 17, 18, 19 |
| `23505` | Unique violation | 6, 14 |
| `23502` | NOT NULL violation | 20, 21 |

The cases cover negative capacity and prices, excess reserved seats, missing references, invalid currencies and statuses, invalid ticket times, repeated ticket/payment identifiers, and mismatched validation ticket identity.
