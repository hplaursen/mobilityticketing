-- Reversible rehearsal: inspect dependencies, remove the old column in a
-- transaction, prove the ID-only reader/writer work, and roll back.
\set ON_ERROR_STOP on

select dependent_ns.nspname as schema_name, dependent_view.relname as object_name,
       dependent_view.relkind
from pg_depend d
join pg_rewrite rw on rw.oid = d.objid
join pg_class dependent_view on dependent_view.oid = rw.ev_class
join pg_namespace dependent_ns on dependent_ns.oid = dependent_view.relnamespace
join pg_attribute a on a.attrelid = d.refobjid and a.attnum = d.refobjsubid
where d.refobjid = 'tickets'::regclass and a.attname = 'product_code';

select proname from pg_proc
where prosrc ilike '%product_code%';

begin;
set local lock_timeout = '3s';
alter table tickets drop column product_code;
do $$
begin
    begin
        execute $sql$
            insert into tickets
                (id, user_id, trip_id, ticket_code, status, product_code,
                 valid_from_utc, valid_to_utc, price, currency)
            select 'LAB04-OLD-AFTER-DROP', user_id, trip_id,
                   'LAB04-CODE-OLD-AFTER-DROP', status, product_code,
                   valid_from_utc, valid_to_utc, price, currency
            from tickets where id = 'TICKET-1'
        $sql$;
        raise exception 'Expected old writer to fail after product_code removal';
    exception when undefined_column then
        raise notice 'Expected failure: old writer refers to removed product_code';
    end;
end;
$$;
\ir final_reader.sql
\ir final_writer.sql
rollback;
