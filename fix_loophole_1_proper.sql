-- === FIX LOOPHOLE 1: Add Service Provider Validation (PROPER WAY) ===
-- Use a trigger function instead of CHECK constraint for complex validation

-- Create function to validate service provider matches job cart service
CREATE OR REPLACE FUNCTION validate_quotation_service_match()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the service provider's service matches the job cart's service
    IF NOT EXISTS (
        SELECT 1 FROM public.job_cart jc
        JOIN public.service_provider sp ON sp.service_provider_id = NEW.service_provider_id
        WHERE jc.job_cart_id = NEW.job_cart_id
        AND jc.service_id = sp.service_id
    ) THEN
        RAISE EXCEPTION 'Service provider cannot quote for this job cart - service type mismatch';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to enforce the validation
DROP TRIGGER IF EXISTS trg_validate_quotation_service ON public.quotation;
CREATE TRIGGER trg_validate_quotation_service
    BEFORE INSERT OR UPDATE ON public.quotation
    FOR EACH ROW
    EXECUTE FUNCTION validate_quotation_service_match();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_job_cart_service_id ON public.job_cart (service_id);
CREATE INDEX IF NOT EXISTS idx_service_provider_service_id ON public.service_provider (service_id);


