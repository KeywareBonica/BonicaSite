-- === ADD NEW COLUMNS TO EXISTING TABLES ONLY ===
-- This adds the new columns you requested to your existing tables

-- === Add new columns to job_cart table ===
ALTER TABLE public.job_cart 
ADD COLUMN IF NOT EXISTS job_cart_item text,
ADD COLUMN IF NOT EXISTS job_cart_details text,
ADD COLUMN IF NOT EXISTS job_cart_created_date date DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS job_cart_created_time time DEFAULT CURRENT_TIME,
ADD COLUMN IF NOT EXISTS accepted_quotation_id uuid,
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

-- === Add new columns to quotation table ===
ALTER TABLE public.quotation 
ADD COLUMN IF NOT EXISTS quotation_details text,
ADD COLUMN IF NOT EXISTS quotation_file_path text,
ADD COLUMN IF NOT EXISTS quotation_file_name text,
ADD COLUMN IF NOT EXISTS quotation_submission_date date DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS quotation_submission_time time DEFAULT CURRENT_TIME,
ADD COLUMN IF NOT EXISTS quotation_status text DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

-- === Add new columns to booking table ===
ALTER TABLE public.booking 
ADD COLUMN IF NOT EXISTS booking_special_requests text,
ADD COLUMN IF NOT EXISTS booking_min_price numeric,
ADD COLUMN IF NOT EXISTS booking_max_price numeric,
ADD COLUMN IF NOT EXISTS booking_location text,
ADD COLUMN IF NOT EXISTS payment_status text,
ADD COLUMN IF NOT EXISTS booking_total_price numeric,
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

-- === Add new columns to notification table ===
ALTER TABLE public.notification 
ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS read_at timestamp,
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

-- === Add new columns to service_provider table ===
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

-- === Add new columns to client table ===
ALTER TABLE public.client 
ADD COLUMN IF NOT EXISTS client_city text,
ADD COLUMN IF NOT EXISTS client_town text,
ADD COLUMN IF NOT EXISTS client_street_name text,
ADD COLUMN IF NOT EXISTS client_house_number text,
ADD COLUMN IF NOT EXISTS client_postal_code text,
ADD COLUMN IF NOT EXISTS client_preferred_notification text,
ADD COLUMN IF NOT EXISTS client_province text,
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

-- === Add new columns to event table ===
ALTER TABLE public.event 
ADD COLUMN IF NOT EXISTS event_end_time time,
ADD COLUMN IF NOT EXISTS event_location text,
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

-- === Add new columns to event_service table ===
ALTER TABLE public.event_service 
ADD COLUMN IF NOT EXISTS event_service_notes text,
ADD COLUMN IF NOT EXISTS event_service_status text DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

-- === COMPLETE! ===
-- All new columns have been added to your existing tables


