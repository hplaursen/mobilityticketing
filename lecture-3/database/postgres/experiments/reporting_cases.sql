-- Run once on the seeded database after migrations 020, 021, and 022.
-- Reset the Lecture 3 database before repeating this experiment.
\set ON_ERROR_STOP on

create temporary view reporting_approaches_current as
select 'direct query'::text as approach,
       coalesce(sum(p.amount), 0) as captured_amount,
       count(p.id) as captured_payments
from payments p
join tickets t on t.id = p.ticket_id
join trips tr on tr.id = t.trip_id
join routes r on r.id = tr.route_id
where r.operator_id = 'OP-METRO'
  and (p.created_utc at time zone 'UTC')::date = date '2026-04-29'
  and p.status = 'Captured'
union all
select 'SQL function', captured_amount, captured_payments
from captured_revenue_for_day('OP-METRO', date '2026-04-29')
union all
select 'materialized view', captured_amount, captured_payments
from daily_captured_revenue
where operator_id = 'OP-METRO' and revenue_date = date '2026-04-29'
union all
select 'trigger summary', captured_amount, captured_payments
from daily_revenue_by_operator
where operator_id = 'OP-METRO' and revenue_date = date '2026-04-29';

\echo 'Baseline: OP-METRO, 2026-04-29'
select * from reporting_approaches_current order by approach;

\echo 'Case 1: insert captured payment'
insert into payments (
    id, user_id, ticket_id, external_payment_reference,
    amount, currency, status, created_utc
) values (
    'PAY-CASE-CAPTURED', 'USER-1', 'TICKET-1', 'gateway-case-captured',
    36, 'DKK', 'Captured', '2026-04-29 10:00:00+00'
);
select * from reporting_approaches_current order by approach;

\echo 'Case 2: insert failed payment'
insert into payments (
    id, user_id, ticket_id, external_payment_reference,
    amount, currency, status, created_utc
) values (
    'PAY-CASE-FAILED', 'USER-1', 'TICKET-1', 'gateway-case-failed',
    50, 'DKK', 'Failed', '2026-04-29 10:05:00+00'
);
select * from reporting_approaches_current order by approach;

\echo 'Case 3: correct Failed to Captured'
update payments
set status = 'Captured'
where id = 'PAY-CASE-FAILED';
select * from reporting_approaches_current order by approach;

\echo 'Case 4: correct Captured to Refunded'
update payments
set status = 'Refunded'
where id = 'PAY-CASE-CAPTURED';
select * from reporting_approaches_current order by approach;

\echo 'Case 5: delete the corrected test payment'
delete from payments
where id = 'PAY-CASE-FAILED';
select * from reporting_approaches_current order by approach;

\echo 'Case 6: deliver a duplicate external payment reference'
insert into payments (
    id, user_id, ticket_id, external_payment_reference,
    amount, currency, status, created_utc
) values (
    'PAY-CASE-DUPLICATE', 'USER-1', 'TICKET-1', 'gateway-capture-0001',
    36, 'DKK', 'Captured', '2026-04-29 10:10:00+00'
);
select * from reporting_approaches_current order by approach;

\echo 'Refresh the materialized view after observing staleness'
refresh materialized view daily_captured_revenue;
select * from reporting_approaches_current order by approach;

\echo 'Rebuild the trigger summary after observing its drift'
select rebuild_daily_revenue_for('OP-METRO', date '2026-04-29');
select * from reporting_approaches_current order by approach;
