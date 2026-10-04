-- Contract stage: run only after old-only writers have been retired.
begin;
set local lock_timeout = '3s';

alter table tickets validate constraint tickets_product_id_fk;

alter table tickets
    add constraint tickets_product_id_present
    check (product_id is not null) not valid;

alter table tickets validate constraint tickets_product_id_present;
alter table tickets alter column product_id set not null;
alter table tickets drop constraint tickets_product_id_present;

commit;
