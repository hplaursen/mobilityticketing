-- Expected-failure probe after product_id is NOT NULL.
do $$
begin
    begin
        execute $sql$
            insert into tickets
                (id, user_id, trip_id, ticket_code, status, product_code,
                 valid_from_utc, valid_to_utc, price, currency)
            select 'LAB04-OLD-AFTER-REQUIRE', user_id, trip_id,
                   'LAB04-CODE-OLD-AFTER-REQUIRE', status, product_code,
                   valid_from_utc, valid_to_utc, price, currency
            from tickets where id = 'TICKET-1'
        $sql$;
        raise exception 'Expected old writer to fail after product_id became required';
    exception when not_null_violation then
        raise notice 'Expected failure: old writer omits required product_id';
    end;
end;
$$;
