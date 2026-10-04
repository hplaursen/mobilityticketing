-- Transitional reader: use the stable ID when present, otherwise resolve the
-- legacy code. This also exposes missing or inconsistent assignments.
select t.id, t.product_code, t.product_id,
       coalesce(by_id.id, by_code.id) as resolved_product_id,
       coalesce(by_id.code, by_code.code) as resolved_product_code,
       t.price, t.currency
from tickets t
left join products by_id on by_id.id = t.product_id
left join products by_code on by_code.code = t.product_code
order by t.id;
