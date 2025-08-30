create table event_service (
  event_service_id uuid primary key default gen_random_uuid(),
  service_id uuid not null references service(service_id) on delete cascade,
  event_id uuid not null references event(event_id) on delete cascade,
  event_service_notes text,
  event_service_status text default 'pending',
  created_at timestamp default now()
);
