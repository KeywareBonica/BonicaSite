-- =====================================================
-- LOOPHOLE 5 & 6: STATUS TRACKING & TIME LIMITS FIX
-- =====================================================
-- Problem 5: No quotation_status field being used properly
-- Problem 6: No quotation deadline on service provider side
-- Solution: Comprehensive status tracking and time limit system

-- Step 1: Drop dependent views first
DROP VIEW IF EXISTS public.quotation_with_file_validation CASCADE;
DROP VIEW IF EXISTS public.quotation_with_files CASCADE;
DROP VIEW IF EXISTS public.quotation_with_file_validation_enhanced CASCADE;
DROP VIEW IF EXISTS public.quotation_with_status_info CASCADE;
DROP VIEW IF EXISTS public.quotation_view CASCADE;
DROP VIEW IF EXISTS public.quotation_with_location CASCADE;

-- Step 2: Enhance quotation_status_enum with more statuses
DO $$
BEGIN
    -- Drop existing enum if it exists to recreate with more values
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'quotation_status_enum') THEN
        -- First, remove the enum from the column
        ALTER TABLE public.quotation ALTER COLUMN quotation_status TYPE text;
        DROP TYPE public.quotation_status_enum CASCADE;
    END IF;
    
    -- Create enhanced enum with comprehensive statuses
    CREATE TYPE quotation_status_enum AS ENUM (
        'pending',           -- Initial status when quotation is submitted
        'submitted',         -- Quotation has been submitted (existing data)
        'under_review',      -- Quotation is being reviewed by client
        'accepted',          -- Client has accepted the quotation
        'rejected',          -- Client has rejected the quotation
        'withdrawn',         -- Service provider withdrew the quotation
        'expired',           -- Quotation has expired due to time limits
        'cancelled',         -- Quotation was cancelled by system or admin
        'confirmed',         -- Quotation is confirmed and booking created
        'completed'          -- Service has been completed
    );
    
    -- First, drop the default value
    ALTER TABLE public.quotation 
    ALTER COLUMN quotation_status DROP DEFAULT;
    
    -- Convert the column back to enum
    ALTER TABLE public.quotation 
    ALTER COLUMN quotation_status TYPE quotation_status_enum 
    USING quotation_status::quotation_status_enum;
    
    -- Set default value with explicit casting
    ALTER TABLE public.quotation 
    ALTER COLUMN quotation_status SET DEFAULT 'pending'::quotation_status_enum;
END$$;

-- Step 3: Add time limit columns to quotation table
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_deadline timestamp without time zone;
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_expiry_date timestamp without time zone;
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_created_at timestamp without time zone DEFAULT now();
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_last_updated timestamp without time zone DEFAULT now();

-- Step 4: Add time limit columns to job_cart table
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS quotation_deadline timestamp without time zone;
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS quotation_expiry_minutes integer DEFAULT 2; -- 2 minutes default for service providers to submit
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS quotation_submission_deadline timestamp without time zone; -- When submission period ends
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS client_review_deadline timestamp without time zone; -- When client must decide
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS client_review_hours integer DEFAULT 24; -- 24 hours for client to review
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS submission_period_ended boolean DEFAULT false; -- Flag when submission period is over

-- Step 5: Create function to set quotation deadlines
CREATE OR REPLACE FUNCTION public.set_quotation_deadlines()
RETURNS TRIGGER AS $$
DECLARE
    expiry_minutes integer;
    deadline_time timestamp without time zone;
BEGIN
    -- Get expiry minutes from job_cart (default 2 minutes)
    SELECT COALESCE(jc.quotation_expiry_minutes, 2) INTO expiry_minutes
    FROM public.job_cart jc
    WHERE jc.job_cart_id = NEW.job_cart_id;
    
    -- Calculate deadline time
    deadline_time := NOW() + (expiry_minutes || ' minutes')::interval;
    
    -- Set deadline and expiry for new quotation
    IF TG_OP = 'INSERT' THEN
        NEW.quotation_deadline := deadline_time;
        NEW.quotation_expiry_date := deadline_time;
        NEW.quotation_created_at := NOW();
        NEW.quotation_last_updated := NOW();
    END IF;
    
    -- Update last_updated for any changes
    IF TG_OP = 'UPDATE' THEN
        NEW.quotation_last_updated := NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Create trigger for quotation deadlines
DROP TRIGGER IF EXISTS trg_set_quotation_deadlines ON public.quotation;
CREATE TRIGGER trg_set_quotation_deadlines
    BEFORE INSERT OR UPDATE ON public.quotation
    FOR EACH ROW 
    EXECUTE FUNCTION public.set_quotation_deadlines();

-- Step 7: Create function to automatically expire quotations
-- BUSINESS RULE: Only expire 'pending' quotations (service providers who didn't submit in time)
-- Do NOT expire 'under_review' quotations (client is still deciding)
CREATE OR REPLACE FUNCTION public.expire_old_quotations()
RETURNS integer AS $$
DECLARE
    expired_count integer;
BEGIN
    -- Update quotations that have passed their deadline and are still pending
    -- This means service providers who didn't submit within the 2-minute window
    UPDATE public.quotation 
    SET quotation_status = 'expired',
        quotation_last_updated = NOW()
    WHERE quotation_status = 'pending'  -- Only pending, NOT under_review
    AND quotation_expiry_date < NOW()
    AND quotation_expiry_date IS NOT NULL;
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    
    -- Log expired quotations
    IF expired_count > 0 THEN
        RAISE NOTICE 'Expired % quotations due to time limits (service providers did not submit in time)', expired_count;
    END IF;
    
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 8: Create function to validate quotation status transitions
CREATE OR REPLACE FUNCTION public.validate_quotation_status_transition()
RETURNS TRIGGER AS $$
DECLARE
    valid_transitions text[];
BEGIN
    -- Define valid status transitions
    valid_transitions := ARRAY[
        'pending->under_review',
        'pending->accepted',
        'pending->rejected',
        'pending->withdrawn',
        'pending->expired',
        'pending->cancelled',
        'under_review->accepted',
        'under_review->rejected',
        'under_review->withdrawn',
        'under_review->expired',
        'under_review->cancelled',
        'accepted->confirmed',
        'accepted->withdrawn',
        'confirmed->completed'
    ];
    
    -- Check if transition is valid
    IF OLD.quotation_status IS DISTINCT FROM NEW.quotation_status THEN
        IF NOT (OLD.quotation_status::text || '->' || NEW.quotation_status::text = ANY(valid_transitions)) THEN
            RAISE EXCEPTION 'Invalid status transition from % to %. Valid transitions: %', 
                OLD.quotation_status, NEW.quotation_status, array_to_string(valid_transitions, ', ');
        END IF;
        
        -- Log status change
        RAISE NOTICE 'Quotation % status changed from % to %', 
            NEW.quotation_id, OLD.quotation_status, NEW.quotation_status;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 9: Create trigger for status validation
DROP TRIGGER IF EXISTS trg_validate_quotation_status ON public.quotation;
CREATE TRIGGER trg_validate_quotation_status
    BEFORE UPDATE ON public.quotation
    FOR EACH ROW 
    EXECUTE FUNCTION public.validate_quotation_status_transition();

-- Step 10: Create quotation status history table
CREATE TABLE IF NOT EXISTS public.quotation_status_history (
    history_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    quotation_id uuid NOT NULL,
    old_status quotation_status_enum,
    new_status quotation_status_enum NOT NULL,
    changed_by uuid,
    changed_by_type user_type_enum,
    change_reason text,
    changed_at timestamp without time zone DEFAULT now(),
    
    CONSTRAINT quotation_status_history_quotation_fkey 
        FOREIGN KEY (quotation_id) REFERENCES public.quotation(quotation_id)
);

-- Step 11: Create function to log status changes
CREATE OR REPLACE FUNCTION public.log_quotation_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only log if status actually changed
    IF OLD.quotation_status IS DISTINCT FROM NEW.quotation_status THEN
        INSERT INTO public.quotation_status_history (
            quotation_id,
            old_status,
            new_status,
            changed_by,
            changed_by_type,
            change_reason
        ) VALUES (
            NEW.quotation_id,
            OLD.quotation_status,
            NEW.quotation_status,
            -- Note: In a real implementation, you'd get the current user from auth context
            NULL, -- changed_by
            NULL, -- changed_by_type
            'Status changed via system'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 12: Create trigger for status history logging
DROP TRIGGER IF EXISTS trg_log_quotation_status ON public.quotation;
CREATE TRIGGER trg_log_quotation_status
    AFTER UPDATE ON public.quotation
    FOR EACH ROW 
    EXECUTE FUNCTION public.log_quotation_status_change();

-- Step 13: Create view for quotations with status and time information
CREATE OR REPLACE VIEW public.quotation_with_status_info AS
SELECT 
    q.*,
    CASE 
        WHEN q.quotation_status = 'expired' THEN 'Expired'
        WHEN q.quotation_expiry_date < NOW() THEN 'Expired'
        WHEN q.quotation_expiry_date < NOW() + INTERVAL '24 hours' THEN 'Expiring Soon'
        ELSE 'Active'
    END as time_status,
    CASE 
        WHEN q.quotation_expiry_date IS NOT NULL THEN 
            EXTRACT(EPOCH FROM (q.quotation_expiry_date - NOW())) / 3600
        ELSE NULL
    END as hours_until_expiry,
    CASE 
        WHEN q.quotation_expiry_date IS NOT NULL THEN 
            q.quotation_expiry_date - NOW()
        ELSE NULL
    END as time_until_expiry,
    jc.quotation_expiry_minutes as job_cart_expiry_minutes
FROM public.quotation q
LEFT JOIN public.job_cart jc ON q.job_cart_id = jc.job_cart_id;

-- Step 14: Recreate the quotation_with_files view with enum support (using existing file_storage table)
CREATE OR REPLACE VIEW public.quotation_with_files AS
SELECT 
    q.*,
    fs.file_id,
    fs.file_path,
    fs.file_name,
    fs.file_size,
    fs.file_type,
    fs.file_hash,
    fs.upload_date as uploaded_at,
    fs.updated_at as last_verified_at,
    fs.is_active as file_is_active
FROM public.quotation q
LEFT JOIN public.file_storage fs ON q.file_storage_id = fs.file_id;

-- Step 15: Recreate the quotation_with_file_validation view with enum support
CREATE OR REPLACE VIEW public.quotation_with_file_validation AS
SELECT 
    q.*,
    fs.file_id,
    fs.file_path,
    fs.file_name,
    fs.file_size,
    fs.file_type,
    fs.file_hash,
    fs.upload_date as uploaded_at,
    fs.updated_at as last_verified_at,
    fs.is_active as file_is_active,
    CASE 
        WHEN q.quotation_file_validated = true AND fs.is_active = true THEN 'Valid'
        WHEN q.quotation_file_validated = false THEN 'Not Validated'
        WHEN fs.is_active = false THEN 'File Inactive'
        ELSE 'Unknown'
    END as file_validation_status
FROM public.quotation q
LEFT JOIN public.file_storage fs ON q.file_storage_id = fs.file_id;

-- Step 16: Create function to get quotations by status
CREATE OR REPLACE FUNCTION public.get_quotations_by_status(
    p_status quotation_status_enum,
    p_user_id uuid DEFAULT NULL,
    p_user_type user_type_enum DEFAULT NULL
)
RETURNS TABLE (
    quotation_id uuid,
    quotation_price numeric,
    quotation_status quotation_status_enum,
    quotation_deadline timestamp without time zone,
    time_until_expiry interval,
    service_name text,
    client_name text,
    provider_name text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        q.quotation_id,
        q.quotation_price,
        q.quotation_status,
        q.quotation_deadline,
        q.quotation_expiry_date - NOW() as time_until_expiry,
        s.service_name,
        (c.client_name || ' ' || c.client_surname) as client_name,
        (sp.service_provider_name || ' ' || sp.service_provider_surname) as provider_name
    FROM public.quotation q
    JOIN public.job_cart jc ON q.job_cart_id = jc.job_cart_id
    JOIN public.service s ON jc.service_id = s.service_id
    JOIN public.client c ON jc.client_id = c.client_id
    JOIN public.service_provider sp ON q.service_provider_id = sp.service_provider_id
    WHERE q.quotation_status = p_status
    AND (p_user_id IS NULL OR 
         (p_user_type = 'client' AND jc.client_id = p_user_id) OR
         (p_user_type = 'service_provider' AND q.service_provider_id = p_user_id));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 17: Create function to withdraw quotation
CREATE OR REPLACE FUNCTION public.withdraw_quotation(
    p_quotation_id uuid,
    p_user_id uuid,
    p_user_type user_type_enum,
    p_reason text DEFAULT NULL
)
RETURNS boolean AS $$
DECLARE
    quotation_exists boolean;
    current_status quotation_status_enum;
BEGIN
    -- Check if quotation exists and get current status
    SELECT EXISTS(SELECT 1 FROM public.quotation WHERE quotation_id = p_quotation_id),
           quotation_status
    INTO quotation_exists, current_status
    FROM public.quotation 
    WHERE quotation_id = p_quotation_id;
    
    IF NOT quotation_exists THEN
        RAISE EXCEPTION 'Quotation not found: %', p_quotation_id;
    END IF;
    
    -- Check if quotation can be withdrawn
    IF current_status NOT IN ('pending', 'under_review') THEN
        RAISE EXCEPTION 'Cannot withdraw quotation with status: %', current_status;
    END IF;
    
    -- Update quotation status
    UPDATE public.quotation 
    SET quotation_status = 'withdrawn',
        quotation_last_updated = NOW()
    WHERE quotation_id = p_quotation_id;
    
    -- Log the withdrawal
    INSERT INTO public.quotation_status_history (
        quotation_id,
        old_status,
        new_status,
        changed_by,
        changed_by_type,
        change_reason
    ) VALUES (
        p_quotation_id,
        current_status,
        'withdrawn',
        p_user_id,
        p_user_type,
        COALESCE(p_reason, 'Quotation withdrawn by user')
    );
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 18: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_quotation_status ON public.quotation (quotation_status);
CREATE INDEX IF NOT EXISTS idx_quotation_expiry ON public.quotation (quotation_expiry_date) WHERE quotation_status IN ('pending', 'under_review');
CREATE INDEX IF NOT EXISTS idx_quotation_created_at ON public.quotation (quotation_created_at);
CREATE INDEX IF NOT EXISTS idx_quotation_last_updated ON public.quotation (quotation_last_updated);
CREATE INDEX IF NOT EXISTS idx_quotation_status_history_quotation ON public.quotation_status_history (quotation_id);

-- Step 19: Create scheduled job function for automatic expiry
-- Note: In production, this would be called by a cron job every hour
CREATE OR REPLACE FUNCTION public.run_quotation_maintenance()
RETURNS text AS $$
DECLARE
    expired_count integer;
    result_text text;
BEGIN
    -- Expire old quotations
    SELECT public.expire_old_quotations() INTO expired_count;
    
    result_text := 'Quotation maintenance completed. Expired ' || expired_count || ' quotations.';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 20: Create function to set submission deadline when job_cart is created/updated
CREATE OR REPLACE FUNCTION public.set_job_cart_submission_deadline()
RETURNS TRIGGER AS $$
DECLARE
    submission_minutes integer;
    review_hours integer;
BEGIN
    -- Set defaults if not provided
    submission_minutes := COALESCE(NEW.quotation_expiry_minutes, 2);
    review_hours := COALESCE(NEW.client_review_hours, 24);
    
    -- Set submission deadline when job_cart is created
    IF TG_OP = 'INSERT' THEN
        NEW.quotation_submission_deadline := NOW() + (submission_minutes || ' minutes')::interval;
        NEW.quotation_deadline := NEW.quotation_submission_deadline; -- For backward compatibility
        NEW.submission_period_ended := false;
        -- Client review deadline is set AFTER submission period ends
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for job_cart submission deadlines
DROP TRIGGER IF EXISTS trg_set_job_cart_submission_deadline ON public.job_cart;
CREATE TRIGGER trg_set_job_cart_submission_deadline
    BEFORE INSERT OR UPDATE ON public.job_cart
    FOR EACH ROW 
    EXECUTE FUNCTION public.set_job_cart_submission_deadline();

-- Step 21: Create function to end submission period and start client review
-- BUSINESS RULE: After submission period ends, move all 'pending' quotations to 'under_review'
-- This allows client to start reviewing quotations (even if less than 3)
CREATE OR REPLACE FUNCTION public.end_submission_period(p_job_cart_id uuid)
RETURNS TABLE (
    quotations_ready integer,
    client_review_deadline timestamp without time zone,
    message text
) AS $$
DECLARE
    job_exists boolean;
    already_ended boolean;
    review_hours integer;
    review_deadline timestamp without time zone;
    quotations_count integer;
    updated_count integer;
BEGIN
    -- Check if job_cart exists
    SELECT EXISTS(SELECT 1 FROM public.job_cart WHERE job_cart_id = p_job_cart_id),
           submission_period_ended,
           client_review_hours
    INTO job_exists, already_ended, review_hours
    FROM public.job_cart
    WHERE job_cart_id = p_job_cart_id;
    
    IF NOT job_exists THEN
        RAISE EXCEPTION 'Job cart not found: %', p_job_cart_id;
    END IF;
    
    IF already_ended THEN
        RAISE EXCEPTION 'Submission period has already ended for this job cart';
    END IF;
    
    -- Set client review deadline
    review_deadline := NOW() + (COALESCE(review_hours, 24) || ' hours')::interval;
    
    -- Update job_cart to mark submission period as ended
    UPDATE public.job_cart
    SET submission_period_ended = true,
        client_review_deadline = review_deadline
    WHERE job_cart_id = p_job_cart_id;
    
    -- Move all 'pending' quotations to 'under_review' status
    -- BUSINESS RULE: Once submission period ends, client can review whatever quotations are available
    UPDATE public.quotation
    SET quotation_status = 'under_review',
        quotation_last_updated = NOW()
    WHERE job_cart_id = p_job_cart_id
    AND quotation_status = 'pending';
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    -- Count total quotations for this job cart
    SELECT COUNT(*) INTO quotations_count
    FROM public.quotation
    WHERE job_cart_id = p_job_cart_id
    AND quotation_status IN ('under_review', 'submitted');
    
    -- Return results
    RETURN QUERY
    SELECT 
        quotations_count,
        review_deadline,
        CASE 
            WHEN quotations_count = 0 THEN 'No quotations submitted. Client may need to repost job.'
            WHEN quotations_count < 3 THEN 'Only ' || quotations_count || ' quotation(s) available. Client can still review.'
            ELSE quotations_count || ' quotations ready for client review.'
        END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 22: Create function to automatically end submission periods
CREATE OR REPLACE FUNCTION public.auto_end_submission_periods()
RETURNS integer AS $$
DECLARE
    ended_count integer := 0;
    job_record RECORD;
BEGIN
    -- Find all job_carts where submission period has ended but not marked as such
    FOR job_record IN 
        SELECT job_cart_id
        FROM public.job_cart
        WHERE quotation_submission_deadline < NOW()
        AND submission_period_ended = false
    LOOP
        -- End submission period for each job
        PERFORM public.end_submission_period(job_record.job_cart_id);
        ended_count := ended_count + 1;
    END LOOP;
    
    IF ended_count > 0 THEN
        RAISE NOTICE 'Ended submission period for % job cart(s)', ended_count;
    END IF;
    
    RETURN ended_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 23: Create function to check if client can view quotations
-- BUSINESS RULE: Client can only view quotations after submission period ends
CREATE OR REPLACE FUNCTION public.can_client_view_quotations(
    p_job_cart_id uuid,
    p_client_id uuid
)
RETURNS TABLE (
    can_view boolean,
    reason text,
    quotations_available integer,
    time_until_deadline interval
) AS $$
DECLARE
    job_exists boolean;
    is_owner boolean;
    period_ended boolean;
    review_deadline timestamp without time zone;
    quotation_count integer;
BEGIN
    -- Check if job_cart exists and belongs to client
    SELECT 
        EXISTS(SELECT 1 FROM public.job_cart WHERE job_cart_id = p_job_cart_id),
        EXISTS(SELECT 1 FROM public.job_cart WHERE job_cart_id = p_job_cart_id AND client_id = p_client_id),
        jc.submission_period_ended,
        jc.client_review_deadline
    INTO job_exists, is_owner, period_ended, review_deadline
    FROM public.job_cart jc
    WHERE jc.job_cart_id = p_job_cart_id;
    
    IF NOT job_exists THEN
        RETURN QUERY SELECT false, 'Job cart not found', 0, NULL::interval;
        RETURN;
    END IF;
    
    IF NOT is_owner THEN
        RETURN QUERY SELECT false, 'Not authorized to view this job', 0, NULL::interval;
        RETURN;
    END IF;
    
    IF NOT period_ended THEN
        RETURN QUERY SELECT false, 'Submission period has not ended yet. Please wait for service providers to submit quotations.', 0, NULL::interval;
        RETURN;
    END IF;
    
    -- Count available quotations
    SELECT COUNT(*) INTO quotation_count
    FROM public.quotation
    WHERE job_cart_id = p_job_cart_id
    AND quotation_status IN ('under_review', 'submitted');
    
    -- Client can view quotations
    RETURN QUERY 
    SELECT 
        true,
        'You can view and compare ' || quotation_count || ' quotation(s)',
        quotation_count,
        CASE 
            WHEN review_deadline IS NOT NULL THEN review_deadline - NOW()
            ELSE NULL
        END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 24: Create function to get quotations for client review
-- BUSINESS RULE: Only show quotations that are in 'under_review' status
CREATE OR REPLACE FUNCTION public.get_quotations_for_client_review(
    p_job_cart_id uuid,
    p_client_id uuid
)
RETURNS TABLE (
    quotation_id uuid,
    quotation_price numeric,
    quotation_description text,
    quotation_status quotation_status_enum,
    service_provider_id uuid,
    provider_name text,
    provider_rating numeric,
    file_path text,
    file_name text,
    created_at timestamp without time zone
) AS $$
DECLARE
    can_view_result RECORD;
BEGIN
    -- Check if client can view quotations
    SELECT * INTO can_view_result
    FROM public.can_client_view_quotations(p_job_cart_id, p_client_id)
    LIMIT 1;
    
    IF NOT can_view_result.can_view THEN
        RAISE EXCEPTION 'Cannot view quotations: %', can_view_result.reason;
    END IF;
    
    -- Return quotations for review
    RETURN QUERY
    SELECT 
        q.quotation_id,
        q.quotation_price,
        q.quotation_description,
        q.quotation_status,
        q.service_provider_id,
        (sp.service_provider_name || ' ' || sp.service_provider_surname) as provider_name,
        sp.service_provider_rating,
        fs.file_path,
        fs.file_name,
        q.quotation_created_at
    FROM public.quotation q
    JOIN public.service_provider sp ON q.service_provider_id = sp.service_provider_id
    LEFT JOIN public.file_storage fs ON q.file_storage_id = fs.file_id
    WHERE q.job_cart_id = p_job_cart_id
    AND q.quotation_status IN ('under_review', 'submitted')
    ORDER BY q.quotation_price ASC;  -- Show cheapest first
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 25: Update the maintenance function to include auto-ending submission periods
CREATE OR REPLACE FUNCTION public.run_quotation_maintenance()
RETURNS text AS $$
DECLARE
    expired_count integer;
    ended_count integer;
    result_text text;
BEGIN
    -- Auto-end submission periods that have passed
    SELECT public.auto_end_submission_periods() INTO ended_count;
    
    -- Expire old quotations (only pending ones)
    SELECT public.expire_old_quotations() INTO expired_count;
    
    result_text := 'Quotation maintenance completed. ' ||
                   'Ended ' || ended_count || ' submission period(s). ' ||
                   'Expired ' || expired_count || ' quotation(s).';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 26: Create view for client to see their jobs with quotation status
CREATE OR REPLACE VIEW public.client_job_quotation_summary AS
SELECT 
    jc.job_cart_id,
    jc.client_id,
    s.service_name,
    jc.quotation_submission_deadline,
    jc.client_review_deadline,
    jc.submission_period_ended,
    COUNT(q.quotation_id) as total_quotations,
    COUNT(q.quotation_id) FILTER (WHERE q.quotation_status = 'under_review') as quotations_under_review,
    COUNT(q.quotation_id) FILTER (WHERE q.quotation_status = 'accepted') as quotations_accepted,
    COUNT(q.quotation_id) FILTER (WHERE q.quotation_status = 'rejected') as quotations_rejected,
    MIN(q.quotation_price) as lowest_price,
    MAX(q.quotation_price) as highest_price,
    CASE 
        WHEN jc.submission_period_ended = false THEN 'Waiting for quotations'
        WHEN COUNT(q.quotation_id) FILTER (WHERE q.quotation_status = 'under_review') > 0 THEN 'Ready for review'
        WHEN COUNT(q.quotation_id) FILTER (WHERE q.quotation_status = 'accepted') > 0 THEN 'Quotation accepted'
        WHEN COUNT(q.quotation_id) = 0 THEN 'No quotations received'
        ELSE 'Review completed'
    END as status_summary
FROM public.job_cart jc
JOIN public.service s ON jc.service_id = s.service_id
LEFT JOIN public.quotation q ON jc.job_cart_id = q.job_cart_id
GROUP BY jc.job_cart_id, jc.client_id, s.service_name, 
         jc.quotation_submission_deadline, jc.client_review_deadline, 
         jc.submission_period_ended;

-- Summary with Business Rules Documentation
SELECT '
====================================================================
LOOPHOLE 5 & 6: STATUS TRACKING & TIME LIMITS - COMPLETE
====================================================================

BUSINESS RULES IMPLEMENTED:
----------------------------

1. SUBMISSION PERIOD (Service Provider Side):
   - Service providers have 2 minutes (configurable) to submit quotations
   - Quotations start with ''pending'' status
   - If not submitted within 2 minutes, status changes to ''expired''
   - Each quotation has individual deadline tracking

2. CLIENT REVIEW PERIOD:
   - After submission period ends, ALL pending quotations move to ''under_review''
   - Client can see whatever quotations are available (even if less than 3)
   - Quotations in ''under_review'' do NOT expire
   - Client has 24 hours (configurable) to review and accept/reject
   - Client can only view quotations AFTER submission period ends

3. QUOTATION VISIBILITY:
   - Service providers: Can see their own quotations at any time
   - Clients: Can only view quotations AFTER submission period ends
   - No minimum quotation requirement - client sees whatever is submitted

4. STATUS WORKFLOW:
   pending -> under_review -> accepted/rejected
   pending -> expired (if not submitted in time)
   under_review -> accepted -> confirmed -> completed
   
5. AUTOMATIC PROCESSES:
   - Auto-expire pending quotations past deadline
   - Auto-end submission periods when time is up
   - Auto-move pending quotations to under_review
   - Run via: SELECT public.run_quotation_maintenance();

KEY FUNCTIONS FOR APPLICATION:
-------------------------------
- can_client_view_quotations(job_cart_id, client_id): Check if client can view
- get_quotations_for_client_review(job_cart_id, client_id): Get quotations to display
- end_submission_period(job_cart_id): Manually end submission period
- run_quotation_maintenance(): Run scheduled maintenance (call every minute)

====================================================================
' as implementation_summary;
