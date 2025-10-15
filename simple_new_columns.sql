-- === ADD NEW COLUMNS ONLY - NO ENUMS ===

-- Add new columns to job_cart table
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS accepted_quotation_id uuid;
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS job_cart_min_price numeric;
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS job_cart_max_price numeric;

-- Add new columns to quotation table
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_details text;
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_file_path text;
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_file_name text;

-- Add new columns to booking table
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_special_requests text;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_min_price numeric;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_max_price numeric;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_location text;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS payment_status text;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_total_price numeric;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS quotation_id uuid;

-- Add new columns to notification table
ALTER TABLE public.notification ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false;
ALTER TABLE public.notification ADD COLUMN IF NOT EXISTS read_at timestamp;

-- Add new columns to service_provider table
ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_location text;
ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_base_rate numeric;
ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_overtime_rate numeric;
ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_rating numeric DEFAULT 0.00;
ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_verification boolean DEFAULT false;

-- Add new columns to client table
ALTER TABLE public.client ADD COLUMN IF NOT EXISTS client_city text;
ALTER TABLE public.client ADD COLUMN IF NOT EXISTS client_town text;

-- Add new columns to event table
ALTER TABLE public.event ADD COLUMN IF NOT EXISTS event_end_time time;
ALTER TABLE public.event ADD COLUMN IF NOT EXISTS event_location text;

-- Add new columns to event_service table
ALTER TABLE public.event_service ADD COLUMN IF NOT EXISTS event_service_notes text;

-- Add foreign key for accepted quotation
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

-- Add foreign key for booking quotation
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


