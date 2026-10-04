-- Show ticket identity and historical price, including any bad references.
select t.id, t.product_code, t.product_id,
       p_by_code.id as code_product_id,
       p_by_id.code as id_product_code,
       t.price, t.currency
from tickets t
left join products p_by_code on p_by_code.code = t.product_code
left join products p_by_id on p_by_id.id = t.product_id
order by t.id;

-- Expected: zero rows once the backfill and dual-write are correct.
select t.id
from tickets t
left join products p_by_code on p_by_code.code = t.product_code
left join products p_by_id on p_by_id.id = t.product_id
where t.product_id is null
   or p_by_id.id is null
   or p_by_code.id is distinct from p_by_id.id;

-- Historical TICKET-3 must remain 65 DKK; DAY currently costs 80 DKK.
select t.id, t.price as paid_price, p.price as current_catalogue_price,
       t.currency, p.currency as catalogue_currency
from tickets t join products p on p.code = t.product_code
where t.id = 'TICKET-3';
