-- === FIX LOOPHOLE 1: Add Service Provider Validation ===
-- Ensures service providers can only quote for job carts matching their service type

-- Add check constraint to quotation table
ALTER TABLE public.quotation 
ADD CONSTRAINT quotation_service_provider_service_match 
CHECK (
  EXISTS (
    SELECT 1 FROM public.job_cart jc
    JOIN public.service_provider sp ON sp.service_id = jc.service_id
    WHERE jc.job_cart_id = quotation.job_cart_id
    AND sp.service_provider_id = quotation.service_provider_id
  )
);

-- Add index for better performance on this check
CREATE INDEX IF NOT EXISTS idx_job_cart_service_id ON public.job_cart (service_id);
CREATE INDEX IF NOT EXISTS idx_service_provider_service_id ON public.service_provider (service_id);







