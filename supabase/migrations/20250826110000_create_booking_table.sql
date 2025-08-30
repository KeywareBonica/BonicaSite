create table booking (
  booking_id uuid primary key default gen_random_uuid(),
  booking_date date not null,
  booking_start_time time not null,
  booking_end_time time not null,
  booking_status text default 'pending',
  booking_total_price numeric(10,2),
  booking_special_request text,
  client_id uuid not null references client(client_id) on delete cascade,
  event_id uuid not null references event(event_id) on delete cascade,
  created_at timestamp default now()
);
