-- Simulate an older application instance writing during the backfill window.
insert into tickets
    (id, user_id, trip_id, ticket_code, status, product_code,
     valid_from_utc, valid_to_utc, price, currency)
select 'LAB04-OLD-LATE', user_id, trip_id, 'LAB04-CODE-OLD-LATE', status,
       product_code, valid_from_utc, valid_to_utc, price, currency
from tickets
where id = 'TICKET-1';
