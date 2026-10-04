-- Optional follow-up after the comparison experiment.
-- The duplicate test row is removed before adding the uniqueness rule.
\set ON_ERROR_STOP on

delete from payments
where id = 'PAY-CASE-DUPLICATE';

alter table payments
    add constraint payments_external_reference_unique
    unique (external_payment_reference);

refresh materialized view daily_captured_revenue;
select rebuild_daily_revenue_for('OP-METRO', date '2026-04-29');

-- Assert that redelivery with the same gateway reference is rejected.
do $$
begin
    begin
        insert into payments (
            id, user_id, ticket_id, external_payment_reference,
            amount, currency, status, created_utc
        ) values (
            'PAY-CASE-DUPLICATE-REJECTED', 'USER-1', 'TICKET-1',
            'gateway-capture-0001', 36, 'DKK', 'Captured',
            '2026-04-29 10:10:00+00'
        );
        raise exception 'Expected duplicate payment reference to be rejected';
    exception
        when unique_violation then
            raise notice 'Duplicate payment reference rejected as expected (SQLSTATE %)', SQLSTATE;
    end;
end;
$$;
