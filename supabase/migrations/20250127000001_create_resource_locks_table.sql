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
