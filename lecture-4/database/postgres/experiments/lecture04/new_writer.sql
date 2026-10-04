-- New writer accepts a product ID, derives its code, and keeps the agreed
-- purchase price as an independent input (not the current catalogue price).
\set ticket_id 'LAB04-NEW-1'
\set ticket_code 'LAB04-CODE-NEW-1'
select id as product_id from products where code = 'DAY' \gset

insert into tickets
    (id, user_id, trip_id, ticket_code, status, product_code, product_id,
     valid_from_utc, valid_to_utc, price, currency)
select :'ticket_id', source.user_id, source.trip_id, :'ticket_code',
       'Active', p.code, p.id,
       source.valid_from_utc, source.valid_to_utc, 65.00, 'DKK'
from tickets source
join products p on p.id = :'product_id'::uuid
where source.id = 'TICKET-1';

-- A caller supplies SINGLE with the DAY product ID. The writer ignores the
-- conflicting supplied code and stores the code looked up from the ID.
with request(supplied_code, product_id) as (
    values ('SINGLE'::text, :'product_id'::uuid)
)
insert into tickets
    (id, user_id, trip_id, ticket_code, status, product_code, product_id,
     valid_from_utc, valid_to_utc, price, currency)
select 'LAB04-NEW-CONFLICT', source.user_id, source.trip_id,
       'LAB04-CODE-NEW-CONFLICT', 'Active',
       case when request.supplied_code is distinct from p.code
            then p.code else request.supplied_code end,
       p.id, source.valid_from_utc, source.valid_to_utc, 65.00, 'DKK'
from request
join products p on p.id = request.product_id
join tickets source on source.id = 'TICKET-1';

-- Unknown IDs are rejected explicitly.
do $$
declare inserted_rows integer;
begin
    insert into tickets
        (id, user_id, trip_id, ticket_code, status, product_code, product_id,
         valid_from_utc, valid_to_utc, price, currency)
    select 'LAB04-UNKNOWN-PRODUCT', source.user_id, source.trip_id,
           'LAB04-CODE-UNKNOWN-PRODUCT', 'Active', p.code, p.id,
           source.valid_from_utc, source.valid_to_utc, 65.00, 'DKK'
    from tickets source
    join products p on p.id = '00000000-0000-0000-0000-000000000000'::uuid
    where source.id = 'TICKET-1';
    get diagnostics inserted_rows = row_count;
    if inserted_rows = 0 then
        raise notice 'Unknown product ID rejected';
    else
        raise exception 'Unknown product ID unexpectedly inserted a ticket';
    end if;
end;
$$;
