-- === SUPABASE MIGRATION SCRIPT - FIXED FOR DEFAULT VALUES ===
-- This script properly handles default value conversion

-- === STEP 1: Create ENUM types ===
DO $$
BEGIN
  -- Job Cart Status ENUM
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_cart_status_enum') THEN
    CREATE TYPE job_cart_status_enum AS ENUM (
      'pending',
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
      'withdrawn'
    );
  END IF;

  -- Notification Type ENUM
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type_enum') THEN
    CREATE TYPE notification_type_enum AS ENUM ('info','success','warning','error');
  END IF;

  -- User Type ENUM
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_type_enum') THEN
    CREATE TYPE user_type_enum AS ENUM ('client','service_provider');
  END IF;
END$$;

-- === STEP 2: Convert job_cart.job_cart_status to ENUM (handle default) ===
-- Step 2a: Drop the default value
ALTER TABLE public.job_cart ALTER COLUMN job_cart_status DROP DEFAULT;

-- Step 2b: Convert the column type
ALTER TABLE public.job_cart 
ALTER COLUMN job_cart_status TYPE job_cart_status_enum 
USING job_cart_status::job_cart_status_enum;

-- Step 2c: Set the new default value
ALTER TABLE public.job_cart 
ALTER COLUMN job_cart_status SET DEFAULT 'pending'::job_cart_status_enum;

-- === STEP 3: Convert quotation.quotation_status to ENUM (handle default) ===
-- Step 3a: Drop the default value
ALTER TABLE public.quotation ALTER COLUMN quotation_status DROP DEFAULT;

-- Step 3b: Convert the column type
ALTER TABLE public.quotation 
ALTER COLUMN quotation_status TYPE quotation_status_enum 
USING quotation_status::quotation_status_enum;

-- Step 3c: Set the new default value
ALTER TABLE public.quotation 
ALTER COLUMN quotation_status SET DEFAULT 'pending'::quotation_status_enum;

-- === STEP 4: Convert notification.type to ENUM (handle default) ===
-- Step 4a: Drop the default value
ALTER TABLE public.notification ALTER COLUMN type DROP DEFAULT;

-- Step 4b: Convert the column type
ALTER TABLE public.notification 
ALTER COLUMN type TYPE notification_type_enum 
USING type::notification_type_enum;

-- === STEP 5: Convert notification.user_type to ENUM ===
ALTER TABLE public.notification 
ALTER COLUMN user_type TYPE user_type_enum 
USING user_type::user_type_enum;

-- === STEP 6: Convert resource_locks.user_type to ENUM ===
ALTER TABLE public.resource_locks 
ALTER COLUMN user_type TYPE user_type_enum 
USING user_type::user_type_enum;

-- === STEP 7: Add new columns to job_cart ===
ALTER TABLE public.job_cart 
ADD COLUMN IF NOT EXISTS accepted_quotation_id uuid,
ADD COLUMN IF NOT EXISTS job_cart_min_price numeric,
ADD COLUMN IF NOT EXISTS job_cart_max_price numeric;

-- === STEP 8: Add foreign key for accepted_quotation_id ===
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'job_cart_accepted_quotation_fkey'
    AND table_name = 'job_cart'
  ) THEN
    ALTER TABLE public.job_cart
    ADD CONSTRAINT job_cart_accepted_quotation_fkey
    FOREIGN KEY (accepted_quotation_id)
    REFERENCES public.quotation(quotation_id);
  END IF;
END$$;

-- === STEP 9: Add quotation_id to booking table ===
ALTER TABLE public.booking 
ADD COLUMN IF NOT EXISTS quotation_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'booking_quotation_fkey'
    AND table_name = 'booking'
  ) THEN
    ALTER TABLE public.booking
    ADD CONSTRAINT booking_quotation_fkey
    FOREIGN KEY (quotation_id) 
    REFERENCES public.quotation(quotation_id);
  END IF;
END$$;

-- === STEP 10: Create quotation_history table ===
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

-- === STEP 11: Add unique constraint for one accepted quotation per job cart ===
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'uq_one_accepted_per_job_cart'
  ) THEN
    CREATE UNIQUE INDEX uq_one_accepted_per_job_cart
    ON public.quotation (job_cart_id)
    WHERE quotation_status = 'accepted';
  END IF;
END$$;

-- === STEP 12: Create performance indexes ===
CREATE INDEX IF NOT EXISTS idx_jobcart_client ON public.job_cart (client_id);
CREATE INDEX IF NOT EXISTS idx_jobcart_event ON public.job_cart (event_id);
CREATE INDEX IF NOT EXISTS idx_quotation_jobcart ON public.quotation (job_cart_id);
CREATE INDEX IF NOT EXISTS idx_quotation_provider ON public.quotation (service_provider_id);
CREATE INDEX IF NOT EXISTS idx_booking_client ON public.booking (client_id);
CREATE INDEX IF NOT EXISTS idx_booking_event ON public.booking (event_id);
CREATE INDEX IF NOT EXISTS idx_quotation_history_quotation ON public.quotation_history (quotation_id);

-- === STEP 13: Create trigger functions ===

-- Function: Handle quotation acceptance
CREATE OR REPLACE FUNCTION public.fn_handle_quotation_accepted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  existing_booking uuid;
BEGIN
  IF (TG_OP = 'UPDATE') 
     AND NEW.quotation_status = 'accepted' 
     AND OLD.quotation_status IS DISTINCT FROM 'accepted' THEN

    -- Update job_cart with accepted quotation
    UPDATE public.job_cart
    SET accepted_quotation_id = NEW.quotation_id,
        job_cart_status = 'quotation_accepted'
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

-- Function: Handle new quotation creation
CREATE OR REPLACE FUNCTION public.fn_on_new_quotation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update job cart status when first quotation is submitted
  UPDATE public.job_cart
  SET job_cart_status = 'quotations_in_progress'
  WHERE job_cart_id = NEW.job_cart_id
  AND job_cart_status = 'pending';
  
  RETURN NEW;
END;
$$;

-- === STEP 14: Create triggers ===
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

-- === STEP 15: Set up Row Level Security for quotation_history ===
ALTER TABLE public.quotation_history ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Users can view quotation history for their quotations'
  ) THEN
    CREATE POLICY "Users can view quotation history for their quotations" ON public.quotation_history
    FOR SELECT USING (
      quotation_id IN (
        SELECT quotation_id FROM public.quotation q
        JOIN public.job_cart jc ON q.job_cart_id = jc.job_cart_id
        WHERE jc.client_id = auth.uid()::uuid
        OR q.service_provider_id = auth.uid()::uuid
      )
    );
  END IF;
END$$;

-- === STEP 16: Grant permissions ===
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.quotation_history TO authenticated;
GRANT USAGE ON TYPE job_cart_status_enum TO authenticated;
GRANT USAGE ON TYPE quotation_status_enum TO authenticated;
GRANT USAGE ON TYPE notification_type_enum TO authenticated;
GRANT USAGE ON TYPE user_type_enum TO authenticated;

-- === MIGRATION COMPLETE ===







