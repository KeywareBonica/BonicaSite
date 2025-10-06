-- Create missing tables for the application
-- Run this script in your Supabase SQL editor

-- Create notification table
create table if not exists notification (
    notification_id uuid primary key default gen_random_uuid(),
    user_id uuid not null,
    user_type text not null check (user_type in ('client', 'service_provider')),
    title text not null,
    message text not null,
    type text not null check (type in ('info', 'success', 'warning', 'error')),
    is_read boolean default false,
    created_at timestamp default now(),
    read_at timestamp
);

-- Create index for efficient queries
create index if not exists idx_notification_user_id on notification(user_id);
create index if not exists idx_notification_user_type on notification(user_type);
create index if not exists idx_notification_is_read on notification(is_read);
create index if not exists idx_notification_created_at on notification(created_at);

-- Create resource_locks table for managing concurrent access
create table if not exists resource_locks (
    lock_id uuid primary key default gen_random_uuid(),
    resource_type text not null,
    resource_id text not null,
    user_id uuid not null,
    user_type text not null check (user_type in ('client', 'service_provider')),
    acquired_at timestamp default now(),
    expires_at timestamp not null,
    created_at timestamp default now()
);

-- Create unique constraint to prevent multiple locks on same resource
create unique index if not exists idx_resource_locks_unique on resource_locks(resource_type, resource_id);

-- Create index for efficient cleanup queries
create index if not exists idx_resource_locks_expires_at on resource_locks(expires_at);
create index if not exists idx_resource_locks_user_id on resource_locks(user_id);

-- Add function to automatically clean up expired locks
create or replace function cleanup_expired_locks()
returns void as $$
begin
    delete from resource_locks where expires_at < now();
end;
$$ language plpgsql;

-- Insert some sample notifications for testing
insert into notification (user_id, user_type, title, message, type) values
('84d9a8af-afde-41e6-a8b2-0dc6babd03f1', 'client', 'Welcome!', 'Welcome to our event booking system!', 'info'),
('84d9a8af-afde-41e6-a8b2-0dc6babd03f1', 'client', 'Booking Confirmed', 'Your event booking has been confirmed.', 'success');

-- Enable Row Level Security (RLS) for both tables
alter table notification enable row level security;
alter table resource_locks enable row level security;

-- Create RLS policies for notification table
create policy "Users can view their own notifications" on notification
    for select using (user_id = auth.uid());

create policy "Users can update their own notifications" on notification
    for update using (user_id = auth.uid());

-- Create RLS policies for resource_locks table
create policy "Users can manage their own locks" on resource_locks
    for all using (user_id = auth.uid());
