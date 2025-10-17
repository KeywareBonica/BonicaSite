-- === SUPABASE WORKING SOLUTION ===
-- This adds the quotation-to-job-cart linking you need
-- NO ENUM CONVERSION - keeps your existing text columns
-- Run this in Supabase SQL Editor

-- === STEP 1: Add new columns ===
ALTER TABLE public.job_cart 
ADD COLUMN IF NOT EXISTS accepted_quotation_id uuid,
ADD COLUMN IF NOT EXISTS job_cart_min_price numeric,
ADD COLUMN IF NOT EXISTS job_cart_max_price numeric;

ALTER TABLE public.booking 
ADD COLUMN IF NOT EXISTS quotation_id uuid;

-- === STEP 2: Add foreign keys ===
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

-- === STEP 3: Business rule - only one accepted quotation per job cart ===
CREATE UNIQUE INDEX IF NOT EXISTS uq_one_accepted_per_job_cart
ON public.quotation (job_cart_id)
WHERE quotation_status = 'accepted';

-- === STEP 4: Performance indexes ===
CREATE INDEX IF NOT EXISTS idx_jobcart_client ON public.job_cart (client_id);
CREATE INDEX IF NOT EXISTS idx_quotation_jobcart ON public.quotation (job_cart_id);
CREATE INDEX IF NOT EXISTS idx_booking_client ON public.booking (client_id);

-- === STEP 5: Trigger function for automatic booking creation ===
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

    -- Update job_cart
    UPDATE public.job_cart
    SET accepted_quotation_id = NEW.quotation_id,
        job_cart_status = 'accepted'
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
        client_id,
        event_id,
        created_at,
        booking_total_price,
        quotation_id
      )
      SELECT
        e.event_date,
        'pending',
        jc.client_id,
        COALESCE(NEW.event_id, jc.event_id),
        now(),
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

-- === STEP 6: Create trigger ===
DROP TRIGGER IF EXISTS trg_quotation_after_update ON public.quotation;
CREATE TRIGGER trg_quotation_after_update
AFTER UPDATE ON public.quotation
FOR EACH ROW
EXECUTE FUNCTION public.fn_handle_quotation_accepted();

-- === DONE! ===
-- Your system now has:
-- ✅ Quotations properly linked to job carts
-- ✅ Only one accepted quotation per job cart (enforced)
-- ✅ Automatic booking creation when quotation is accepted
-- ✅ No enum conversion issues
-- ✅ Works with your existing data







