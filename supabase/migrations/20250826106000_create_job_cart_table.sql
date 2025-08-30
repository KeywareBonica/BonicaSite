create table job_cart (
  job_cart_id uuid primary key default gen_random_uuid(),
  event_id uuid not null references event(event_id) on delete cascade,
  job_cart_item text not null,
  job_cart_details text,
  job_cart_created_date date default current_date,
  job_cart_created_time time default current_time,
  job_cart_status text default 'pending',
  created_at timestamp default now()
);
