-- === FINAL WORKING MIGRATION - ALL ERRORS FIXED ===
-- This fixes ALL the errors we've encountered from the beginning

-- === STEP 1: Required extension ===
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- === STEP 2: Create enums if they don't already exist ===
DO $$
BEGIN
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

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type_enum') THEN
    CREATE TYPE notification_type_enum AS ENUM ('info','success','warning','error');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_type_enum') THEN
    CREATE TYPE user_type_enum AS ENUM ('client','service_provider');
  END IF;
END$$;

-- === STEP 3: Drop any existing views that might cause issues ===
DROP VIEW IF EXISTS public.quotation_with_files CASCADE;

-- === STEP 4: Add new columns to existing tables ===
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS accepted_quotation_id uuid;
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS job_cart_min_price numeric;
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS job_cart_max_price numeric;

ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_details text;
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_file_path text;
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_file_name text;

ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_special_requests text;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_min_price numeric;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_max_price numeric;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_location text;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS payment_status text;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_total_price numeric;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS quotation_id uuid;

ALTER TABLE public.notification ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false;
ALTER TABLE public.notification ADD COLUMN IF NOT EXISTS read_at timestamp;

ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_location text;
ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_base_rate numeric;
ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_overtime_rate numeric;
ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_rating numeric DEFAULT 0.00;
ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_verification boolean DEFAULT false;

ALTER TABLE public.client ADD COLUMN IF NOT EXISTS client_city text;
ALTER TABLE public.client ADD COLUMN IF NOT EXISTS client_town text;

ALTER TABLE public.event ADD COLUMN IF NOT EXISTS event_end_time time;
ALTER TABLE public.event ADD COLUMN IF NOT EXISTS event_location text;

ALTER TABLE public.event_service ADD COLUMN IF NOT EXISTS event_service_notes text;

-- === STEP 5: Convert columns to enums (FIXED FOR ALL DEFAULT VALUE ISSUES) ===

-- Convert job_cart_status to enum
ALTER TABLE public.job_cart
  ALTER COLUMN job_cart_status DROP DEFAULT;
ALTER TABLE public.job_cart
  ALTER COLUMN job_cart_status TYPE job_cart_status_enum
  USING job_cart_status::job_cart_status_enum;
ALTER TABLE public.job_cart
  ALTER COLUMN job_cart_status SET DEFAULT 'pending'::job_cart_status_enum;

-- Convert quotation_status to enum
ALTER TABLE public.quotation
  ALTER COLUMN quotation_status DROP DEFAULT;
ALTER TABLE public.quotation
  ALTER COLUMN quotation_status TYPE quotation_status_enum
  USING quotation_status::quotation_status_enum;
ALTER TABLE public.quotation
  ALTER COLUMN quotation_status SET DEFAULT 'pending'::quotation_status_enum;

-- Convert notification type to enum
ALTER TABLE public.notification
  ALTER COLUMN type TYPE notification_type_enum
  USING type::notification_type_enum;

-- Convert notification user_type to enum
ALTER TABLE public.notification
  ALTER COLUMN user_type TYPE user_type_enum
  USING user_type::user_type_enum;

-- Convert resource_locks user_type to enum (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'resource_locks' AND table_schema = 'public') THEN
    ALTER TABLE public.resource_locks
    ALTER COLUMN user_type TYPE user_type_enum
    USING user_type::user_type_enum;
  END IF;
END$$;

-- === STEP 6: Add foreign key constraints (FIXED FOR IF NOT EXISTS ISSUES) ===
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'job_cart_accepted_quotation_fkey'
    AND table_name = 'job_cart'
    AND table_schema = 'public'
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
    AND table_name = 'booking'
    AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.booking
    ADD CONSTRAINT booking_quotation_fkey
    FOREIGN KEY (quotation_id)
    REFERENCES public.quotation(quotation_id);
  END IF;
END$$;

-- === STEP 7: Create quotation_history table ===
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

-- === STEP 8: Add indexes for performance ===
CREATE INDEX IF NOT EXISTS idx_jobcart_client ON public.job_cart (client_id);
CREATE INDEX IF NOT EXISTS idx_jobcart_event ON public.job_cart (event_id);
CREATE INDEX IF NOT EXISTS idx_quotation_jobcart ON public.quotation (job_cart_id);
CREATE INDEX IF NOT EXISTS idx_quotation_provider ON public.quotation (service_provider_id);
CREATE INDEX IF NOT EXISTS idx_booking_client ON public.booking (client_id);
CREATE INDEX IF NOT EXISTS idx_booking_event ON public.booking (event_id);

-- === STEP 9: Recreate quotation_with_files view (ENUM-SAFE) ===
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

-- === STEP 10: Add trigger functions for automation ===

-- Function: handle quotation accepted
CREATE OR REPLACE FUNCTION public.fn_handle_quotation_accepted()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  existing_booking uuid;
BEGIN
  IF (TG_OP = 'UPDATE') 
     AND NEW.quotation_status = 'accepted'::quotation_status_enum
     AND OLD.quotation_status IS DISTINCT FROM 'accepted'::quotation_status_enum THEN

    -- Prevent multiple accepted quotations for the same job_cart
    PERFORM 1 FROM public.quotation
    WHERE job_cart_id = NEW.job_cart_id 
      AND quotation_status = 'accepted'::quotation_status_enum
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

-- Function: on new quotation insert
CREATE OR REPLACE FUNCTION public.fn_on_new_quotation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.job_cart
  SET job_cart_status = CASE
    WHEN job_cart_status = 'pending'::job_cart_status_enum THEN 'quotations_in_progress'::job_cart_status_enum
    WHEN job_cart_status = 'quotations_in_progress'::job_cart_status_enum THEN job_cart_status
    ELSE job_cart_status
  END
  WHERE job_cart_id = NEW.job_cart_id;
  RETURN NEW;
END;
$$;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS trg_quotation_after_update ON public.quotation;
DROP TRIGGER IF EXISTS trg_quotation_after_insert ON public.quotation;

-- Create triggers
CREATE TRIGGER trg_quotation_after_update
AFTER UPDATE ON public.quotation
FOR EACH ROW
EXECUTE FUNCTION public.fn_handle_quotation_accepted();

CREATE TRIGGER trg_quotation_after_insert
AFTER INSERT ON public.quotation
FOR EACH ROW
EXECUTE FUNCTION public.fn_on_new_quotation();

-- === COMPLETE! ===
-- All errors have been fixed and the schema is now complete with enums


