-- Demonstrate that an old query no longer compiles after removing its column.
-- The whole change is rolled back after the expected error is caught.
begin;
alter table tickets drop column product_code;
do $$
begin
    begin
        execute 'select product_code from tickets limit 1';
        raise exception 'Expected the legacy query to fail';
    exception when undefined_column then
        raise notice 'Expected failure: old reader refers to removed product_code';
    end;
end;
$$;
rollback;
