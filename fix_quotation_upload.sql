-- Fix quotation upload issue - Remove verification requirement
-- This script fixes the "Only verified service providers can upload quotations" error

-- 1. Update the validation function to allow unverified service providers
CREATE OR REPLACE FUNCTION validate_quotation_file_upload()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the service provider exists (allow unverified for now)
    IF NOT EXISTS (
        SELECT 1 FROM service_provider 
        WHERE service_provider_id = NEW.service_provider_id
    ) THEN
        RAISE EXCEPTION 'Service provider not found';
    END IF;
    
    -- Validate file path format (relaxed for now)
    IF NEW.quotation_file_path IS NOT NULL THEN
        -- Allow various file path formats
        IF NEW.quotation_file_path !~ '^[a-zA-Z0-9_\-/\.]+$' THEN
            RAISE EXCEPTION 'Invalid file path format';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Alternative: Drop the trigger completely if you want to allow all uploads
-- Uncomment the lines below if you want to remove the validation entirely:

-- DROP TRIGGER IF EXISTS validate_quotation_upload_trigger ON quotation;
-- 
-- CREATE TRIGGER validate_quotation_upload_trigger
--     BEFORE INSERT OR UPDATE ON quotation
--     FOR EACH ROW
--     WHEN (NEW.quotation_file_path IS NOT NULL)
--     EXECUTE FUNCTION validate_quotation_file_upload();

-- 3. Update existing service providers to be verified (optional)
-- Uncomment if you want to mark all existing service providers as verified:
-- UPDATE service_provider SET service_provider_verification = true WHERE service_provider_verification IS NULL;

SELECT 'Quotation upload fix applied successfully!' as status;
