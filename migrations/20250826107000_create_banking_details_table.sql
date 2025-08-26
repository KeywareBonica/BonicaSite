create table banking_details (
  banking_details_id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references payment(payment_id) on delete cascade,
  account_number text not null,
  account_name text not null,
  branch_code text,
  swift_code text,
  branch_address text,
  banking_reference text,
  created_at timestamp default now()
);
