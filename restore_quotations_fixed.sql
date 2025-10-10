-- ===============================================
-- RESTORE QUOTATIONS AFTER CLEANUP ISSUE
-- ===============================================

-- Step 1: Check current state
SELECT 'Current quotation count:' AS info, COUNT(*) AS count FROM quotation WHERE quotation_submission_date = '2025-10-10';
SELECT 'Current job_cart count:' AS info, COUNT(*) AS count FROM job_cart WHERE job_cart_created_date = '2025-10-10';
SELECT 'Current service_provider count:' AS info, COUNT(*) AS count FROM service_provider;

-- Step 2: Create MANY job carts (50 per service = 1,300 total)
INSERT INTO job_cart (
    job_cart_id,
    event_id,
    client_id,
    service_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
)
WITH existing_data AS (
    SELECT 
        (SELECT client_id FROM client LIMIT 1) as client_id,
        (SELECT event_id FROM event LIMIT 1) as event_id
)
SELECT
    gen_random_uuid(),
    ed.event_id,
    ed.client_id,
    s.service_id,
    s.service_name,
    s.service_description,
    '2025-10-10',
    '09:00:00'::TIME + (INTERVAL '1 minute' * (ROW_NUMBER() OVER (ORDER BY s.service_id, gs) - 1)),
    'pending',
    NOW()
FROM service s
CROSS JOIN existing_data ed
CROSS JOIN generate_series(1, 50) as gs  -- 50 job carts per service
WHERE s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
)
ON CONFLICT (job_cart_id) DO NOTHING;

-- Step 3: Create MANY service providers (50 per service = 1,300 total)
INSERT INTO service_provider (
    service_provider_id,
    service_id,
    service_provider_name,
    service_provider_surname,
    service_provider_password,
    service_provider_contactno,
    service_provider_email,
    service_provider_location,
    service_provider_rating,
    service_provider_service_type,
    service_provider_verification,
    created_at
)
-- Create 5 service providers per service
SELECT
    gen_random_uuid(),
    s.service_id,
    CASE 
        WHEN s.service_name = 'Hair Styling & Makeup' THEN 'Nomsa'
        WHEN s.service_name = 'Photography' THEN 'Sipho'
        WHEN s.service_name = 'Videography' THEN 'Mandla'
        WHEN s.service_name = 'Catering' THEN 'Thabo'
        WHEN s.service_name = 'Decoration' THEN 'Grace'
        WHEN s.service_name = 'DJ Services' THEN 'DJ'
        WHEN s.service_name = 'Venue' THEN 'Sarah'
        WHEN s.service_name = 'Security' THEN 'Johan'
        WHEN s.service_name = 'Event Planning' THEN 'Amanda'
        WHEN s.service_name = 'Florist' THEN 'Emma'
        WHEN s.service_name = 'MC' THEN 'MC'
        WHEN s.service_name = 'Makeup & Hair' THEN 'Thandi'
        WHEN s.service_name = 'Makeup Artist' THEN 'Jennifer'
        WHEN s.service_name = 'Sound System' THEN 'Robert'
        WHEN s.service_name = 'Stage Design' THEN 'James'
        WHEN s.service_name = 'Photo Booth' THEN 'Daniel'
        WHEN s.service_name = 'Hair Styling' THEN 'Anthony'
        WHEN s.service_name = 'Lighting' THEN 'Donald'
        WHEN s.service_name = 'Musician' THEN 'Paul'
        WHEN s.service_name = 'Caterer' THEN 'Joshua'
        WHEN s.service_name = 'DJ' THEN 'Kevin'
        WHEN s.service_name = 'Decorator' THEN 'George'
        WHEN s.service_name = 'Flowers' THEN 'Ronald'
        WHEN s.service_name = 'Music' THEN 'Ryan'
        WHEN s.service_name = 'Photographer' THEN 'Gary'
        WHEN s.service_name = 'Hair Stylist' THEN 'Eric'
        ELSE 'Provider'
    END,
    CASE 
        WHEN s.service_name = 'Hair Styling & Makeup' THEN 'Mthembu'
        WHEN s.service_name = 'Photography' THEN 'Mthembu'
        WHEN s.service_name = 'Videography' THEN 'Dlamini'
        WHEN s.service_name = 'Catering' THEN 'Molefe'
        WHEN s.service_name = 'Decoration' THEN 'Van Zyl'
        WHEN s.service_name = 'DJ Services' THEN 'Khaya'
        WHEN s.service_name = 'Venue' THEN 'Johnson'
        WHEN s.service_name = 'Security' THEN 'Pretorius'
        WHEN s.service_name = 'Event Planning' THEN 'Davis'
        WHEN s.service_name = 'Florist' THEN 'Wilson'
        WHEN s.service_name = 'MC' THEN 'Tebogo'
        WHEN s.service_name = 'Makeup & Hair' THEN 'Nkosi'
        WHEN s.service_name = 'Makeup Artist' THEN 'Taylor'
        WHEN s.service_name = 'Sound System' THEN 'Jones'
        WHEN s.service_name = 'Stage Design' THEN 'Miller'
        WHEN s.service_name = 'Photo Booth' THEN 'Rodriguez'
        WHEN s.service_name = 'Hair Styling' THEN 'Perez'
        WHEN s.service_name = 'Lighting' THEN 'Wilson'
        WHEN s.service_name = 'Musician' THEN 'Thomas'
        WHEN s.service_name = 'Caterer' THEN 'White'
        WHEN s.service_name = 'DJ' THEN 'Martin'
        WHEN s.service_name = 'Decorator' THEN 'Martinez'
        WHEN s.service_name = 'Flowers' THEN 'Clark'
        WHEN s.service_name = 'Music' THEN 'Lewis'
        WHEN s.service_name = 'Photographer' THEN 'Walker'
        WHEN s.service_name = 'Hair Stylist' THEN 'Allen'
        ELSE 'Smith'
    END,
    'password123',
    '082 ' || LPAD((ROW_NUMBER() OVER (ORDER BY s.service_id, gs) + 100)::TEXT, 3, '0') || ' ' || LPAD((ROW_NUMBER() OVER (ORDER BY s.service_id, gs) + 1000)::TEXT, 4, '0'),
    LOWER(REPLACE(s.service_name, ' ', '')) || '.' || ROW_NUMBER() OVER (ORDER BY s.service_id, gs) || '.' || SUBSTRING(s.service_id::text, 1, 8) || '@email.com',
    CASE 
        WHEN ROW_NUMBER() OVER (ORDER BY s.service_id, gs) % 4 = 0 THEN 'Sandton'
        WHEN ROW_NUMBER() OVER (ORDER BY s.service_id, gs) % 4 = 1 THEN 'Rosebank'
        WHEN ROW_NUMBER() OVER (ORDER BY s.service_id, gs) % 4 = 2 THEN 'Soweto'
        ELSE 'Johannesburg'
    END,
    4.0 + (RANDOM() * 1.0),
    CASE 
        WHEN s.service_name IN ('Hair Styling & Makeup', 'Makeup & Hair', 'Makeup Artist', 'Hair Styling', 'Hair Stylist') THEN 'Beauty'
        WHEN s.service_name IN ('Photography', 'Videography', 'Photographer') THEN 'Media'
        WHEN s.service_name IN ('DJ Services', 'MC', 'Sound System', 'Photo Booth', 'Musician', 'DJ', 'Music') THEN 'Entertainment'
        WHEN s.service_name IN ('Catering', 'Caterer') THEN 'Food & Beverage'
        WHEN s.service_name IN ('Decoration', 'Stage Design', 'Lighting', 'Decorator', 'Flowers', 'Florist') THEN 'Design'
        WHEN s.service_name = 'Venue' THEN 'Venue'
        WHEN s.service_name = 'Security' THEN 'Security'
        WHEN s.service_name = 'Event Planning' THEN 'Planning'
        ELSE 'General'
    END,
    true,
    NOW()
FROM service s
CROSS JOIN generate_series(1, 50) as gs  -- 50 service providers per service
WHERE s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
)
ON CONFLICT (service_provider_id) DO NOTHING;

-- Step 4: Create MANY quotations (50 per service = 1,300 total)
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
-- Create 50 quotations per service
SELECT
    gen_random_uuid(),
    jc.job_cart_id,
    sp.service_provider_id,
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
        END) * (0.8 + (RANDOM() * 0.4))
    )::NUMERIC(10,2) AS quotation_price,
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY s.service_name ORDER BY sp.service_provider_id) = 1 THEN 'Professional ' || s.service_name || ' services for your special event.'
        WHEN ROW_NUMBER() OVER (PARTITION BY s.service_name ORDER BY sp.service_provider_id) = 2 THEN 'Alternative ' || s.service_name || ' package with competitive pricing.'
        WHEN ROW_NUMBER() OVER (PARTITION BY s.service_name ORDER BY sp.service_provider_id) = 3 THEN 'Budget-friendly ' || s.service_name || ' option with quality service.'
        WHEN ROW_NUMBER() OVER (PARTITION BY s.service_name ORDER BY sp.service_provider_id) = 4 THEN 'Premium ' || s.service_name || ' services with enhanced features.'
        ELSE 'Standard ' || s.service_name || ' package with reliable service.'
    END,
    'confirmed',  -- IMPORTANT: Set status to 'confirmed' so JavaScript can find them
    '2025-10-10',
    '09:30:00'::TIME + (INTERVAL '1 minute' * (ROW_NUMBER() OVER (PARTITION BY s.service_name ORDER BY sp.service_provider_id) - 1)),
    'quotations/quotation_' || SUBSTRING(jc.job_cart_id::text, 1, 8) || '_' || SUBSTRING(sp.service_provider_id::text, 1, 8) || '.pdf' AS quotation_file_path,
    'quotation_' || SUBSTRING(jc.job_cart_id::text, 1, 8) || '_' || SUBSTRING(sp.service_provider_id::text, 1, 8) || '.pdf' AS quotation_file_name,
    NOW()
FROM job_cart jc
JOIN service s ON jc.service_id = s.service_id
JOIN service_provider sp ON sp.service_id = s.service_id
WHERE jc.job_cart_created_date = '2025-10-10'
AND jc.job_cart_status = 'pending'
ON CONFLICT (quotation_id) DO NOTHING;

-- Step 5: Final verification
SELECT '=== RESTORATION COMPLETE ===' AS info;

SELECT 'Final Job Carts:' AS type, COUNT(*) AS count FROM job_cart WHERE job_cart_created_date = '2025-10-10';

SELECT 'Final Service Providers:' AS type, COUNT(*) AS count FROM service_provider;

SELECT 'Final Quotations:' AS type, COUNT(*) AS count FROM quotation WHERE quotation_submission_date = '2025-10-10';

-- Show quotations per service (should be exactly 50 each)
SELECT 
    'Quotations per Service:' AS info,
    s.service_name,
    COUNT(q.quotation_id) AS quotation_count,
    CASE 
        WHEN COUNT(q.quotation_id) = 50 THEN '✅ Perfect (50 quotations)'
        WHEN COUNT(q.quotation_id) > 50 THEN '⚠️ More than 50'
        WHEN COUNT(q.quotation_id) < 50 THEN '❌ Less than 50'
        ELSE '❌ No quotations'
    END AS status
FROM service s
LEFT JOIN quotation q ON s.service_id = q.service_id 
    AND q.quotation_submission_date = '2025-10-10'
    AND q.quotation_status = 'confirmed'
WHERE s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
)
GROUP BY s.service_name
ORDER BY s.service_name;
