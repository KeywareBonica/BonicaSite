-- Add 2 additional quotations per service (to get 3 total per service)
-- This script assumes you already have 1 quotation per service from the previous script

-- Step 1: Add second quotation for each service
INSERT INTO quotation (
    quotation_id,
    job_cart_id,
    service_provider_id,
    service_id,
    quotation_price,
    quotation_details,
    quotation_status,
    quotation_submission_date,
    quotation_submission_time,
    quotation_file_path,
    quotation_file_name,
    created_at
)
SELECT
    gen_random_uuid(),
    jc.job_cart_id,
    (SELECT service_provider_id FROM service_provider 
     WHERE service_provider_id != sp.service_provider_id 
     ORDER BY RANDOM() LIMIT 1),
    jc.service_id,
    ROUND(
        (CASE 
            WHEN s.service_name = 'Hair Styling & Makeup' THEN 2500.00
            WHEN s.service_name = 'Photography' THEN 3500.00
            WHEN s.service_name = 'Videography' THEN 4500.00
            WHEN s.service_name = 'Catering' THEN 8000.00
            WHEN s.service_name = 'Decoration' THEN 3000.00
            WHEN s.service_name = 'DJ Services' THEN 2000.00
            WHEN s.service_name = 'Venue' THEN 12000.00
            WHEN s.service_name = 'Security' THEN 1500.00
            WHEN s.service_name = 'Event Planning' THEN 5000.00
            WHEN s.service_name = 'Florist' THEN 1800.00
            WHEN s.service_name = 'MC' THEN 1800.00
            WHEN s.service_name = 'Makeup & Hair' THEN 2500.00
            WHEN s.service_name = 'Makeup Artist' THEN 2500.00
            WHEN s.service_name = 'Sound System' THEN 2000.00
            WHEN s.service_name = 'Stage Design' THEN 3000.00
            WHEN s.service_name = 'Photo Booth' THEN 1000.00
            WHEN s.service_name = 'Hair Styling' THEN 2500.00
            WHEN s.service_name = 'Lighting' THEN 1500.00
            WHEN s.service_name = 'Musician' THEN 2000.00
            WHEN s.service_name = 'Caterer' THEN 8000.00
            WHEN s.service_name = 'DJ' THEN 2000.00
            WHEN s.service_name = 'Decorator' THEN 3000.00
            WHEN s.service_name = 'Flowers' THEN 1500.00
            WHEN s.service_name = 'Music' THEN 2000.00
            WHEN s.service_name = 'Photographer' THEN 3500.00
            WHEN s.service_name = 'Hair Stylist' THEN 2500.00
            ELSE 2000.00
        END) * (1 + (RANDOM() * 0.2))
    )::NUMERIC(10,2) AS quotation_price,
    'Alternative ' || s.service_name || ' services with competitive pricing.',
    'confirmed',
    '2025-10-10',
    '10:30:00'::TIME,
    'quotations/alt_quotation_' || 
        SUBSTRING(jc.job_cart_id::text, 1, 8) || '_' || 
        SUBSTRING(gen_random_uuid()::text, 1, 8) || '.pdf' AS quotation_file_path,
    'alt_quotation_' || 
        SUBSTRING(jc.job_cart_id::text, 1, 8) || '_' || 
        SUBSTRING(gen_random_uuid()::text, 1, 8) || '.pdf' AS quotation_file_name,
    NOW()
FROM job_cart jc
JOIN service s ON jc.service_id = s.service_id
JOIN service_provider sp ON sp.service_id = s.service_id
WHERE jc.job_cart_created_date = '2025-10-10'
AND jc.job_cart_status = 'pending'
AND NOT EXISTS (
    SELECT 1 FROM quotation q 
    WHERE q.job_cart_id = jc.job_cart_id 
    AND q.quotation_file_path LIKE 'quotations/alt_quotation_%'
)
ON CONFLICT (quotation_id) DO NOTHING;

-- Step 2: Add third quotation for each service
INSERT INTO quotation (
    quotation_id,
    job_cart_id,
    service_provider_id,
    service_id,
    quotation_price,
    quotation_details,
    quotation_status,
    quotation_submission_date,
    quotation_submission_time,
    quotation_file_path,
    quotation_file_name,
    created_at
)
SELECT
    gen_random_uuid(),
    jc.job_cart_id,
    (SELECT service_provider_id FROM service_provider 
     WHERE service_provider_id NOT IN (
         SELECT q.service_provider_id FROM quotation q 
         WHERE q.job_cart_id = jc.job_cart_id
     )
     ORDER BY RANDOM() LIMIT 1),
    jc.service_id,
    ROUND(
        (CASE 
            WHEN s.service_name = 'Hair Styling & Makeup' THEN 2500.00
            WHEN s.service_name = 'Photography' THEN 3500.00
            WHEN s.service_name = 'Videography' THEN 4500.00
            WHEN s.service_name = 'Catering' THEN 8000.00
            WHEN s.service_name = 'Decoration' THEN 3000.00
            WHEN s.service_name = 'DJ Services' THEN 2000.00
            WHEN s.service_name = 'Venue' THEN 12000.00
            WHEN s.service_name = 'Security' THEN 1500.00
            WHEN s.service_name = 'Event Planning' THEN 5000.00
            WHEN s.service_name = 'Florist' THEN 1800.00
            WHEN s.service_name = 'MC' THEN 1800.00
            WHEN s.service_name = 'Makeup & Hair' THEN 2500.00
            WHEN s.service_name = 'Makeup Artist' THEN 2500.00
            WHEN s.service_name = 'Sound System' THEN 2000.00
            WHEN s.service_name = 'Stage Design' THEN 3000.00
            WHEN s.service_name = 'Photo Booth' THEN 1000.00
            WHEN s.service_name = 'Hair Styling' THEN 2500.00
            WHEN s.service_name = 'Lighting' THEN 1500.00
            WHEN s.service_name = 'Musician' THEN 2000.00
            WHEN s.service_name = 'Caterer' THEN 8000.00
            WHEN s.service_name = 'DJ' THEN 2000.00
            WHEN s.service_name = 'Decorator' THEN 3000.00
            WHEN s.service_name = 'Flowers' THEN 1500.00
            WHEN s.service_name = 'Music' THEN 2000.00
            WHEN s.service_name = 'Photographer' THEN 3500.00
            WHEN s.service_name = 'Hair Stylist' THEN 2500.00
            ELSE 2000.00
        END) * (0.8 + (RANDOM() * 0.3))
    )::NUMERIC(10,2) AS quotation_price,
    'Budget-friendly ' || s.service_name || ' package with quality service.',
    'confirmed',
    '2025-10-10',
    '11:30:00'::TIME,
    'quotations/budget_quotation_' || 
        SUBSTRING(jc.job_cart_id::text, 1, 8) || '_' || 
        SUBSTRING(gen_random_uuid()::text, 1, 8) || '.pdf' AS quotation_file_path,
    'budget_quotation_' || 
        SUBSTRING(jc.job_cart_id::text, 1, 8) || '_' || 
        SUBSTRING(gen_random_uuid()::text, 1, 8) || '.pdf' AS quotation_file_name,
    NOW()
FROM job_cart jc
JOIN service s ON jc.service_id = s.service_id
JOIN service_provider sp ON sp.service_id = s.service_id
WHERE jc.job_cart_created_date = '2025-10-10'
AND jc.job_cart_status = 'pending'
AND NOT EXISTS (
    SELECT 1 FROM quotation q 
    WHERE q.job_cart_id = jc.job_cart_id 
    AND q.quotation_file_path LIKE 'quotations/budget_quotation_%'
)
ON CONFLICT (quotation_id) DO NOTHING;

-- Step 3: Verification - Check quotation counts per service
SELECT 
    'Quotation Count Per Service' AS info,
    s.service_name,
    COUNT(q.quotation_id) AS quotation_count
FROM service s
LEFT JOIN job_cart jc ON s.service_id = jc.service_id AND jc.job_cart_created_date = '2025-10-10'
LEFT JOIN quotation q ON jc.job_cart_id = q.job_cart_id AND q.quotation_submission_date = '2025-10-10'
WHERE s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
)
GROUP BY s.service_name
ORDER BY s.service_name;

-- Step 4: Final summary
SELECT 
    'Total Records Summary' AS info,
    'Job Carts' AS type,
    COUNT(*) AS count
FROM job_cart 
WHERE job_cart_created_date = '2025-10-10'

UNION ALL

SELECT 
    'Total Records Summary' AS info,
    'Quotations' AS type,
    COUNT(*) AS count
FROM quotation 
WHERE quotation_submission_date = '2025-10-10';
