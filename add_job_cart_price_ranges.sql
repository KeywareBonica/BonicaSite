-- === ADD JOB CART PRICE RANGES ===
-- Add min/max price columns back to job_cart for client-specific service budgets

-- Add price range columns to job_cart table
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS job_cart_min_price numeric;
ALTER TABLE public.job_cart ADD COLUMN IF NOT EXISTS job_cart_max_price numeric;







