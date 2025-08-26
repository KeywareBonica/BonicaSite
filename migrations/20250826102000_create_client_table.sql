create table client (
  client_id uuid primary key default gen_random_uuid(),
  client_name text not null,
  client_surname text not null,
  client_password text not null,
  client_contact text not null,
  client_email text unique not null,
  client_city text,
  client_town text,
  client_street_name text,
  client_house_number text,
  client_postal_code text,
  client_preferred_notification text,
  created_at timestamp default now()
);
