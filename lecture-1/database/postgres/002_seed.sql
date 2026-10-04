insert into operators (id, name) values
    ('OP-METRO', 'City Metro'),
    ('OP-BUS', 'City Bus'),
    ('OP-TRAIN', 'Regional Train')
on conflict do nothing;

insert into routes (id, operator_id, city_id, mode, short_name) values
    ('LINE-M2', 'OP-METRO', 'CPH', 'metro', 'M2'),
    ('LINE-5C', 'OP-BUS', 'CPH', 'bus', '5C'),
    ('LINE-8B', 'OP-TRAIN', 'HBO', 'train', '8B')
on conflict do nothing;

insert into stops (id, city_id, name) values
    ('STOP-NORREPORT', 'CPH', 'Nørreport'),
    ('STOP-KONGENS-NYTORV', 'CPH', 'Kongens Nytorv'),
    ('STOP-AIRPORT', 'CPH', 'Copenhagen Airport'),
    ('STOP-CENTRAL', 'CPH', 'Copenhagen Central Station')
on conflict do nothing;

-- Add route_stops rows after deciding the key.
insert into route_stops (route_id, stop_id, stop_sequence) values
    ('LINE-M2', 'STOP-NORREPORT', 1),
    ('LINE-M2', 'STOP-KONGENS-NYTORV', 2),
    ('LINE-M2', 'STOP-AIRPORT', 3),
    ('LINE-5C', 'STOP-CENTRAL', 1),
    ('LINE-5C', 'STOP-KONGENS-NYTORV', 2),
    ('LINE-5C', 'STOP-NORREPORT', 3)
on conflict do nothing;

-- Add at least two trips per route on the same service date.
insert into trips (id, route_id, service_date, scheduled_departure_utc, status) values
    ('TRIP-M2-2024-06-01-08:00', 'LINE-M2', '2024-06-01', '2024-06-01 08:00:00+02', 'scheduled'),
    ('TRIP-M2-2024-06-01-08:30', 'LINE-M2', '2024-06-01', '2024-06-01 08:30:00+02', 'scheduled'),
    ('TRIP-5C-2024-06-01-09:00', 'LINE-5C', '2024-06-01', '2024-06-01 09:00:00+02', 'scheduled'),
    ('TRIP-5C-2024-06-01-09:15', 'LINE-5C', '2024-06-01', '2024-06-01 09:15:00+02', 'scheduled')
on conflict do nothing;
