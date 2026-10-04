# Lecture 4 lab answers

This document expands the Moodle answers with the migration reasoning, rollout checks and open limitation.

## Migration approach

Use an expand/backfill/contract rollout. The expand migration gives each existing product a generated UUID and keeps the product code key available. `tickets.product_id` begins nullable so old writers continue to work. A `NOT VALID` foreign key applies to new writes immediately and can be validated after existing rows have been backfilled.

The expand migration uses a three-second lock timeout to fail rather than wait indefinitely for a table lock. On a much larger table, check whether adding the default rewrites the table on the target PostgreSQL version, schedule DDL for a quiet period, use concurrent index builds where possible, and backfill in bounded batches with progress monitoring.

The transitional reader prefers `product_id` and falls back to the code only while the ID is null. The transitional writer accepts a product ID, looks up the current code, and writes both references. This implementation ignores a conflicting supplied code and stores the code found through the ID. Product ID and product code identify the catalogue product; the ticket's price and currency record what the customer actually bought and must not be overwritten during migration.

The backfill is repeatable because it updates only null IDs. A second run should update no rows. After retiring old-only writers, run a final backfill, verify all IDs and relationships, validate the foreign key, and set `product_id` to `NOT NULL`. Remove the ticket's old code column only after all readers and writers use IDs and database dependencies have been inspected.

## Compatibility matrix

| Stage | Old reader | Old writer | Transitional reader | Transitional writer | ID-only reader/writer |
| --- | --- | --- | --- | --- | --- |
| Before expansion | Works | Works | Not deployed | Not deployed | Cannot work |
| After expansion, before backfill | Works | Works | Works via code fallback | Works when writing both | May miss tickets with null IDs |
| After backfill, ID still nullable | Works | Works; later backfill needed | Works | Works | Reader sees all; writer must dual-write the still-required code |
| ID required, both columns present | Reads | Fails because it omits ID | Works | Works | Works if the writer supplies product_code too |
| Legacy column removed | Fails | Fails | Fails if it still references code | Works only if changed to ID-only | Works |

The final reader uses an inner join, so before backfill it can silently omit tickets with null or invalid IDs. The verification query must show no such tickets before that reader is used as the only reader.

## Required checks and expected findings

- Baseline: three tickets cover two products, and all current product-code references resolve.
- Historical price: `TICKET-3` remains 65 DKK while DAY currently costs 80 DKK.
- Repeatability: first backfill fills existing and late old-writer rows; the second run changes zero rows and does not overwrite any previously assigned IDs.
- Referential integrity: null IDs, missing product IDs, and code/ID pairs resolving to different products all return zero rows before the contract stage.
- Mismatch probe: direct SQL can create a conflicting pair during the compatibility window unless every writer is controlled or an extra database rule is added. The transitional writer ignores a conflicting supplied code and stores the code looked up from the product ID. Once the old code column is removed, the duplicated-identity mismatch is no longer possible.
- Early `NOT NULL`: fails while any ticket has a null product ID. Once filled, the validated check allows PostgreSQL to establish the column as not-null.
- Legacy removal: dropping the code without `CASCADE` protects dependent database objects by failing if a dependency remains. The provided rehearsal checks views and functions and rolls back after proving the final ID-only SQL works.
- Product ID immutability: a database trigger prevents later changes to `products.id`; a UUID default alone would not provide that guarantee.

## Rollback and limitation

Before the contract stage, rolling back to an old application is possible because `product_code` remains populated and old writers can still write. After `product_id` becomes required, old-only writers fail; restore compatibility by deploying a dual-writing version or temporarily allowing null IDs. After dropping the legacy column, the old binary cannot run unchanged. Recovery needs a forward migration to add and backfill the code column or a compatibility view, followed by application rollback.

The database does not enforce that the two references point to the same product while both columns exist. Application code must reject conflicts, and the verification query must be part of the deployment gate. A stronger database guarantee could use a composite unique key and composite foreign key, but that adds schema work and is not required for this small staged exercise.

## Decision

Retire old-only writers before requiring `product_id`. Keep the compatibility column through the mixed-version period. Remove it only after the final verification is clean and ID-only readers and writers are deployed. The migration tests demonstrate why removing the code early breaks readers and writers, and the reversible final-stage rehearsal demonstrates that the new version can work without it.

## Files

- [Lecture lab](lab.md)
- [Moodle answers](moodle-answers.md)
- [Run evidence](evidence/lecture04/README.md)
- [Migrations](../database/postgres/migrations/)
- [SQL experiments](../database/postgres/experiments/lecture04/)
