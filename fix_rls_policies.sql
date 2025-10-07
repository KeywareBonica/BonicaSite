-- Fix RLS policies for quotation uploads
-- This script handles the "policy already exists" error

-- 1. Drop existing policies if they exist
DROP POLICY IF EXISTS "Service providers can upload quotations" ON storage.objects;
DROP POLICY IF EXISTS "Service providers can view their quotations" ON storage.objects;
DROP POLICY IF EXISTS "Clients can view quotations for their bookings" ON storage.objects;

-- 2. Create updated policies (without verification requirement)
CREATE POLICY "Service providers can upload quotations"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'quotations' AND
    auth.uid()::text IN (
        SELECT service_provider_id::text 
        FROM service_provider 
        WHERE service_provider_email = auth.jwt()->>'email'
    )
);

CREATE POLICY "Service providers can view their quotations"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'quotations' AND
    auth.uid()::text IN (
        SELECT service_provider_id::text 
        FROM service_provider 
        WHERE service_provider_email = auth.jwt()->>'email'
    )
);

CREATE POLICY "Clients can view quotations for their bookings"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'quotations' AND
    name IN (
        SELECT quotation_file_path
        FROM quotation q
        JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
        JOIN client c ON jc.client_id = c.client_id
        WHERE c.client_email = auth.jwt()->>'email'
    )
);

-- 3. Also update the validation function
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
    
    -- Validate file path format (relaxed)
    IF NEW.quotation_file_path IS NOT NULL THEN
        IF NEW.quotation_file_path !~ '^[a-zA-Z0-9_\-/\.]+$' THEN
            RAISE EXCEPTION 'Invalid file path format';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Recreate the trigger
DROP TRIGGER IF EXISTS validate_quotation_upload_trigger ON quotation;

CREATE TRIGGER validate_quotation_upload_trigger
    BEFORE INSERT OR UPDATE ON quotation
    FOR EACH ROW
    WHEN (NEW.quotation_file_path IS NOT NULL)
    EXECUTE FUNCTION validate_quotation_file_upload();

SELECT 'RLS policies and validation function updated successfully!' as status;
