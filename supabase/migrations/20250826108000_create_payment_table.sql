create table payment (
  payment_id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references booking(booking_id) on delete cascade,
  payment_amount numeric(10,2) not null,
  payment_proof text,
  payment_status text default 'pending',
  payment_invoice text,
  created_at timestamp default now()
);
