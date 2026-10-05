# Implementation lab: Change product identity without breaking tickets

## Scenario

The transport operator wants to rename product codes without breaking existing tickets. Your job is to give each product an ID that stays the same when its code changes. You cannot update every application instance at once, so your migration needs to support old code that still reads and writes `product_code`.

For this exercise, keep product codes unique and do not rename or reuse them while old and new code run together. Assign each product ID once. Keep every ticket linked to the same product, with its original price and currency.

## Before you start

Create a branch, then run these commands from the repository root to start your lab database:

```bash
git switch -c product-identity-lab
docker compose up -d
docker compose ps
docker compose exec -T postgres psql -U mobility -d mobility -v ON_ERROR_STOP=1 < database/postgres/experiments/lecture04/baseline.sql
```

Check that you have three tickets covering two products and that every ticket refers to an existing product. Save the ticket IDs, product codes, prices and currencies so you can compare them later. Leave `database/postgres/init/` unchanged.

If you are continuing in your own repository, use your earlier migrations and load at least three valid tickets covering two products. Check whether your reporting views or functions from lecture 3 use the columns you will change.

Copy each `.sql.example` file you need to `.sql` and complete its TODOs. Some examples contain runnable queries; others need your SQL before they can run.

Before running a migration, check its nullable columns, keys, backfill and any statements that remove data. If you already use an ORM, inspect its generated SQL too.

Run your scripts from the repository root, for example:

```bash
docker compose exec -T postgres psql -U mobility -d mobility -v ON_ERROR_STOP=1 < database/postgres/migrations/030_expand_product_identity.sql
```

Use the same command pattern for each file. Run each DDL migration once, in order. The backfill should be safe to repeat. If a statement fails inside a transaction, roll it back before continuing.

## Tasks

1. Try removing the old reference before updating the application code. Before running it, predict what will happen. Explain how you could lose the link between tickets and products, and show which old query or insert breaks. Roll back or reset your lab database before continuing.
2. Complete `030_expand_product_identity.sql.example`. Add a stored UUID to each product and a unique constraint on that column. Add a nullable `tickets.product_id` with a foreign key to the product ID. Keep `product_code`. Use a short lock timeout and explain what you would need to consider with a much larger table.
3. Write an insert and a query that use only `product_code`, as the old application would. Show that both still work after you add the new columns.
4. Write a new insert that accepts a product ID and looks up the code from that product. Store both references and the agreed purchase price. If the caller supplies a conflicting product code, either reject it or ignore it and use the code you looked up.
5. Write a query that finds a ticket's product by `product_id`, using `product_code` only when `product_id` is null. Test it before you fill in the IDs on existing tickets.
6. Complete `031_backfill_ticket_product.sql.example`. Fill in `product_id` only where it is null. Run the backfill twice and check that the second run changes zero rows. Then insert another ticket using the old writer and run the backfill again. It should fill in the new ticket's reference without changing any IDs you already assigned.
7. Write checks for null product IDs, missing products, and code/ID pairs that point to different products. Compare the original tickets, prices and currencies with your starting data. Separately, try writing a mismatched pair directly in SQL and record whether the database rejects it.
8. Complete `032_require_ticket_product.sql.example`. First, try making `product_id` required while one ticket still has a null reference. Capture the failure. Once you meet the conditions below, validate the foreign key and make the column required. Show that the old writer now fails.
9. Write an insert and a query that use only `product_id`. Check for views and functions that still use `tickets.product_code`, then try dropping that column in your lab database without `CASCADE`. Keep `products.code` for the catalogue.
## Before you require the new reference

Before making `product_id` required, make sure no old-only writers are still running and that the new readers and writers are in place. Run the backfill one last time and check for missing or mismatched references. Explain whether you could still return to the old application version and what that would involve. You cannot tell which versions are running just by looking at the repository.

Before dropping `tickets.product_code`, switch to readers and writers that use only the ID and check for database objects that still need the code. Explain whether you would keep the old column for a while and why. A UUID default does not stop someone from updating an ID, so explain how your application code or database permissions would prevent that.

## What to record

Keep your SQL, commands and important results in `docs/evidence/lecture04/README.md`. Show the failures as well as the successful runs, and check that the original tickets still have the same products, prices and currencies.

Add a small table showing which inserts and queries work before expansion, after expansion, once the ID is required, and after the old column is removed. Note any query that runs but misses tickets.

Finish with your rollout decision: when would you stop the old writers, and could you still return to the old application version? Support your answer with a result from your tests.

## Answers to the Lecture 4 tasks

### 1. Try removing the old reference

[`unsafe_change.sql`](../database/postgres/experiments/lecture04/unsafe_change.sql) shows that dropping `tickets.product_code` breaks the old query. Without a replacement reference, tickets lose their product link. The change is rolled back.

### 2. Complete the expand migration

[`030_expand_product_identity.sql`](../database/postgres/migrations/030_expand_product_identity.sql) assigns each product a UUID and adds a nullable `tickets.product_id` with a foreign key. It keeps `product_code` for old application versions. The lock timeout is three seconds. For a large table, plan for locks, possible table rewrites, and a backfill in batches.

### 3. Check the old application still works

The old reader and writer in [`old_reader.sql`](../database/postgres/experiments/lecture04/old_reader.sql) and [`old_writer.sql`](../database/postgres/experiments/lecture04/old_writer.sql) use `product_code` only. Both work while `product_id` is nullable.

### 4. Write using a product ID

[`new_writer.sql`](../database/postgres/experiments/lecture04/new_writer.sql) looks up the code from the supplied ID and writes both references. If the supplied code conflicts, it uses the looked-up code. It keeps the agreed ticket price; it does not replace it with today's catalogue price.

### 5. Read by ID, with a code fallback

[`new_reader.sql`](../database/postgres/experiments/lecture04/new_reader.sql) looks up the product by ID and falls back to its code when the ID is null. This lets it read tickets before backfill.

### 6. Backfill ticket product IDs

[`031_backfill_ticket_product.sql`](../database/postgres/migrations/031_backfill_ticket_product.sql) updates only null IDs. Run it twice: the second run changes zero rows. Run the old writer and backfill again to fill the new ticket without changing existing IDs.

### 7. Check references and preserve ticket details

[`verify.sql`](../database/postgres/experiments/lecture04/verify.sql) checks for null IDs, missing products, and mismatched code/ID pairs. `TICKET-3` stays at 65 DKK even though DAY now costs 80 DKK. [`mismatch_probe.sql`](../database/postgres/experiments/lecture04/mismatch_probe.sql) shows that direct SQL can create a mismatch while both references exist. The transitional writer avoids that mismatch, but the database does not enforce it. Product IDs are protected from changes, as tested in [`immutable_product_id_probe.sql`](../database/postgres/experiments/lecture04/immutable_product_id_probe.sql).

### 8. Require the new reference

[`require_before_backfill.sql`](../database/postgres/experiments/lecture04/require_before_backfill.sql) shows that `NOT NULL` fails while a ticket has no product ID. After backfill, [`032_require_ticket_product.sql`](../database/postgres/migrations/032_require_ticket_product.sql) validates the foreign key and requires the ID. The old writer then fails because it does not provide one.

### 9. Remove the old ticket reference

[`remove_legacy.sql`](../database/postgres/experiments/lecture04/remove_legacy.sql) checks dependencies and tries dropping `tickets.product_code` without `CASCADE`. The ID-only reader and writer work in the rehearsal. The transaction is rolled back. `products.code` remains the catalogue label.

### Before requiring the new reference

Stop old writers first. Backfill the tickets and check that every ticket has the right product ID before making it required. Before removing `product_code`, switch readers and writers to IDs and check what still uses the old column. After it is removed, the old application will need changes before it can work again.

### Rollout decision

Keep both references while old and new application versions run together. Require `product_id` only after old writers stop and all tickets pass the checks. Remove `tickets.product_code` later, after everything uses IDs. To use the old application again, the database would need to support `product_code` again.

The [Lecture 4 evidence](evidence/lecture04/README.md) shows the test results.
