-- === SUPABASE MIGRATION - WORKING WITH YOUR CURRENT SCHEMA ===
-- This script works with your existing schema structure

-- === STEP 1: Create enums ===
DO $$
BEGIN
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

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'quotation_status_enum') THEN
    CREATE TYPE quotation_status_enum AS ENUM (
      'pending',
      'accepted',
      'rejected',
      'withdrawn'
    );
  END IF;
END$$;

-- === STEP 2: Add new columns to existing tables ===
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS accepted_quotation_id uuid;
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS job_cart_min_price numeric;
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS job_cart_max_price numeric;

ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS quotation_id uuid;

-- === STEP 3: Create quotation_history table ===
CREATE TABLE IF NOT EXISTS public.quotation_history (
  history_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quotation_id uuid NOT NULL,
  action text NOT NULL,
  performed_by uuid,
  performed_by_type text CHECK (performed_by_type = ANY (ARRAY['client'::text, 'service_provider'::text])),
  performed_at timestamp without time zone DEFAULT now(),
  details text,
  CONSTRAINT quotation_history_quotation_fkey FOREIGN KEY (quotation_id) REFERENCES public.quotation(quotation_id)
);

-- === STEP 4: Add foreign key constraints ===
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

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'booking_quotation_fkey'
    AND table_name = 'booking'
  ) THEN
    ALTER TABLE public.booking
    ADD CONSTRAINT booking_quotation_fkey
    FOREIGN KEY (quotation_id) REFERENCES public.quotation(quotation_id);
  END IF;
END$$;

-- === STEP 5: Add business rule constraint (works with text status) ===
CREATE UNIQUE INDEX IF NOT EXISTS uq_one_accepted_per_job_cart
  ON public.quotation (job_cart_id)
  WHERE quotation_status = 'accepted';

-- === STEP 6: Add helper indexes for performance ===
CREATE INDEX IF NOT EXISTS idx_jobcart_client ON public.job_cart (client_id);
CREATE INDEX IF NOT EXISTS idx_jobcart_event ON public.job_cart (event_id);
CREATE INDEX IF NOT EXISTS idx_quotation_jobcart ON public.quotation (job_cart_id);
CREATE INDEX IF NOT EXISTS idx_quotation_provider ON public.quotation (service_provider_id);
CREATE INDEX IF NOT EXISTS idx_booking_client ON public.booking (client_id);
CREATE INDEX IF NOT EXISTS idx_booking_event ON public.booking (event_id);

-- === STEP 7: Create trigger functions ===
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

    -- Prevent multiple accepted quotations for the same job_cart
    PERFORM 1 FROM public.quotation
    WHERE job_cart_id = NEW.job_cart_id 
      AND quotation_status = 'accepted' 
      AND quotation_id <> NEW.quotation_id;
    IF FOUND THEN
      RAISE EXCEPTION 'Another quotation is already accepted for job_cart %', NEW.job_cart_id;
    END IF;

    -- Update job_cart
    UPDATE public.job_cart
    SET accepted_quotation_id = NEW.quotation_id,
        job_cart_status = 'quotation_accepted'
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
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.job_cart
  SET job_cart_status = CASE
    WHEN job_cart_status = 'pending' THEN 'quotations_in_progress'
    WHEN job_cart_status = 'quotations_in_progress' THEN job_cart_status
    ELSE job_cart_status
  END
  WHERE job_cart_id = NEW.job_cart_id;
  RETURN NEW;
END;
$$;

-- === STEP 8: Create triggers ===
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

-- === STEP 9: Enable RLS and add policies ===
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

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.quotation_history TO authenticated;







