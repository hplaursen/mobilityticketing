-- The generated identifier must not be reassigned after issuance.
do $$
begin
    begin
        update products set id = gen_random_uuid() where code = 'DAY';
        raise exception 'Expected product ID update to fail';
    exception when raise_exception then
        if sqlerrm = 'Product ID is immutable' then
            raise notice 'Expected failure: issued product ID cannot be changed';
        else
            raise;
        end if;
    end;
end;
$$;
