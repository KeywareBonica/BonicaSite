-- Setup Quotation File Storage System
-- This script ensures proper file storage for quotation documents

-- 1. Create quotations storage bucket (if not exists)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'quotations',
    'quotations',
    false, -- Private bucket for security
    52428800, -- 50MB limit
    ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'image/jpeg', 'image/png', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Create RLS policies for quotations bucket
-- Policy for service providers to upload quotations
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

-- Policy for service providers to view their own quotations
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

-- Policy for clients to view quotations for their bookings
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

-- 3. Create function to generate public URLs for quotation files
CREATE OR REPLACE FUNCTION get_quotation_file_url(quotation_id_param uuid)
RETURNS text AS $$
DECLARE
    file_path text;
    signed_url text;
BEGIN
    -- Get the file path from the quotation
    SELECT quotation_file_path INTO file_path
    FROM quotation
    WHERE quotation_id = quotation_id_param;
    
    IF file_path IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Generate signed URL (this would need to be done in the application layer)
    -- For now, return the file path that can be used with Supabase client
    RETURN file_path;
END;
$$ LANGUAGE plpgsql;

-- 4. Create view for quotations with file URLs
CREATE OR REPLACE VIEW quotation_with_files AS
SELECT 
    q.quotation_id,
    q.service_provider_id,
    q.quotation_price,
    q.quotation_details,
    q.quotation_file_path,
    q.quotation_file_name,
    q.quotation_submission_date,
    q.quotation_submission_time,
    q.quotation_status,
    q.created_at,
    q.event_id,
    q.booking_id,
    sp.service_provider_name,
    sp.service_provider_surname,
    sp.service_provider_email,
    jc.service_id as job_service_id,
    jc.client_id as job_client_id,
    s.service_name,
    s.service_type,
    e.event_type as event_name,
    e.event_date,
    e.event_location,
    c.client_name,
    c.client_surname,
    c.client_email as client_email,
    CASE 
        WHEN q.quotation_file_path IS NOT NULL THEN 
            'https://spudtrptbyvwyhvistdf.supabase.co/storage/v1/object/sign/quotations/' || q.quotation_file_path
        ELSE NULL 
    END as quotation_file_url
FROM quotation q
JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
JOIN service s ON jc.service_id = s.service_id
JOIN event e ON jc.event_id = e.event_id
JOIN client c ON jc.client_id = c.client_id;

-- 5. Add function to validate quotation file uploads
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
    
    -- Check if the file path is properly formatted
    IF NEW.quotation_file_path IS NOT NULL AND NEW.quotation_file_path !~ '^[a-f0-9-]+/[0-9]+-.*$' THEN
        RAISE EXCEPTION 'Invalid file path format';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Create trigger to validate quotation uploads
DROP TRIGGER IF EXISTS trigger_validate_quotation_file ON quotation;
CREATE TRIGGER trigger_validate_quotation_file
    BEFORE INSERT OR UPDATE ON quotation
    FOR EACH ROW
    EXECUTE FUNCTION validate_quotation_file_upload();

-- 7. Create function to clean up orphaned files
CREATE OR REPLACE FUNCTION cleanup_orphaned_quotation_files()
RETURNS void AS $$
DECLARE
    file_record RECORD;
BEGIN
    -- Find files in storage that don't have corresponding quotations
    FOR file_record IN 
        SELECT name FROM storage.objects 
        WHERE bucket_id = 'quotations'
        AND name NOT IN (
            SELECT quotation_file_path 
            FROM quotation 
            WHERE quotation_file_path IS NOT NULL
        )
    LOOP
        -- Delete orphaned file (this would need to be done via API)
        RAISE NOTICE 'Orphaned file found: %', file_record.name;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 8. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_quotation_file_path ON quotation(quotation_file_path) WHERE quotation_file_path IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_quotation_service_provider_status ON quotation(service_provider_id, quotation_status);

-- 9. Grant necessary permissions
GRANT SELECT ON quotation_with_files TO authenticated;
GRANT EXECUTE ON FUNCTION get_quotation_file_url(uuid) TO authenticated;

-- 10. Add comments for documentation
COMMENT ON VIEW quotation_with_files IS 'View of quotations with file URLs and related information';
COMMENT ON FUNCTION get_quotation_file_url(uuid) IS 'Returns the file path for generating signed URLs';
COMMENT ON FUNCTION cleanup_orphaned_quotation_files() IS 'Identifies orphaned files in quotations storage bucket';

SELECT 'Quotation storage system setup completed successfully!' as status;
