-- Create job cart acceptance table to track which service providers have accepted jobs
create table job_cart_acceptance (
  acceptance_id uuid primary key default gen_random_uuid(),
  job_cart_id uuid not null references job_cart(job_cart_id) on delete cascade,
  service_provider_id uuid not null references service_provider(service_provider_id) on delete cascade,
  acceptance_status text not null check (acceptance_status in ('pending', 'accepted', 'declined')),
  accepted_at timestamp,
  declined_at timestamp,
  created_at timestamp default now(),
  
  -- Ensure one acceptance record per service provider per job cart
  unique(job_cart_id, service_provider_id)
);

-- Create index for faster queries
create index idx_job_cart_acceptance_job_cart on job_cart_acceptance(job_cart_id);
create index idx_job_cart_acceptance_provider on job_cart_acceptance(service_provider_id);
create index idx_job_cart_acceptance_status on job_cart_acceptance(acceptance_status);

-- Add job_cart_status to track overall job cart state
alter table job_cart add column job_cart_status text default 'available' check (job_cart_status in ('available', 'in_progress', 'completed', 'cancelled'));

-- Create index for job_cart_status
create index idx_job_cart_status on job_cart(job_cart_status);

-- Add function to automatically update job_cart_status when quotations are uploaded
create or replace function update_job_cart_status()
returns trigger as $$
begin
  -- When a quotation is inserted, mark the job cart as in_progress
  if TG_OP = 'INSERT' then
    update job_cart 
    set job_cart_status = 'in_progress' 
    where job_cart_id = NEW.job_cart_id 
    and job_cart_status = 'available';
  end if;
  
  return NEW;
end;
$$ language plpgsql;

-- Create trigger to automatically update job cart status
create trigger trigger_update_job_cart_status
  after insert on quotation
  for each row
  execute function update_job_cart_status();

-- Add function to handle concurrent acceptance attempts
create or replace function accept_job_cart_concurrent(
  p_job_cart_id uuid,
  p_service_provider_id uuid
)
returns json as $$
declare
  v_acceptance_id uuid;
  v_result json;
begin
  -- Use row-level locking to prevent race conditions
  perform 1 from job_cart_acceptance 
  where job_cart_id = p_job_cart_id 
  and service_provider_id = p_service_provider_id
  for update;
  
  -- Check if acceptance already exists
  if found then
    select acceptance_id, acceptance_status into v_acceptance_id, v_result
    from job_cart_acceptance 
    where job_cart_id = p_job_cart_id 
    and service_provider_id = p_service_provider_id;
    
    return json_build_object(
      'success', false,
      'message', 'Job cart already processed by this service provider',
      'current_status', v_result,
      'acceptance_id', v_acceptance_id
    );
  end if;
  
  -- Check if job cart is still available
  if not exists (
    select 1 from job_cart 
    where job_cart_id = p_job_cart_id 
    and job_cart_status = 'available'
  ) then
    return json_build_object(
      'success', false,
      'message', 'Job cart is no longer available'
    );
  end if;
  
  -- Create acceptance record
  insert into job_cart_acceptance (
    job_cart_id, 
    service_provider_id, 
    acceptance_status, 
    accepted_at
  ) values (
    p_job_cart_id, 
    p_service_provider_id, 
    'accepted', 
    now()
  ) returning acceptance_id into v_acceptance_id;
  
  return json_build_object(
    'success', true,
    'message', 'Job cart accepted successfully',
    'acceptance_id', v_acceptance_id
  );
end;
$$ language plpgsql;

-- Add function to decline job cart
create or replace function decline_job_cart_concurrent(
  p_job_cart_id uuid,
  p_service_provider_id uuid
)
returns json as $$
declare
  v_acceptance_id uuid;
begin
  -- Use row-level locking to prevent race conditions
  perform 1 from job_cart_acceptance 
  where job_cart_id = p_job_cart_id 
  and service_provider_id = p_service_provider_id
  for update;
  
  -- Check if acceptance already exists
  if found then
    select acceptance_id into v_acceptance_id
    from job_cart_acceptance 
    where job_cart_id = p_job_cart_id 
    and service_provider_id = p_service_provider_id;
    
    return json_build_object(
      'success', false,
      'message', 'Job cart already processed by this service provider',
      'acceptance_id', v_acceptance_id
    );
  end if;
  
  -- Create decline record
  insert into job_cart_acceptance (
    job_cart_id, 
    service_provider_id, 
    acceptance_status, 
    declined_at
  ) values (
    p_job_cart_id, 
    p_service_provider_id, 
    'declined', 
    now()
  ) returning acceptance_id into v_acceptance_id;
  
  return json_build_object(
    'success', true,
    'message', 'Job cart declined',
    'acceptance_id', v_acceptance_id
  );
end;
$$ language plpgsql;
