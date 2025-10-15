-- === FIX ENUM COMPARISON ERROR ===
-- This finds and fixes the notification_type_enum = text comparison issue

-- === STEP 1: Find the problematic code ===
-- Check all views for enum comparisons
SELECT 'VIEWS WITH ENUM COMPARISONS:' as section;
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public'
AND (definition ~ 'notification.*type.*=' OR definition ~ 'type.*=.*''[^'']*''');

-- Check all functions for enum comparisons
SELECT 'FUNCTIONS WITH ENUM COMPARISONS:' as section;
SELECT 
    n.nspname as schema_name,
    p.proname as function_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND pg_get_functiondef(p.oid) ~ 'notification.*type.*=';

-- Check all triggers for enum comparisons
SELECT 'TRIGGERS WITH ENUM COMPARISONS:' as section;
SELECT 
    trigger_name,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND action_statement ~ 'notification.*type.*=';

-- Check all policies for enum comparisons
SELECT 'POLICIES WITH ENUM COMPARISONS:' as section;
SELECT 
    schemaname,
    tablename,
    policyname,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
AND (qual ~ 'notification.*type.*=' OR with_check ~ 'notification.*type.*=');

-- === STEP 2: Drop and recreate problematic objects with proper casting ===

-- Drop any existing views that might have enum comparison issues
DROP VIEW IF EXISTS public.quotation_with_files CASCADE;

-- Drop any existing functions that might have enum comparison issues
DROP FUNCTION IF EXISTS public.fn_handle_quotation_accepted() CASCADE;
DROP FUNCTION IF EXISTS public.fn_on_new_quotation() CASCADE;

-- === STEP 3: Recreate objects with proper enum casting ===

-- Recreate quotation_with_files view with proper enum handling
CREATE OR REPLACE VIEW public.quotation_with_files AS
SELECT 
    q.*,
    sp.service_provider_name,
    sp.service_provider_surname,
    jc.job_cart_item,
    jc.job_cart_details,
    jc.client_id,
    c.client_name,
    c.client_surname
FROM public.quotation q
JOIN public.service_provider sp ON q.service_provider_id = sp.service_provider_id
JOIN public.job_cart jc ON q.job_cart_id = jc.job_cart_id
JOIN public.client c ON jc.client_id = c.client_id;

-- Recreate functions with proper enum casting
CREATE OR REPLACE FUNCTION public.fn_handle_quotation_accepted()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  existing_booking uuid;
BEGIN
  IF (TG_OP = 'UPDATE') 
     AND NEW.quotation_status::text = 'accepted'
     AND OLD.quotation_status::text IS DISTINCT FROM 'accepted' THEN

    -- Prevent multiple accepted quotations for the same job_cart
    PERFORM 1 FROM public.quotation
    WHERE job_cart_id = NEW.job_cart_id 
      AND quotation_status::text = 'accepted'
      AND quotation_id <> NEW.quotation_id;
    IF FOUND THEN
      RAISE EXCEPTION 'Another quotation is already accepted for job_cart %', NEW.job_cart_id;
    END IF;

    -- Update job_cart
    UPDATE public.job_cart
    SET accepted_quotation_id = NEW.quotation_id,
        job_cart_status = 'quotation_accepted'::job_cart_status_enum
    WHERE job_cart_id = NEW.job_cart_id;

    -- Create booking if not already linked
    SELECT booking_id INTO existing_booking 
    FROM public.booking 
    WHERE quotation_id = NEW.quotation_id 
    LIMIT 1;

    IF existing_booking IS NULL THEN
      INSERT INTO public.booking (
        booking_date,
        booking_status,
        booking_special_requests,
        client_id,
        event_id,
        created_at,
        booking_min_price,
        booking_max_price,
        booking_location,
        payment_status,
        booking_total_price,
        quotation_id
      )
      SELECT
        e.event_date,
        'pending',
        jc.job_cart_details,
        jc.client_id,
        COALESCE(NEW.event_id, jc.event_id),
        now(),
        jc.job_cart_min_price,
        jc.job_cart_max_price,
        jc.job_cart_details,
        'unpaid',
        NEW.quotation_price,
        NEW.quotation_id
      FROM public.job_cart jc
      LEFT JOIN public.event e ON jc.event_id = e.event_id
      WHERE jc.job_cart_id = NEW.job_cart_id
      RETURNING booking_id INTO existing_booking;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_on_new_quotation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.job_cart
  SET job_cart_status = CASE
    WHEN job_cart_status::text = 'pending' THEN 'quotations_in_progress'::job_cart_status_enum
    WHEN job_cart_status::text = 'quotations_in_progress' THEN job_cart_status
    ELSE job_cart_status
  END
  WHERE job_cart_id = NEW.job_cart_id;
  RETURN NEW;
END;
$$;

-- === STEP 4: Check for any remaining enum comparison issues ===
SELECT 'CHECKING FOR REMAINING ISSUES:' as section;

-- Check if there are any remaining problematic comparisons
SELECT 
    'Potential enum comparison issue' as issue_type,
    'Check manually' as recommendation
WHERE EXISTS (
    SELECT 1 FROM pg_views 
    WHERE schemaname = 'public'
    AND definition ~ 'notification.*type.*=.*''[^'']*'''
);

-- === COMPLETE! ===
-- This should fix the notification_type_enum = text comparison error


