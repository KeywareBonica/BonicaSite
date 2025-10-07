-- Create real test data for presentation tomorrow
-- This will insert actual job carts and quotations into the database

-- Step 1: Insert real job carts for the client
INSERT INTO job_cart (
    job_cart_id,
    client_id,
    service_id,
    event_id,
    job_cart_status,
    job_cart_created_date,
    job_cart_created_time
) VALUES 
-- Photography job cart
(
    gen_random_uuid(),
    'ff33d598-3d94-4fc1-9287-8760290651d3', -- Your client ID
    (SELECT service_id FROM service WHERE service_name = 'Photography' LIMIT 1),
    (SELECT event_id FROM event ORDER BY created_at DESC LIMIT 1), -- Use latest event
    'accepted',
    CURRENT_DATE,
    CURRENT_TIME
),
-- Makeup Artist job cart  
(
    gen_random_uuid(),
    'ff33d598-3d94-4fc1-9287-8760290651d3', -- Your client ID
    (SELECT service_id FROM service WHERE service_name = 'Makeup Artist' LIMIT 1),
    (SELECT event_id FROM event ORDER BY created_at DESC LIMIT 1), -- Use latest event
    'accepted',
    CURRENT_DATE,
    CURRENT_TIME
)
ON CONFLICT DO NOTHING;

-- Step 2: Insert real quotations for these job carts
-- First, let's get the job cart IDs we just created and find service providers
WITH job_carts AS (
    SELECT jc.job_cart_id, jc.service_id, s.service_name
    FROM job_cart jc
    JOIN service s ON jc.service_id = s.service_id
    WHERE jc.client_id = 'ff33d598-3d94-4fc1-9287-8760290651d3'
    AND jc.job_cart_status = 'accepted'
),
service_providers AS (
    SELECT service_provider_id, service_provider_name
    FROM service_provider 
    WHERE service_provider_verification = true
    OR service_provider_verification IS NULL  -- Include unverified ones too
    ORDER BY service_provider_id
    LIMIT 5 -- Get first 5 service providers
)
INSERT INTO quotation (
    quotation_id,
    service_provider_id,
    job_cart_id,
    quotation_price,
    quotation_details,
    quotation_file_path,
    quotation_file_name,
    quotation_submission_date,
    quotation_submission_time,
    quotation_status
)
SELECT 
    gen_random_uuid(),
    sp.service_provider_id,
    jc.job_cart_id,
    CASE 
        WHEN jc.service_name = 'Photography' THEN 8500.00 + ((RANDOM() * 2000) - 1000) -- R7,500-R9,500
        WHEN jc.service_name = 'Makeup Artist' THEN 2000.00 + ((RANDOM() * 800) - 400) -- R1,600-R2,400
        ELSE 5000.00
    END as quotation_price,
    'Professional ' || jc.service_name || ' services for your special event. Includes full coverage, setup, and professional delivery.',
    'sample-quotations/' || LOWER(REPLACE(jc.service_name, ' ', '_')) || '_quote.pdf',
    jc.service_name || ' Quote.pdf',
    CURRENT_DATE - (RANDOM() * 7)::int, -- Submitted in last week
    CURRENT_TIME,
    'confirmed'
FROM job_carts jc
CROSS JOIN service_providers sp
WHERE jc.service_name IN ('Photography', 'Makeup Artist')
ON CONFLICT DO NOTHING;

-- Step 3: Verify the data was created
SELECT 
    'Job Carts Created' as data_type,
    COUNT(*) as count
FROM job_cart 
WHERE client_id = 'ff33d598-3d94-4fc1-9287-8760290651d3'
AND job_cart_status = 'accepted'

UNION ALL

SELECT 
    'Quotations Created' as data_type,
    COUNT(*) as count
FROM quotation q
JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
WHERE jc.client_id = 'ff33d598-3d94-4fc1-9287-8760290651d3'
AND q.quotation_status = 'confirmed';

-- Step 4: Show sample of created data
SELECT 
    jc.job_cart_id,
    s.service_name,
    jc.job_cart_status,
    q.quotation_id,
    q.quotation_price,
    q.quotation_status,
    sp.service_provider_name
FROM job_cart jc
JOIN service s ON jc.service_id = s.service_id
LEFT JOIN quotation q ON jc.job_cart_id = q.job_cart_id
LEFT JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
WHERE jc.client_id = 'ff33d598-3d94-4fc1-9287-8760290651d3'
ORDER BY jc.created_at DESC;
