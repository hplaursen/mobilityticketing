# Experiment Results

## 1. Reference query
select
    r.operator_id,
    p.created_utc::date as revenue_date,
    sum(p.amount) as captured_amount,
    count(*) as captured_payments
from payments p
join tickets t on t.id = p.ticket_id
join trips tr on tr.id = t.trip_id
join routes r on r.id = tr.route_id
where p.status = 'Captured'
group by r.operator_id, p.created_utc::date
order by r.operator_id, p.created_utc::date;

### Result
| Operator id | Revenue date | Captured amount | Captured payments |
| :---------- | :----------- | :-------------- | :---------------- |
| OP-BUS      | 2026-04-29   | 36              | 1                 |
| OP-METRO    | 2026-04-29   | 36              | 1                 |


### Verification
The captured payments have the expected amount, date and operator.
Therefore SUM(amount) and COUNT(*) produce the expected result.