-- Deliberately insert-only: the experiment compares its limitations with
-- corrections and deletes. Rebuild manually with rebuild_daily_revenue_for.

create table if not exists daily_revenue_by_operator (
    operator_id text not null references operators(id),
    revenue_date date not null,
    captured_amount numeric not null default 0,
    captured_payments bigint not null default 0,
    primary key (operator_id, revenue_date)
);

-- Clear the summary table, then fill it again using the payment records.
truncate table daily_revenue_by_operator;

create or replace function add_inserted_payment_to_daily_revenue()
returns trigger
language plpgsql
as $$
declare
    payment_operator_id text;
    payment_revenue_date date;
begin
    if new.status is distinct from 'Captured' then
        return new;
    end if;

    select r.operator_id
    into payment_operator_id
    from tickets t
    join trips tr on tr.id = t.trip_id
    join routes r on r.id = tr.route_id
    where t.id = new.ticket_id;

    payment_revenue_date := (new.created_utc at time zone 'UTC')::date;

    insert into daily_revenue_by_operator (
        operator_id, revenue_date, captured_amount, captured_payments
    ) values (
        payment_operator_id, payment_revenue_date, new.amount, 1
    )
    on conflict (operator_id, revenue_date)
    do update set
        captured_amount = daily_revenue_by_operator.captured_amount + excluded.captured_amount,
        captured_payments = daily_revenue_by_operator.captured_payments + 1;

    return new;
end;
$$;

drop trigger if exists payments_daily_revenue_after_insert on payments;
create trigger payments_daily_revenue_after_insert
after insert on payments
for each row
execute function add_inserted_payment_to_daily_revenue();

-- The trigger only handles new payments, so add the existing payments to the summary here.
insert into daily_revenue_by_operator (
    operator_id, revenue_date, captured_amount, captured_payments
)
select
    r.operator_id,
    (p.created_utc at time zone 'UTC')::date,
    sum(p.amount),
    count(*)
from payments p
join tickets t on t.id = p.ticket_id
join trips tr on tr.id = t.trip_id
join routes r on r.id = tr.route_id
where p.status = 'Captured'
group by r.operator_id, (p.created_utc at time zone 'UTC')::date;

-- Use this function to update the summary after payments are changed or deleted.
-- During this exercise, do not add payments while the summary is being rebuilt.
create or replace function rebuild_daily_revenue_for(
    requested_operator_id text,
    requested_date date
)
returns void
language plpgsql
as $$
begin
    delete from daily_revenue_by_operator
    where operator_id = requested_operator_id
      and revenue_date = requested_date;

    insert into daily_revenue_by_operator (
        operator_id, revenue_date, captured_amount, captured_payments
    )
    select
        r.operator_id,
        (p.created_utc at time zone 'UTC')::date,
        sum(p.amount),
        count(*)
    from payments p
    join tickets t on t.id = p.ticket_id
    join trips tr on tr.id = t.trip_id
    join routes r on r.id = tr.route_id
    where r.operator_id = requested_operator_id
      and (p.created_utc at time zone 'UTC')::date = requested_date
      and p.status = 'Captured'
    group by r.operator_id, (p.created_utc at time zone 'UTC')::date;
end;
$$;
