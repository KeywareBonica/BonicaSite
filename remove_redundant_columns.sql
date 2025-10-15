-- Remove redundant min/max price columns from job_cart
ALTER TABLE public.job_cart DROP COLUMN IF EXISTS job_cart_min_price;
ALTER TABLE public.job_cart DROP COLUMN IF EXISTS job_cart_max_price;

-- Remove redundant min/max price columns from booking (use event table instead)
ALTER TABLE public.booking DROP COLUMN IF EXISTS booking_min_price;
ALTER TABLE public.booking DROP COLUMN IF EXISTS booking_max_price;


