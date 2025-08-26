create table quotation (
quotation_id uuid primary key default gen_random_uuid(),
  service_provider_id uuid not null references service_provider(service_provider_id) on delete cascade,
  job_cart_id uuid not null references job_cart(job_cart_id) on delete cascade,
  quotation_price numeric(10,2) not null,
  quotation_details text,
  quotation_file_path text,
  quotation_file_name text,
  quotation_submission_date date default current_date,
  quotation_submission_time time default current_time,
  quotation_status text default 'pending',
  created_at timestamp default now()
);
