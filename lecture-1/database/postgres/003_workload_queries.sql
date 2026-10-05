-- 1. Show up to the next 20 scheduled trips for a route after a supplied timestamp.
select
    t.id,
    t.scheduled_departure_utc,
    t.status
from trips t
where t.route_id = 'LINE-5C'
  and t.status = 'scheduled'
  and t.scheduled_departure_utc > '2024-06-01 00:00:00+00'
order by t.scheduled_departure_utc
limit 20;

-- 2. Show the ordered stops belonging to a route.
select
    rs.stop_sequence,
    s.id as stop_id,
    s.city_id,
    s.name
from route_stops rs
join stops s on s.id = rs.stop_id
where rs.route_id = 'LINE-5C'
order by rs.stop_sequence;

-- 3. Show all routes and their scheduled-trip counts for a service date,
-- including routes with no scheduled trips on that date.
select
    r.id as route_id,
    r.short_name,
    count(t.id) as scheduled_trip_count
from routes r
left join trips t
    on t.route_id = r.id
   and t.service_date = date '2024-06-01'
   and t.status = 'scheduled'
group by r.id, r.short_name
order by r.short_name;
