-- Reference query: current captured revenue by operator and UTC payment date.
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
order by r.operator_id, revenue_date;
