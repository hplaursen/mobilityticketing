1. Extract at least ten domain invariants from the scenario and schema.

2. Classify each invariant as one of:
   - directly enforceable with a column or table constraint;
   - enforceable with a unique or exclusion rule;
   - dependent on more than one row or an external system;
   - currently ambiguous and requiring a domain decision.
3. Implement the constraints that belong in this lecture.

**directly enforceable with a column or table constraint;**
trips.capacity (must not be negative)
trips.reserved_seats (must not be negative and less or equal to capacity)
payments.user_id (user_id must be FK to PK in user table)
valid_to_utc (grater than valid_from_utc)

**enforceable with a unique or exclusion rule;**

**dependent on more than one row or external system;**
payments.external_payment_reference (external)

**currently ambiguous and requiring a domain decision.**
validations.device_id (not clear where this data reference to)
products.name (should product name be unique and/or not empty)
users.email (should users email be unique and not/or empty)
tickets.ticket_code (should ticket_code be unique and not/or empty)
validation.stop_id (what stop - first/ending or the validation stop)

4. Write negative tests that attempt invalid inserts or updates.

5. Record at least two important invariants that cannot be solved by a simple constraint. Keep them for the transactions lecture.

   1. When purchasing a ticket, the payment and ticket creation must succeed together. If the payment or ticket creation fails, the operation should be rolled back.

   2. When purchasing a ticket, the seat/capacity update must be consistent with the ticket purchase. If there is no remaining capacity, the purchase must fail and any changes must be rolled back.