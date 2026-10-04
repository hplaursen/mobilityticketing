-- Expected-failure rehearsal while at least one ticket has product_id NULL.
do $$
begin
    begin
        execute 'alter table tickets alter column product_id set not null';
        raise exception 'Expected SET NOT NULL to fail before backfill';
    exception when not_null_violation then
        raise notice 'Expected failure: product_id still contains NULL values';
    end;
end;
$$;
