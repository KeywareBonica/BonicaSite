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
    SELECT service_provider_id, service_provider_name, service_provider_service_type
    FROM service_provider 
    WHERE service_provider_verification = true
    OR service_provider_verification IS NULL  -- Include unverified ones too
    ORDER BY service_provider_id
    LIMIT 20 -- Get more service providers to ensure we have enough for each service
),
-- Generate multiple quotations per service (at least 4 per service)
quotation_generator AS (
    SELECT 
        gen_random_uuid() as quotation_id,
        sp.service_provider_id,
        jc.job_cart_id,
        jc.service_id,
        CASE 
            WHEN jc.service_name = 'Photography' THEN 7500.00 + ((RANDOM() * 3000) - 1500) -- R6,000-R9,000
            WHEN jc.service_name = 'Makeup Artist' THEN 1500.00 + ((RANDOM() * 1000) - 500) -- R1,000-R2,000
            WHEN jc.service_name = 'Catering' THEN 2000.00 + ((RANDOM() * 1500) - 750) -- R1,250-R2,750
            WHEN jc.service_name = 'DJ Services' THEN 1200.00 + ((RANDOM() * 800) - 400) -- R800-R1,600
            WHEN jc.service_name = 'Decoration' THEN 1800.00 + ((RANDOM() * 1200) - 600) -- R1,200-R2,400
            WHEN jc.service_name = 'Videography' THEN 4000.00 + ((RANDOM() * 2000) - 1000) -- R3,000-R5,000
            WHEN jc.service_name = 'Venue' THEN 5000.00 + ((RANDOM() * 3000) - 1500) -- R3,500-R6,500
            WHEN jc.service_name = 'Florist' THEN 800.00 + ((RANDOM() * 600) - 300) -- R500-R1,100
            WHEN jc.service_name = 'MC' THEN 1000.00 + ((RANDOM() * 500) - 250) -- R750-R1,250
            WHEN jc.service_name = 'Security' THEN 600.00 + ((RANDOM() * 400) - 200) -- R400-R800
            WHEN jc.service_name = 'Sound System' THEN 1500.00 + ((RANDOM() * 1000) - 500) -- R1,000-R2,000
            WHEN jc.service_name = 'Stage Design' THEN 2500.00 + ((RANDOM() * 1500) - 750) -- R1,750-R3,250
            WHEN jc.service_name = 'Photo Booth' THEN 1200.00 + ((RANDOM() * 800) - 400) -- R800-R1,600
            ELSE 2000.00 + ((RANDOM() * 1000) - 500) -- Default range
        END as quotation_price,
        CASE 
            WHEN jc.service_name = 'Photography' THEN 'Professional photography coverage with ' || (4 + (RANDOM() * 4))::int || ' hours of shooting, ' || (300 + (RANDOM() * 200))::int || '+ edited photos, and online gallery delivery.'
            WHEN jc.service_name = 'Makeup Artist' THEN 'Professional makeup services for ' || (1 + (RANDOM() * 2))::int || ' people, including trial session, touch-ups, and premium cosmetics.'
            WHEN jc.service_name = 'Catering' THEN 'Delicious catering for ' || (30 + (RANDOM() * 40))::int || ' guests, including ' || (2 + (RANDOM() * 3))::int || ' course meal, beverages, and professional service staff.'
            WHEN jc.service_name = 'DJ Services' THEN 'Professional DJ services with ' || (4 + (RANDOM() * 4))::int || ' hours of music, premium sound system, lighting effects, and music library.'
            WHEN jc.service_name = 'Decoration' THEN 'Beautiful event decoration including floral arrangements, lighting, table settings, and venue transformation for ' || (50 + (RANDOM() * 50))::int || ' guests.'
            WHEN jc.service_name = 'Videography' THEN 'Professional videography with ' || (6 + (RANDOM() * 4))::int || ' hours of coverage, cinematic editing, highlight reel, and full event video.'
            WHEN jc.service_name = 'Venue' THEN 'Premium venue rental for ' || (50 + (RANDOM() * 100))::int || ' guests, including setup, cleanup, and basic amenities.'
            WHEN jc.service_name = 'Florist' THEN 'Beautiful floral arrangements including bridal bouquet, centerpieces, ceremony flowers, and venue decorations.'
            WHEN jc.service_name = 'MC' THEN 'Professional MC services for ' || (4 + (RANDOM() * 4))::int || ' hours, including ceremony coordination, announcements, and entertainment.'
            WHEN jc.service_name = 'Security' THEN 'Professional security services with ' || (2 + (RANDOM() * 2))::int || ' security personnel for ' || (6 + (RANDOM() * 4))::int || ' hours of coverage.'
            WHEN jc.service_name = 'Sound System' THEN 'Premium sound system rental including speakers, microphones, mixing board, and technical support for ' || (4 + (RANDOM() * 4))::int || ' hours.'
            WHEN jc.service_name = 'Stage Design' THEN 'Custom stage design and setup including backdrop, lighting, props, and technical equipment for ' || (50 + (RANDOM() * 50))::int || ' guests.'
            WHEN jc.service_name = 'Photo Booth' THEN 'Fun photo booth rental with props, instant printing, digital gallery, and ' || (2 + (RANDOM() * 2))::int || ' hours of service.'
            ELSE 'Professional ' || jc.service_name || ' services for your special event. Includes full coverage, setup, and professional delivery.'
        END as quotation_details,
        'sample-quotations/' || LOWER(REPLACE(jc.service_name, ' ', '_')) || '_' || sp.service_provider_id || '_quote.pdf' as quotation_file_path,
        jc.service_name || ' Quote - ' || sp.service_provider_name || '.pdf' as quotation_file_name,
        CURRENT_DATE - (RANDOM() * 14)::int as quotation_submission_date, -- Submitted in last 2 weeks
        CURRENT_TIME as quotation_submission_time,
        'confirmed' as quotation_status,
        ROW_NUMBER() OVER (PARTITION BY jc.service_id ORDER BY RANDOM()) as service_quotation_rank
    FROM job_carts jc
    CROSS JOIN service_providers sp
    WHERE jc.service_name IN ('Photography', 'Makeup Artist', 'Catering', 'DJ Services', 'Decoration', 'Videography', 'Venue', 'Florist', 'MC', 'Security', 'Sound System', 'Stage Design', 'Photo Booth')
)
INSERT INTO quotation (
    quotation_id,
    service_provider_id,
    job_cart_id,
    service_id,
    quotation_price,
    quotation_details,
    quotation_file_path,
    quotation_file_name,
    quotation_submission_date,
    quotation_submission_time,
    quotation_status
)
SELECT 
    quotation_id,
    service_provider_id,
    job_cart_id,
    service_id,
    quotation_price,
    quotation_details,
    quotation_file_path,
    quotation_file_name,
    quotation_submission_date,
    quotation_submission_time,
    quotation_status
FROM quotation_generator
WHERE service_quotation_rank <= 4 -- Ensure at least 4 quotations per service
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
AND q.quotation_status = 'confirmed'

UNION ALL

SELECT 
    'Quotations by Service' as data_type,
    COUNT(*) as count
FROM quotation q
JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
JOIN service s ON q.service_id = s.service_id
WHERE jc.client_id = 'ff33d598-3d94-4fc1-9287-8760290651d3'
AND q.quotation_status = 'confirmed';

-- Step 4: Show detailed breakdown by service
SELECT 
    s.service_name,
    COUNT(q.quotation_id) as quotation_count,
    MIN(q.quotation_price) as min_price,
    MAX(q.quotation_price) as max_price,
    AVG(q.quotation_price)::numeric(10,2) as avg_price
FROM job_cart jc
JOIN service s ON jc.service_id = s.service_id
LEFT JOIN quotation q ON jc.job_cart_id = q.job_cart_id AND q.quotation_status = 'confirmed'
WHERE jc.client_id = 'ff33d598-3d94-4fc1-9287-8760290651d3'
GROUP BY s.service_name
ORDER BY quotation_count DESC, s.service_name;

-- Step 5: Show sample of created data
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
ORDER BY jc.created_at DESC
LIMIT 20;
