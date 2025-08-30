create table cancellation (
  cancellation_id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references booking(booking_id) on delete cascade,
  cancellation_reason text not null,
  cancellation_status text default 'pending',
  cancellation_pre_fund_price numeric(10,2),
  cancellation_date date default current_date,
  created_at timestamp default now()
);
