-- Stored snapshot of captured revenue. It changes only when refreshed.

-- The starter initializes an empty view with this name. Recreate it here so
-- this migration both works with the starter and gives a populated snapshot.
drop materialized view if exists daily_captured_revenue;

create materialized view daily_captured_revenue as
select
    r.operator_id,
    (p.created_utc at time zone 'UTC')::date as revenue_date,
    sum(p.amount) as captured_amount,
    count(*) as captured_payments
from payments p
join tickets t on t.id = p.ticket_id
join trips tr on tr.id = t.trip_id
join routes r on r.id = tr.route_id
where p.status = 'Captured'
group by r.operator_id, (p.created_utc at time zone 'UTC')::date
with no data;

create unique index daily_captured_revenue_key
    on daily_captured_revenue (operator_id, revenue_date);

refresh materialized view daily_captured_revenue;
