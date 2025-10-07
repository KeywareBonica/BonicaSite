-- Update the quotation_with_files view to include the new service_id column
-- This will make the view consistent with the updated quotation table schema

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

-- Grant permissions on the updated view
GRANT SELECT ON quotation_with_files TO authenticated;

-- Add comment for documentation
COMMENT ON VIEW quotation_with_files IS 'Updated view that includes the new service_id column from quotation table for direct service filtering.';
