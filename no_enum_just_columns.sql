-- === NO ENUMS - JUST ADD COLUMNS ===
-- This adds all the new columns you need WITHOUT any enum conversion
-- GUARANTEED NO ENUM ERRORS

-- === Add new columns to existing tables ===
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

-- === Add foreign key constraints ===
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'job_cart_accepted_quotation_fkey'
  ) THEN
    ALTER TABLE public.job_cart 
    ADD CONSTRAINT job_cart_accepted_quotation_fkey 
    FOREIGN KEY (accepted_quotation_id) REFERENCES public.quotation(quotation_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'booking_quotation_fkey'
  ) THEN
    ALTER TABLE public.booking 
    ADD CONSTRAINT booking_quotation_fkey 
    FOREIGN KEY (quotation_id) REFERENCES public.quotation(quotation_id);
  END IF;
END $$;

-- === Add indexes for performance ===
CREATE INDEX IF NOT EXISTS idx_jobcart_client ON public.job_cart (client_id);
CREATE INDEX IF NOT EXISTS idx_jobcart_event ON public.job_cart (event_id);
CREATE INDEX IF NOT EXISTS idx_quotation_jobcart ON public.quotation (job_cart_id);
CREATE INDEX IF NOT EXISTS idx_quotation_provider ON public.quotation (service_provider_id);
CREATE INDEX IF NOT EXISTS idx_booking_client ON public.booking (client_id);
CREATE INDEX IF NOT EXISTS idx_booking_event ON public.booking (event_id);

-- === COMPLETE! ===
-- All new columns added, NO enum conversion, NO enum errors possible







