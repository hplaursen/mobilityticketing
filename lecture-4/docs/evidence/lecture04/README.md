# Lecture 4 migration evidence

The run used the freshly seeded Lecture 4 PostgreSQL database. The command sequence and complete terminal output are in [`run-output.txt`](run-output.txt); the repeatable runner is [`run_experiment.sh`](../../../scripts/run_experiment.sh). The SQL is replayed in the order shown by the runner. The database is left after the contract stage with both columns present; dropping `tickets.product_code` is rehearsed inside a transaction and rolled back.

## Starting data and preserved prices

The baseline contained three tickets covering `SINGLE` and `DAY`, and every old code resolved to a catalogue product. `TICKET-3` cost 65 DKK while the current DAY catalogue price is 80 DKK. After migration and both verification passes, it still cost 65 DKK. The migration changes only product references, not historical ticket prices or currencies.

## Observed results

| Check | Result |
| --- | --- |
| Remove old column before changing readers | Expected old query failure; transaction rolled back |
| Old reader and writer after expansion | Both worked while `product_id` was nullable |
| Transitional reader before backfill | Resolved all tickets through the old product code |
| Require ID before backfill | Expected `NOT NULL` failure, captured in a PL/pgSQL block |
| First backfill after initial old write | `UPDATE 4` |
| Repeat backfill | `UPDATE 0` |
| Old-only late write, then backfill | Insert succeeded; backfill reported `UPDATE 1` |
| Null, missing, or mismatched references after backfill | Verification query returned zero rows |
| Direct SQL mismatch probe | Database accepted a valid-but-conflicting code/ID pair; transaction rolled back |
| New writer with conflicting supplied code | Stored the catalogue code looked up from the supplied ID |
| New writer with unknown product ID | Insert selected zero rows; no ticket was created |
| Change an issued product ID | Expected trigger rejection |
| Require `product_id` after verification | Foreign key validated and `NOT NULL` migration succeeded |
| Old writer after ID became required | Expected not-null failure, captured in a PL/pgSQL block |
| Remove old column in rehearsal | Old writer failed; final ID-only reader and writer worked; transaction rolled back |

## Compatibility by rollout stage

| Stage | Old reader/writer | Transitional reader/writer | ID-only reader/writer |
| --- | --- | --- | --- |
| Before expansion | Works | Not yet deployed | Cannot work |
| After expansion, before backfill | Works | Works via code fallback / dual write | Reader can miss tickets with null IDs |
| After backfill, ID nullable | Works; each later old write needs another backfill | Works | Reader sees all rows; writer still needs old code until removal |
| ID required, both columns present | Reader works; old writer fails | Works | Can dual-write during transition |
| Old column removed | Fails | Fails if it refers to `tickets.product_code` | Works |

## Rollout decision and limitation

Retire all old-only writers before requiring the new ID. Keep the old reference until new readers and writers are deployed and final verification returns zero rows. Remove the column in a later deployment after checking dependencies without `CASCADE`. An old application cannot simply be restarted after the column is removed; rollback then requires a forward compatibility migration or view.

While both references exist, PostgreSQL enforces that each reference points to a real product but does not ensure that they point to the same product. The writer ignores a conflicting supplied code and stores the catalogue code found by ID. The verification query is a deployment gate; a composite key and foreign key could make the pairwise rule database-enforced if needed.
