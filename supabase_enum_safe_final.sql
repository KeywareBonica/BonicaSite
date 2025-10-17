-- === SUPABASE ENUM-SAFE FINAL SOLUTION ===
-- This script creates everything with proper enum casting to avoid type mismatches

-- === STEP 1: Drop ALL problematic objects first ===
DROP VIEW IF EXISTS quotation_with_files CASCADE;
DROP VIEW IF EXISTS notification_view CASCADE;
DROP POLICY IF EXISTS "Users can view quotation history for their quotations" ON public.quotation_history CASCADE;

-- === STEP 2: Create enums with comprehensive values ===
DO $$
BEGIN
  -- Job Cart Status ENUM
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_cart_status_enum') THEN
    CREATE TYPE job_cart_status_enum AS ENUM (
      'pending',
      'accepted',
      'quotations_in_progress',
      'awaiting_client_decision',
      'quotation_accepted',
      'completed',
      'cancelled'
    );
  END IF;

  -- Quotation Status ENUM
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'quotation_status_enum') THEN
    CREATE TYPE quotation_status_enum AS ENUM (
      'pending',
      'accepted',
      'rejected',
      'withdrawn',
      'submitted',
      'confirmed'
    );
  END IF;

  -- Notification Type ENUM
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type_enum') THEN
    CREATE TYPE notification_type_enum AS ENUM (
      'info',
      'success', 
      'warning',
      'error'
    );
  END IF;

  -- User Type ENUM
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_type_enum') THEN
    CREATE TYPE user_type_enum AS ENUM (
      'client',
      'service_provider'
    );
  END IF;
END$$;

-- === STEP 3: Add new columns first ===
ALTER TABLE public.job_cart 
ADD COLUMN IF NOT EXISTS accepted_quotation_id uuid,
ADD COLUMN IF NOT EXISTS job_cart_min_price numeric,
ADD COLUMN IF NOT EXISTS job_cart_max_price numeric;

ALTER TABLE public.booking 
ADD COLUMN IF NOT EXISTS quotation_id uuid;

-- === STEP 4: Convert columns to enums (handle defaults) ===

-- Convert job_cart_status
ALTER TABLE public.job_cart ALTER COLUMN job_cart_status DROP DEFAULT;
ALTER TABLE public.job_cart 
ALTER COLUMN job_cart_status TYPE job_cart_status_enum 
USING job_cart_status::job_cart_status_enum;
ALTER TABLE public.job_cart 
ALTER COLUMN job_cart_status SET DEFAULT 'pending'::job_cart_status_enum;

-- Convert quotation_status
ALTER TABLE public.quotation ALTER COLUMN quotation_status DROP DEFAULT;
ALTER TABLE public.quotation 
ALTER COLUMN quotation_status TYPE quotation_status_enum 
USING quotation_status::quotation_status_enum;
ALTER TABLE public.quotation 
ALTER COLUMN quotation_status SET DEFAULT 'pending'::quotation_status_enum;

-- Convert notification.type
ALTER TABLE public.notification ALTER COLUMN type DROP DEFAULT;
ALTER TABLE public.notification 
ALTER COLUMN type TYPE notification_type_enum 
USING type::notification_type_enum;

-- Convert notification.user_type
ALTER TABLE public.notification 
ALTER COLUMN user_type TYPE user_type_enum 
USING user_type::user_type_enum;

-- Convert resource_locks.user_type
ALTER TABLE public.resource_locks 
ALTER COLUMN user_type TYPE user_type_enum 
USING user_type::user_type_enum;

-- === STEP 5: Add foreign key constraints ===
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'job_cart_accepted_quotation_fkey'
  ) THEN
    ALTER TABLE public.job_cart
    ADD CONSTRAINT job_cart_accepted_quotation_fkey
    FOREIGN KEY (accepted_quotation_id)
    REFERENCES public.quotation(quotation_id);
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'booking_quotation_fkey'
  ) THEN
    ALTER TABLE public.booking
    ADD CONSTRAINT booking_quotation_fkey
    FOREIGN KEY (quotation_id) 
    REFERENCES public.quotation(quotation_id);
  END IF;
END$$;

-- === STEP 6: Create quotation_history table ===
CREATE TABLE IF NOT EXISTS public.quotation_history (
  history_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quotation_id uuid NOT NULL,
  action text NOT NULL,
  performed_by uuid,
  performed_by_type user_type_enum,
  performed_at timestamp without time zone DEFAULT now(),
  details text,
  CONSTRAINT quotation_history_quotation_fkey FOREIGN KEY (quotation_id) REFERENCES public.quotation(quotation_id)
);

-- === STEP 7: Add business rule constraint ===
CREATE UNIQUE INDEX IF NOT EXISTS uq_one_accepted_per_job_cart
ON public.quotation (job_cart_id)
WHERE quotation_status = 'accepted'::quotation_status_enum;

-- === STEP 8: Create performance indexes ===
CREATE INDEX IF NOT EXISTS idx_jobcart_client ON public.job_cart (client_id);
CREATE INDEX IF NOT EXISTS idx_jobcart_event ON public.job_cart (event_id);
CREATE INDEX IF NOT EXISTS idx_quotation_jobcart ON public.quotation (job_cart_id);
CREATE INDEX IF NOT EXISTS idx_quotation_provider ON public.quotation (service_provider_id);
CREATE INDEX IF NOT EXISTS idx_booking_client ON public.booking (client_id);
CREATE INDEX IF NOT EXISTS idx_booking_event ON public.booking (event_id);
CREATE INDEX IF NOT EXISTS idx_quotation_history_quotation ON public.quotation_history (quotation_id);

-- === STEP 9: Create enum-safe trigger functions ===
CREATE OR REPLACE FUNCTION public.fn_handle_quotation_accepted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  existing_booking uuid;
BEGIN
  IF (TG_OP = 'UPDATE') 
     AND NEW.quotation_status = 'accepted'::quotation_status_enum 
     AND OLD.quotation_status IS DISTINCT FROM 'accepted'::quotation_status_enum THEN

    -- Update job_cart with accepted quotation
    UPDATE public.job_cart
    SET accepted_quotation_id = NEW.quotation_id,
        job_cart_status = 'accepted'::job_cart_status_enum
    WHERE job_cart_id = NEW.job_cart_id;

    -- Create booking if not exists
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
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.job_cart
  SET job_cart_status = 'quotations_in_progress'::job_cart_status_enum
  WHERE job_cart_id = NEW.job_cart_id
  AND job_cart_status = 'pending'::job_cart_status_enum;
  
  RETURN NEW;
END;
$$;

-- === STEP 10: Create triggers ===
DROP TRIGGER IF EXISTS trg_quotation_after_update ON public.quotation;
CREATE TRIGGER trg_quotation_after_update
AFTER UPDATE ON public.quotation
FOR EACH ROW
EXECUTE FUNCTION public.fn_handle_quotation_accepted();

DROP TRIGGER IF EXISTS trg_quotation_after_insert ON public.quotation;
CREATE TRIGGER trg_quotation_after_insert
AFTER INSERT ON public.quotation
FOR EACH ROW
EXECUTE FUNCTION public.fn_on_new_quotation();

-- === STEP 11: Set up Row Level Security with enum-safe policies ===
ALTER TABLE public.quotation_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view quotation history for their quotations" ON public.quotation_history
FOR SELECT USING (
  quotation_id IN (
    SELECT quotation_id FROM public.quotation q
    JOIN public.job_cart jc ON q.job_cart_id = jc.job_cart_id
    WHERE jc.client_id = auth.uid()::uuid
    OR q.service_provider_id = auth.uid()::uuid
  )
);

-- === STEP 12: Grant permissions ===
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.quotation_history TO authenticated;
GRANT USAGE ON TYPE job_cart_status_enum TO authenticated;
GRANT USAGE ON TYPE quotation_status_enum TO authenticated;
GRANT USAGE ON TYPE notification_type_enum TO authenticated;
GRANT USAGE ON TYPE user_type_enum TO authenticated;

-- === STEP 13: Create enum-safe views ===
CREATE VIEW public.quotation_with_files AS
SELECT 
  q.quotation_id,
  q.service_provider_id,
  q.job_cart_id,
  q.quotation_price,
  q.quotation_details,
  q.quotation_file_path,
  q.quotation_file_name,
  q.quotation_submission_date,
  q.quotation_submission_time,
  q.quotation_status::text as quotation_status,  -- Cast enum to text for compatibility
  q.created_at,
  q.event_id,
  q.booking_id,
  q.service_id
FROM public.quotation q
WHERE q.quotation_file_path IS NOT NULL;

-- Create enum-safe notification view
CREATE VIEW public.notification_view AS
SELECT 
  n.notification_id,
  n.user_id,
  n.user_type::text as user_type,  -- Cast enum to text
  n.title,
  n.message,
  n.type::text as type,  -- Cast enum to text
  n.is_read,
  n.created_at,
  n.read_at
FROM public.notification n;

-- === STEP 14: Create enum-safe helper functions ===
CREATE OR REPLACE FUNCTION public.get_notifications_by_type(notification_type text)
RETURNS TABLE (
  notification_id uuid,
  user_id uuid,
  user_type text,
  title text,
  message text,
  type text,
  is_read boolean,
  created_at timestamp without time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    n.notification_id,
    n.user_id,
    n.user_type::text,
    n.title,
    n.message,
    n.type::text,
    n.is_read,
    n.created_at
  FROM public.notification n
  WHERE n.type = notification_type::notification_type_enum;  -- Cast text to enum
END;
$$;

-- === DONE! ===
-- This script creates everything with proper enum casting:
-- ✅ All enum comparisons use proper casting (::enum_type or ::text)
-- ✅ Views cast enums to text for compatibility
-- ✅ Triggers use enum literals with proper casting
-- ✅ Policies are enum-safe
-- ✅ Helper functions handle enum conversions properly
-- ✅ No more "operator does not exist" errors!







