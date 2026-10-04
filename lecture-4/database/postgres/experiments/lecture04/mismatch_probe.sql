-- Show whether the transitional schema itself rejects conflicting references.
begin;
insert into tickets
    (id, user_id, trip_id, ticket_code, status, product_code, product_id,
     valid_from_utc, valid_to_utc, price, currency)
select 'LAB04-MISMATCH', t.user_id, t.trip_id, 'LAB04-CODE-MISMATCH',
       'Active', single_product.code, day_product.id,
       t.valid_from_utc, t.valid_to_utc, t.price, t.currency
from tickets t
cross join products single_product
cross join products day_product
where t.id = 'TICKET-1'
  and single_product.code = 'SINGLE'
  and day_product.code = 'DAY';

do $$
begin
    if exists (select 1 from tickets where id = 'LAB04-MISMATCH') then
        raise notice 'Database accepted the mismatched pair; writers and verification must prevent it';
    end if;
end;
$$;
rollback;
