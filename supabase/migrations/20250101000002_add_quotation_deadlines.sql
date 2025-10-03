-- Add quotation deadline system
-- This migration adds time limits for service providers to upload quotations

-- Add quotation deadline to job_cart_acceptance table
alter table job_cart_acceptance add column quotation_deadline timestamp;
alter table job_cart_acceptance add column quotation_uploaded_at timestamp;

-- Add index for deadline queries
create index idx_quotation_deadline on job_cart_acceptance(quotation_deadline);

-- Add function to set quotation deadline when job is accepted
create or replace function set_quotation_deadline()
returns trigger as $$
begin
  -- When a job cart is accepted, set deadline to 6 hours from now
  -- This ensures quick response times while giving providers enough time to prepare quotes
  if TG_OP = 'INSERT' and NEW.acceptance_status = 'accepted' then
    NEW.quotation_deadline = now() + interval '6 hours';
    return NEW;
  end if;
  
  return NEW;
end;
$$ language plpgsql;

-- Create trigger to automatically set quotation deadline
create trigger trigger_set_quotation_deadline
  before insert on job_cart_acceptance
  for each row
  execute function set_quotation_deadline();

-- Add function to update quotation upload time
create or replace function update_quotation_upload_time()
returns trigger as $$
begin
  -- When a quotation is uploaded, update the acceptance record
  if TG_OP = 'INSERT' then
    update job_cart_acceptance 
    set quotation_uploaded_at = now()
    where job_cart_id = NEW.job_cart_id 
    and service_provider_id = NEW.service_provider_id
    and acceptance_status = 'accepted';
  end if;
  
  return NEW;
end;
$$ language plpgsql;

-- Create trigger to update quotation upload time
create trigger trigger_update_quotation_upload_time
  after insert on quotation
  for each row
  execute function update_quotation_upload_time();

-- Add function to check for expired quotations
create or replace function check_expired_quotations()
returns void as $$
begin
  -- Mark acceptances as expired if deadline passed and no quotation uploaded
  update job_cart_acceptance 
  set acceptance_status = 'expired'
  where acceptance_status = 'accepted'
  and quotation_deadline < now()
  and quotation_uploaded_at is null;
  
  -- Log expired acceptances
  insert into system_log (log_type, log_message, created_at)
  select 
    'quotation_expired',
    'Quotation deadline expired for job cart ' || job_cart_id || ' by provider ' || service_provider_id,
    now()
  from job_cart_acceptance 
  where acceptance_status = 'expired'
  and quotation_deadline < now()
  and quotation_uploaded_at is null;
end;
$$ language plpgsql;

-- Add system log table for tracking expired quotations
create table if not exists system_log (
  log_id uuid primary key default gen_random_uuid(),
  log_type text not null,
  log_message text not null,
  created_at timestamp default now()
);

-- Add index for system log queries
create index idx_system_log_type on system_log(log_type);
create index idx_system_log_created on system_log(created_at);

-- Add function to get quotation status for a job cart
create or replace function get_job_cart_quotation_status(p_job_cart_id uuid)
returns json as $$
declare
  v_result json;
  v_total_acceptances int;
  v_uploaded_quotations int;
  v_pending_quotations int;
  v_expired_quotations int;
  v_min_quotations int := 3; -- Minimum quotations required
begin
  -- Count different types of acceptances
  select 
    count(*) filter (where acceptance_status = 'accepted'),
    count(*) filter (where acceptance_status = 'accepted' and quotation_uploaded_at is not null),
    count(*) filter (where acceptance_status = 'accepted' and quotation_uploaded_at is null and quotation_deadline > now()),
    count(*) filter (where acceptance_status = 'expired')
  into v_total_acceptances, v_uploaded_quotations, v_pending_quotations, v_expired_quotations
  from job_cart_acceptance 
  where job_cart_id = p_job_cart_id;
  
  -- Build result
  v_result := json_build_object(
    'job_cart_id', p_job_cart_id,
    'total_acceptances', v_total_acceptances,
    'uploaded_quotations', v_uploaded_quotations,
    'pending_quotations', v_pending_quotations,
    'expired_quotations', v_expired_quotations,
    'minimum_required', v_min_quotations,
    'quotations_sufficient', v_uploaded_quotations >= v_min_quotations,
    'still_waiting', v_pending_quotations > 0,
    'status', case 
      when v_uploaded_quotations >= v_min_quotations then 'sufficient_quotations'
      when v_pending_quotations > 0 then 'waiting_for_quotations'
      when v_expired_quotations > 0 and v_uploaded_quotations < v_min_quotations then 'insufficient_quotations'
      else 'no_acceptances'
    end
  );
  
  return v_result;
end;
$$ language plpgsql;

-- Add function to get quotation deadline countdown
create or replace function get_quotation_countdown(p_job_cart_id uuid, p_service_provider_id uuid)
returns json as $$
declare
  v_deadline timestamp;
  v_uploaded_at timestamp;
  v_seconds_remaining int;
  v_status text;
begin
  -- Get deadline and upload time
  select quotation_deadline, quotation_uploaded_at
  into v_deadline, v_uploaded_at
  from job_cart_acceptance 
  where job_cart_id = p_job_cart_id 
  and service_provider_id = p_service_provider_id
  and acceptance_status = 'accepted';
  
  -- Check if quotation already uploaded
  if v_uploaded_at is not null then
    return json_build_object(
      'status', 'uploaded',
      'message', 'Quotation already uploaded',
      'uploaded_at', v_uploaded_at
    );
  end if;
  
  -- Check if deadline has passed
  if v_deadline < now() then
    return json_build_object(
      'status', 'expired',
      'message', 'Quotation deadline has passed',
      'deadline', v_deadline,
      'seconds_overdue', extract(epoch from (now() - v_deadline))::int
    );
  end if;
  
  -- Calculate seconds remaining
  v_seconds_remaining := extract(epoch from (v_deadline - now()))::int;
  
  -- Determine status (adjusted for 6-hour timeline)
  if v_seconds_remaining > 14400 then -- More than 4 hours
    v_status := 'plenty_time';
  elsif v_seconds_remaining > 7200 then -- More than 2 hours
    v_status := 'moderate_time';
  elsif v_seconds_remaining > 1800 then -- More than 30 minutes
    v_status := 'urgent';
  else
    v_status := 'critical';
  end if;
  
  return json_build_object(
    'status', v_status,
    'deadline', v_deadline,
    'seconds_remaining', v_seconds_remaining,
    'hours_remaining', (v_seconds_remaining / 3600)::numeric(4,1),
    'message', case v_status
      when 'plenty_time' then 'You have plenty of time to upload your quotation'
      when 'moderate_time' then 'Please prepare and upload your quotation soon'
      when 'urgent' then 'Deadline approaching - please upload your quotation now'
      when 'critical' then 'Deadline very close - upload quotation immediately!'
    end
  );
end;
$$ language plpgsql;
