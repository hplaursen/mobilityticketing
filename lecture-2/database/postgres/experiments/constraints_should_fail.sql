-- Run each statement separately after applying your integrity migration.
-- Every statement below should be rejected by a named constraint.
-- In psql, verbose errors include SQLSTATE: 23514 CHECK, 23503 FOREIGN KEY,
-- 23505 UNIQUE, and 23502 NOT NULL.
\set VERBOSITY verbose

-- 1. Negative capacity. Expected: CHECK violation.
update trips
set capacity = -1
where id = 'TRIP-M2-20260429-0800';

-- 2. More reserved seats than capacity. Expected: CHECK violation.
update trips
set reserved_seats = capacity + 1
where id = 'TRIP-M2-20260429-0800';

-- 3. Unknown trip. Expected: FOREIGN KEY violation.
insert into tickets (
    id, user_id, trip_id, ticket_code, status,
    product_code, valid_from_utc, valid_to_utc, price, currency
) values (
    'T-INVALID-TRIP', 'USER-1', 'TRIP-DOES-NOT-EXIST',
    'CODE-INVALID-TRIP', 'Active', 'SINGLE',
    '2026-04-29 08:00:00+00', '2026-04-29 09:00:00+00', 36, 'DKK'
);

-- 4. Unknown product. Expected: FOREIGN KEY violation (23503).
insert into tickets (
    id, user_id, trip_id, ticket_code, status,
    product_code, valid_from_utc, valid_to_utc, price, currency
) values (
    'T-INVALID-PRODUCT', 'USER-1', 'TRIP-M2-20260429-0800',
    'CODE-INVALID-PRODUCT', 'Active', 'NO-SUCH-PRODUCT',
    '2026-04-29 08:00:00+00', '2026-04-29 09:00:00+00', 36, 'DKK'
);

-- 5. Reversed validity window. Expected: CHECK violation (23514).
insert into tickets (
    id, user_id, trip_id, ticket_code, status,
    product_code, valid_from_utc, valid_to_utc, price, currency
) values (
    'T-REVERSED', 'USER-1', 'TRIP-M2-20260429-0800',
    'CODE-REVERSED', 'Active', 'SINGLE',
    '2026-04-29 09:00:00+00', '2026-04-29 08:00:00+00', 36, 'DKK'
);

-- 6. Duplicate ticket code. Expected: UNIQUE violation (23505).
insert into tickets (
    id, user_id, trip_id, ticket_code, status,
    product_code, valid_from_utc, valid_to_utc, price, currency
)
select
    'T-DUPLICATE-CODE', user_id, trip_id, ticket_code, status,
    product_code, valid_from_utc, valid_to_utc, price, currency
from tickets
where id = 'TICKET-1';

-- 7. Unknown ticket status. Expected: CHECK violation (23514).
update tickets
set status = 'Unknown'
where id = 'TICKET-1';

-- 8. Negative product price. Expected: CHECK violation (23514).
update products
set price = -1
where code = 'SINGLE';

-- 9. Malformed currency. Expected: CHECK violation (23514).
update products
set currency = 'dkk'
where code = 'SINGLE';

-- 10. Negative ticket price. Expected: CHECK violation (23514).
update tickets
set price = -1
where id = 'TICKET-1';

-- 11. Payment for an unknown ticket. Expected: FOREIGN KEY violation (23503).
insert into payments (
    id, user_id, ticket_id, external_payment_reference,
    amount, currency, status
) values (
    'PAYMENT-UNKNOWN-TICKET', 'USER-1', 'NO-SUCH-TICKET',
    'gateway-capture-invalid', 36, 'DKK', 'Captured'
);

-- 12. Negative payment amount. Expected: CHECK violation (23514).
update payments
set amount = -1
where id = 'PAYMENT-1';

-- 13. Unknown payment status. Expected: CHECK violation (23514).
update payments
set status = 'Unknown'
where id = 'PAYMENT-1';

-- 14. Duplicate external payment reference. Expected: UNIQUE violation (23505).
insert into payments (
    id, user_id, ticket_id, external_payment_reference,
    amount, currency, status
) values (
    'PAYMENT-DUPLICATE-REFERENCE', 'USER-1', 'TICKET-1',
    'gateway-capture-0001', 36, 'DKK', 'Captured'
);

-- 15. Validation for an unknown ticket. Expected: FOREIGN KEY violation (23503).
insert into validations (
    id, ticket_id, ticket_code, vehicle_id, stop_id, device_id, result
) values (
    'VALIDATION-UNKNOWN-TICKET', 'NO-SUCH-TICKET', 'NO-SUCH-CODE',
    'BUS-5C-01', 'STOP-CENTRAL', 'DEVICE-01', 'Rejected'
);

-- 16. Mismatched ticket id and ticket code. Expected: composite FOREIGN KEY violation (23503).
insert into validations (
    id, ticket_id, ticket_code, vehicle_id, stop_id, device_id, result
) values (
    'VALIDATION-MISMATCH', 'TICKET-1', 'CODE-5C-0001',
    'BUS-5C-01', 'STOP-CENTRAL', 'DEVICE-01', 'Accepted'
);

-- 17. Validation for an unknown stop. Expected: FOREIGN KEY violation (23503).
insert into validations (
    id, ticket_id, ticket_code, vehicle_id, stop_id, device_id, result
) values (
    'VALIDATION-UNKNOWN-STOP', 'TICKET-1', 'CODE-M2-0001',
    'BUS-5C-01', 'NO-SUCH-STOP', 'DEVICE-01', 'Accepted'
);

-- 18. Ticket for an unknown user. Expected: FOREIGN KEY violation (23503).
insert into tickets (
    id, user_id, trip_id, ticket_code, status,
    product_code, valid_from_utc, valid_to_utc, price, currency
) values (
    'T-INVALID-USER', 'NO-SUCH-USER', 'TRIP-M2-20260429-0800',
    'CODE-INVALID-USER', 'Active', 'SINGLE',
    '2026-04-29 08:00:00+00', '2026-04-29 09:00:00+00', 36, 'DKK'
);

-- 19. Payment for an unknown user. Expected: FOREIGN KEY violation (23503).
insert into payments (
    id, user_id, ticket_id, external_payment_reference,
    amount, currency, status
) values (
    'PAYMENT-UNKNOWN-USER', 'NO-SUCH-USER', 'TICKET-1',
    'gateway-capture-invalid-user', 36, 'DKK', 'Captured'
);

-- 20. Missing ticket code. Expected: NOT NULL violation (23502).
insert into tickets (
    id, user_id, trip_id, ticket_code, status,
    product_code, valid_from_utc, valid_to_utc, price, currency
) values (
    'T-MISSING-CODE', 'USER-1', 'TRIP-M2-20260429-0800', null, 'Active',
    'SINGLE', '2026-04-29 08:00:00+00', '2026-04-29 09:00:00+00', 36, 'DKK'
);

-- 21. Missing payment currency. Expected: NOT NULL violation (23502).
insert into payments (
    id, user_id, ticket_id, external_payment_reference,
    amount, currency, status
) values (
    'PAYMENT-MISSING-CURRENCY', 'USER-1', 'TICKET-1',
    'gateway-missing-currency', 36, null, 'Captured'
);
