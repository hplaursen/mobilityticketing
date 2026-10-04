
CREATE FUNCTION get_captured_payments_by_operator()
RETURNS TABLE (
    operator_id TEXT,
    revenue_date DATE,
    captured_amount NUMERIC,
    captured_payments INT
) AS $$
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
$$ LANGUAGE SQL;

