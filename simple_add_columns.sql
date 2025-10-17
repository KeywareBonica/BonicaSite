-- Add new columns to existing tables
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS job_cart_item text;
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS job_cart_details text;
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS accepted_quotation_id uuid;
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_details text;
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_file_path text;
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_file_name text;
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_special_requests text;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_min_price numeric;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_max_price numeric;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_location text;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS payment_status text;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS booking_total_price numeric;
ALTER TABLE public.booking ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

ALTER TABLE public.notification ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false;
ALTER TABLE public.notification ADD COLUMN IF NOT EXISTS read_at timestamp;
ALTER TABLE public.notification ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_location text;
ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_base_rate numeric;
ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_overtime_rate numeric;
ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_rating numeric DEFAULT 0.00;
ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS service_provider_verification boolean DEFAULT false;
ALTER TABLE public.service_provider ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

ALTER TABLE public.client ADD COLUMN IF NOT EXISTS client_city text;
ALTER TABLE public.client ADD COLUMN IF NOT EXISTS client_town text;
ALTER TABLE public.client ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

ALTER TABLE public.event ADD COLUMN IF NOT EXISTS event_end_time time;
ALTER TABLE public.event ADD COLUMN IF NOT EXISTS event_location text;
ALTER TABLE public.event ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();

ALTER TABLE public.event_service ADD COLUMN IF NOT EXISTS event_service_notes text;
ALTER TABLE public.event_service ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT now();







