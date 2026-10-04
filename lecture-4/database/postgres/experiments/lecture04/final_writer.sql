-- ID-only writer; safe after tickets.product_code is removed.
select id as product_id from products where code = 'DAY' \gset

insert into tickets
    (id, user_id, trip_id, ticket_code, status, product_id,
     valid_from_utc, valid_to_utc, price, currency)
select 'LAB04-FINAL-1', source.user_id, source.trip_id,
       'LAB04-CODE-FINAL-1', 'Active', p.id,
       source.valid_from_utc, source.valid_to_utc, 65.00, 'DKK'
from tickets source
join products p on p.id = :'product_id'::uuid
where source.id = 'TICKET-1';
