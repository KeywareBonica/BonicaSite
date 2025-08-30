create table event (
  event_id uuid primary key default gen_random_uuid(),
  event_type text not null,
  event_date date not null,
  event_time time not null,
  created_at timestamp default now()
);
