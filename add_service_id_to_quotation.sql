-- Add service_id column to quotation table and link quotations to services
-- This will make it much easier to filter quotations by service type

-- Step 1: Add service_id column to quotation table
ALTER TABLE quotation 
ADD COLUMN IF NOT EXISTS service_id uuid REFERENCES service(service_id) ON DELETE CASCADE;

-- Step 2: Create index for better performance
CREATE INDEX IF NOT EXISTS idx_quotation_service_id ON quotation(service_id);

-- Step 3: Update existing quotations to link them to services
-- This will link quotations to services based on the service provider's service type
UPDATE quotation 
SET service_id = (
    SELECT s.service_id 
    FROM service s
    JOIN service_provider sp ON s.service_name = sp.service_provider_service_type
    WHERE sp.service_provider_id = quotation.service_provider_id
    LIMIT 1
)
WHERE service_id IS NULL;

-- Step 4: For any quotations that couldn't be matched, assign them to common services
-- Based on service provider service type
UPDATE quotation 
SET service_id = (
    CASE 
        WHEN sp.service_provider_service_type ILIKE '%photography%' OR sp.service_provider_service_type ILIKE '%photo%' 
            THEN (SELECT service_id FROM service WHERE service_name = 'Photography' LIMIT 1)
        WHEN sp.service_provider_service_type ILIKE '%video%' 
            THEN (SELECT service_id FROM service WHERE service_name = 'Videography' LIMIT 1)
        WHEN sp.service_provider_service_type ILIKE '%dj%' OR sp.service_provider_service_type ILIKE '%music%' 
            THEN (SELECT service_id FROM service WHERE service_name = 'DJ Services' LIMIT 1)
        WHEN sp.service_provider_service_type ILIKE '%catering%' OR sp.service_provider_service_type ILIKE '%food%' 
            THEN (SELECT service_id FROM service WHERE service_name = 'Catering' LIMIT 1)
        WHEN sp.service_provider_service_type ILIKE '%makeup%' 
            THEN (SELECT service_id FROM service WHERE service_name = 'Makeup Artist' LIMIT 1)
        WHEN sp.service_provider_service_type ILIKE '%decoration%' OR sp.service_provider_service_type ILIKE '%decor%' 
            THEN (SELECT service_id FROM service WHERE service_name = 'Decoration' LIMIT 1)
        WHEN sp.service_provider_service_type ILIKE '%venue%' 
            THEN (SELECT service_id FROM service WHERE service_name = 'Venue' LIMIT 1)
        WHEN sp.service_provider_service_type ILIKE '%florist%' OR sp.service_provider_service_type ILIKE '%flower%' 
            THEN (SELECT service_id FROM service WHERE service_name = 'Florist' LIMIT 1)
        WHEN sp.service_provider_service_type ILIKE '%mc%' OR sp.service_provider_service_type ILIKE '%master%' 
            THEN (SELECT service_id FROM service WHERE service_name = 'MC' LIMIT 1)
        WHEN sp.service_provider_service_type ILIKE '%security%' 
            THEN (SELECT service_id FROM service WHERE service_name = 'Security' LIMIT 1)
        WHEN sp.service_provider_service_type ILIKE '%sound%' 
            THEN (SELECT service_id FROM service WHERE service_name = 'Sound System' LIMIT 1)
        WHEN sp.service_provider_service_type ILIKE '%stage%' 
            THEN (SELECT service_id FROM service WHERE service_name = 'Stage Design' LIMIT 1)
        WHEN sp.service_provider_service_type ILIKE '%photo.*booth%' 
            THEN (SELECT service_id FROM service WHERE service_name = 'Photo Booth' LIMIT 1)
        ELSE (SELECT service_id FROM service WHERE service_name = 'Photography' LIMIT 1) -- Default fallback
    END
)
FROM service_provider sp
WHERE quotation.service_id IS NULL 
AND sp.service_provider_id = quotation.service_provider_id;

-- Step 5: Verify the updates
SELECT 
    q.quotation_id,
    q.quotation_price,
    sp.service_provider_name,
    sp.service_provider_service_type,
    s.service_name,
    s.service_id
FROM quotation q
JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
LEFT JOIN service s ON q.service_id = s.service_id
ORDER BY q.created_at DESC
LIMIT 10;

-- Step 6: Show any quotations that still don't have service_id linked
SELECT 
    q.quotation_id,
    q.quotation_price,
    sp.service_provider_name,
    sp.service_provider_service_type,
    q.service_id
FROM quotation q
JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
WHERE q.service_id IS NULL;

-- Step 7: Update the quotation_with_files view to include the new service_id column
CREATE OR REPLACE VIEW quotation_with_files AS
SELECT 
    q.quotation_id,
    q.service_provider_id,
    q.service_id, -- Add the new service_id column from quotation table
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
    jc.service_id as job_service_id, -- Keep this for backward compatibility
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
LEFT JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
LEFT JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
LEFT JOIN service s ON q.service_id = s.service_id -- Use the new direct service_id relationship
LEFT JOIN event e ON jc.event_id = e.event_id
LEFT JOIN client c ON jc.client_id = c.client_id;

-- Step 8: Add comment for documentation
COMMENT ON COLUMN quotation.service_id IS 'Direct reference to the service this quotation is for. Makes filtering quotations by service type much simpler.';
COMMENT ON VIEW quotation_with_files IS 'Updated view that includes the new service_id column from quotation table for direct service filtering.';
