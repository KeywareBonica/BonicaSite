-- === COMPLETE SCHEMA MIGRATION ===
-- This adds ALL the new columns and features you requested
-- Based on your original comprehensive schema

-- === STEP 1: Add new columns to existing tables ===

-- Add new columns to job_cart table
ALTER TABLE public.job_cart 
ADD COLUMN IF NOT EXISTS job_cart_item text,
ADD COLUMN IF NOT EXISTS job_cart_details text,
ADD COLUMN IF NOT EXISTS job_cart_created_date date DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS job_cart_created_time time DEFAULT CURRENT_TIME,
ADD COLUMN IF NOT EXISTS job_cart_status text DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS accepted_quotation_id uuid,
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

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

-- Add new columns to quotation table
ALTER TABLE public.quotation 
ADD COLUMN IF NOT EXISTS quotation_details text,
ADD COLUMN IF NOT EXISTS quotation_file_path text,
ADD COLUMN IF NOT EXISTS quotation_file_name text,
ADD COLUMN IF NOT EXISTS quotation_submission_date date DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS quotation_submission_time time DEFAULT CURRENT_TIME,
ADD COLUMN IF NOT EXISTS quotation_status text DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

-- Add new columns to booking table
ALTER TABLE public.booking 
ADD COLUMN IF NOT EXISTS booking_special_requests text,
ADD COLUMN IF NOT EXISTS booking_min_price numeric,
ADD COLUMN IF NOT EXISTS booking_max_price numeric,
ADD COLUMN IF NOT EXISTS booking_location text,
ADD COLUMN IF NOT EXISTS payment_status text,
ADD COLUMN IF NOT EXISTS booking_total_price numeric,
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

-- Add new columns to notification table
ALTER TABLE public.notification 
ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS read_at timestamp,
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

-- Add new columns to service_provider table
ALTER TABLE public.service_provider 
ADD COLUMN IF NOT EXISTS service_provider_location text,
ADD COLUMN IF NOT EXISTS service_provider_operating_days text[],
ADD COLUMN IF NOT EXISTS service_provider_base_rate numeric,
ADD COLUMN IF NOT EXISTS service_provider_overtime_rate numeric,
ADD COLUMN IF NOT EXISTS service_provider_caption text,
ADD COLUMN IF NOT EXISTS service_provider_rating numeric DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS service_provider_description text,
ADD COLUMN IF NOT EXISTS service_provider_service_type text,
ADD COLUMN IF NOT EXISTS service_provider_verification boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS service_provider_operating_times jsonb,
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

-- Add new columns to client table
ALTER TABLE public.client 
ADD COLUMN IF NOT EXISTS client_city text,
ADD COLUMN IF NOT EXISTS client_town text,
ADD COLUMN IF NOT EXISTS client_street_name text,
ADD COLUMN IF NOT EXISTS client_house_number text,
ADD COLUMN IF NOT EXISTS client_postal_code text,
ADD COLUMN IF NOT EXISTS client_preferred_notification text,
ADD COLUMN IF NOT EXISTS client_province text,
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

-- Add new columns to event table
ALTER TABLE public.event 
ADD COLUMN IF NOT EXISTS event_end_time time,
ADD COLUMN IF NOT EXISTS event_location text,
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

-- Add new columns to event_service table
ALTER TABLE public.event_service 
ADD COLUMN IF NOT EXISTS event_service_notes text,
ADD COLUMN IF NOT EXISTS event_service_status text DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

-- === STEP 2: Create new tables ===

-- Create review table
CREATE TABLE IF NOT EXISTS public.review (
    review_id uuid NOT NULL DEFAULT gen_random_uuid(),
    booking_id uuid NOT NULL,
    rating numeric NOT NULL,
    comment text,
    created_at timestamp DEFAULT now(),
    CONSTRAINT review_pkey PRIMARY KEY (review_id),
    CONSTRAINT review_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.booking(booking_id)
);

-- Create resource_locks table
CREATE TABLE IF NOT EXISTS public.resource_locks (
    lock_id uuid NOT NULL DEFAULT gen_random_uuid(),
    resource_type text NOT NULL,
    resource_id text NOT NULL,
    user_id uuid NOT NULL,
    user_type text NOT NULL CHECK (user_type = ANY (ARRAY['client'::text, 'service_provider'::text])),
    acquired_at timestamp DEFAULT now(),
    expires_at timestamp NOT NULL,
    created_at timestamp DEFAULT now(),
    CONSTRAINT resource_locks_pkey PRIMARY KEY (lock_id)
);

-- === STEP 3: Create indexes for performance ===
CREATE INDEX IF NOT EXISTS idx_job_cart_status ON public.job_cart(job_cart_status);
CREATE INDEX IF NOT EXISTS idx_job_cart_client_id ON public.job_cart(client_id);
CREATE INDEX IF NOT EXISTS idx_job_cart_service_id ON public.job_cart(service_id);
CREATE INDEX IF NOT EXISTS idx_quotation_status ON public.quotation(quotation_status);
CREATE INDEX IF NOT EXISTS idx_quotation_service_provider_id ON public.quotation(service_provider_id);
CREATE INDEX IF NOT EXISTS idx_quotation_job_cart_id ON public.quotation(job_cart_id);
CREATE INDEX IF NOT EXISTS idx_notification_user_id ON public.notification(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_is_read ON public.notification(is_read);

-- === STEP 4: Create the quotation_with_files view ===
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

-- === COMPLETE! ===
-- Your database now has all the new columns and features







