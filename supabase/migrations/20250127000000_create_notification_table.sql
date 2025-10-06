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
