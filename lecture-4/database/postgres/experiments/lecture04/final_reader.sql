-- ID-only reader; safe after tickets.product_code is removed.
select t.id, p.id as product_id, p.code as product_code,
       t.price, t.currency
from tickets t
join products p on p.id = t.product_id
order by t.id;
