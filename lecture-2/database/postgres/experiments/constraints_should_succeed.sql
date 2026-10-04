-- Run after applying 011_ticketing_integrity.sql.
-- Every write here should succeed; the transaction is rolled back so the
-- example rows do not remain in the lab database.

begin;

update trips
set reserved_seats = reserved_seats + 1
where id = 'TRIP-M2-20260429-0800'
  and reserved_seats < capacity;

insert into users (id, email, full_name, is_disabled)
values ('USER-CONSTRAINT-TEST', 'constraint-test@example.test', 'Constraint Test', false);

insert into tickets (
    id, user_id, trip_id, ticket_code, status,
    product_code, valid_from_utc, valid_to_utc, price, currency
) values (
    'TICKET-CONSTRAINT-TEST', 'USER-CONSTRAINT-TEST', 'TRIP-M2-20260429-0800',
    'CODE-CONSTRAINT-TEST', 'Active', 'SINGLE',
    '2026-04-29 08:00:00+00', '2026-04-29 09:00:00+00', 36, 'DKK'
);

insert into payments (
    id, user_id, ticket_id, external_payment_reference,
    amount, currency, status
) values (
    'PAYMENT-CONSTRAINT-TEST', 'USER-CONSTRAINT-TEST',
    'TICKET-CONSTRAINT-TEST', 'gateway-constraint-test', 36, 'DKK', 'Captured'
);

insert into validations (
    id, ticket_id, ticket_code, vehicle_id, stop_id, device_id, result
) values (
    'VALIDATION-CONSTRAINT-TEST', 'TICKET-CONSTRAINT-TEST',
    'CODE-CONSTRAINT-TEST', 'BUS-M2-01', 'STOP-NORREPORT',
    'DEVICE-CONSTRAINT-TEST', 'Accepted'
);

rollback;
