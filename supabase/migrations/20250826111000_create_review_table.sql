create table review (
  review_id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references booking(booking_id) on delete cascade,
  rating numeric(3,2) not null,
  comment text,
  created_at timestamp default now()
);
