-- Reusable read logic over the authoritative payments table.
-- Revenue dates are defined in UTC, independent of session time zone.

create or replace function captured_revenue_for_day(
    requested_operator_id text,
    requested_date date
)
returns table (
    captured_amount numeric,
    captured_payments bigint
)
language sql
stable
as $$
    select
        coalesce(sum(p.amount), 0),
        count(*)
    from payments p
    join tickets t on t.id = p.ticket_id
    join trips tr on tr.id = t.trip_id
    join routes r on r.id = tr.route_id
    where r.operator_id = requested_operator_id
      and (p.created_utc at time zone 'UTC')::date = requested_date
      and p.status = 'Captured';
$$;
