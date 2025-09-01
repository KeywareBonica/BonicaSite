create table service (
  service_id uuid primary key default gen_random_uuid(),
  service_name text not null,
  service_type text not null,
  service_description text,
  service_hours integer,
  created_at timestamp default now()
);
