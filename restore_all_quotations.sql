-- ===============================================
-- RESTORE ALL QUOTATIONS (UNDO CLEANUP)
-- ===============================================

-- Step 1: Check current state
SELECT 'Current quotation count:' AS info, COUNT(*) AS count FROM quotation;
SELECT 'Current job_cart count:' AS info, COUNT(*) AS count FROM job_cart;
SELECT 'Current service_provider count:' AS info, COUNT(*) AS count FROM service_provider;

-- Step 2: Restore job carts (recreate the 4,000+ job carts that were deleted)
-- This will recreate job carts for all services with multiple variations
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
-- Create multiple job carts per service to reach 4,000+ total
WITH existing_data AS (
    SELECT 
        (SELECT client_id FROM client LIMIT 1) as client_id,
        (SELECT event_id FROM event LIMIT 1) as event_id
),
service_variations AS (
    SELECT s.service_id, s.service_name, s.service_description,
           CASE 
               WHEN s.service_name = 'Hair Styling & Makeup' THEN 150
               WHEN s.service_name = 'Photography' THEN 200
               WHEN s.service_name = 'Videography' THEN 180
               WHEN s.service_name = 'Catering' THEN 120
               WHEN s.service_name = 'Decoration' THEN 160
               WHEN s.service_name = 'DJ Services' THEN 140
               WHEN s.service_name = 'Venue' THEN 100
               WHEN s.service_name = 'Security' THEN 130
               WHEN s.service_name = 'Event Planning' THEN 110
               WHEN s.service_name = 'Florist' THEN 170
               WHEN s.service_name = 'MC' THEN 150
               WHEN s.service_name = 'Makeup & Hair' THEN 120
               WHEN s.service_name = 'Makeup Artist' THEN 130
               WHEN s.service_name = 'Sound System' THEN 140
               WHEN s.service_name = 'Stage Design' THEN 160
               WHEN s.service_name = 'Photo Booth' THEN 180
               WHEN s.service_name = 'Hair Styling' THEN 150
               WHEN s.service_name = 'Lighting' THEN 140
               WHEN s.service_name = 'Musician' THEN 130
               WHEN s.service_name = 'Caterer' THEN 120
               WHEN s.service_name = 'DJ' THEN 140
               WHEN s.service_name = 'Decorator' THEN 160
               WHEN s.service_name = 'Flowers' THEN 170
               WHEN s.service_name = 'Music' THEN 130
               WHEN s.service_name = 'Photographer' THEN 200
               WHEN s.service_name = 'Hair Stylist' THEN 150
               ELSE 100
           END as quantity
    FROM service s
    WHERE s.service_name IN (
        'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
        'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
        'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
        'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
        'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
    )
)
SELECT
    gen_random_uuid(),
    ed.event_id,
    ed.client_id,
    sv.service_id,
    sv.service_name,
    sv.service_description,
    '2025-10-10',
    (CASE 
        WHEN sv.service_name = 'Hair Styling & Makeup' THEN '09:00:00'::TIME
        WHEN sv.service_name = 'Photography' THEN '10:00:00'::TIME
        WHEN sv.service_name = 'Videography' THEN '11:00:00'::TIME
        WHEN sv.service_name = 'Catering' THEN '12:00:00'::TIME
        WHEN sv.service_name = 'Decoration' THEN '13:00:00'::TIME
        WHEN sv.service_name = 'DJ Services' THEN '14:00:00'::TIME
        WHEN sv.service_name = 'Venue' THEN '15:00:00'::TIME
        WHEN sv.service_name = 'Security' THEN '16:00:00'::TIME
        WHEN sv.service_name = 'Event Planning' THEN '17:00:00'::TIME
        WHEN sv.service_name = 'Florist' THEN '18:00:00'::TIME
        WHEN sv.service_name = 'MC' THEN '18:30:00'::TIME
        WHEN sv.service_name = 'Makeup & Hair' THEN '09:30:00'::TIME
        WHEN sv.service_name = 'Makeup Artist' THEN '10:30:00'::TIME
        WHEN sv.service_name = 'Sound System' THEN '11:30:00'::TIME
        WHEN sv.service_name = 'Stage Design' THEN '12:30:00'::TIME
        WHEN sv.service_name = 'Photo Booth' THEN '13:30:00'::TIME
        WHEN sv.service_name = 'Hair Styling' THEN '14:30:00'::TIME
        WHEN sv.service_name = 'Lighting' THEN '15:30:00'::TIME
        WHEN sv.service_name = 'Musician' THEN '16:30:00'::TIME
        WHEN sv.service_name = 'Caterer' THEN '17:30:00'::TIME
        WHEN sv.service_name = 'DJ' THEN '18:00:00'::TIME
        WHEN sv.service_name = 'Decorator' THEN '19:00:00'::TIME
        WHEN sv.service_name = 'Flowers' THEN '19:30:00'::TIME
        WHEN sv.service_name = 'Music' THEN '20:00:00'::TIME
        WHEN sv.service_name = 'Photographer' THEN '20:30:00'::TIME
        WHEN sv.service_name = 'Hair Stylist' THEN '21:00:00'::TIME
        ELSE '09:00:00'::TIME
    END + (INTERVAL '1 minute' * (ROW_NUMBER() OVER (PARTITION BY sv.service_id ORDER BY sv.service_id) - 1))),
    'pending',
    NOW()
FROM service_variations sv
CROSS JOIN existing_data ed
CROSS JOIN generate_series(1, sv.quantity) as gs
ON CONFLICT (job_cart_id) DO NOTHING;

-- Step 3: Restore service providers (recreate the 4,000+ service providers)
-- This will create multiple service providers per service
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
-- Create multiple service providers per service
WITH service_provider_counts AS (
    SELECT s.service_id, s.service_name,
           CASE 
               WHEN s.service_name = 'Hair Styling & Makeup' THEN 150
               WHEN s.service_name = 'Photography' THEN 200
               WHEN s.service_name = 'Videography' THEN 180
               WHEN s.service_name = 'Catering' THEN 120
               WHEN s.service_name = 'Decoration' THEN 160
               WHEN s.service_name = 'DJ Services' THEN 140
               WHEN s.service_name = 'Venue' THEN 100
               WHEN s.service_name = 'Security' THEN 130
               WHEN s.service_name = 'Event Planning' THEN 110
               WHEN s.service_name = 'Florist' THEN 170
               WHEN s.service_name = 'MC' THEN 150
               WHEN s.service_name = 'Makeup & Hair' THEN 120
               WHEN s.service_name = 'Makeup Artist' THEN 130
               WHEN s.service_name = 'Sound System' THEN 140
               WHEN s.service_name = 'Stage Design' THEN 160
               WHEN s.service_name = 'Photo Booth' THEN 180
               WHEN s.service_name = 'Hair Styling' THEN 150
               WHEN s.service_name = 'Lighting' THEN 140
               WHEN s.service_name = 'Musician' THEN 130
               WHEN s.service_name = 'Caterer' THEN 120
               WHEN s.service_name = 'DJ' THEN 140
               WHEN s.service_name = 'Decorator' THEN 160
               WHEN s.service_name = 'Flowers' THEN 170
               WHEN s.service_name = 'Music' THEN 130
               WHEN s.service_name = 'Photographer' THEN 200
               WHEN s.service_name = 'Hair Stylist' THEN 150
               ELSE 100
           END as provider_count
    FROM service s
    WHERE s.service_name IN (
        'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
        'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
        'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
        'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
        'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
    )
)
SELECT
    gen_random_uuid(),
    spc.service_id,
    CASE 
        WHEN spc.service_name = 'Hair Styling & Makeup' THEN 'Nomsa'
        WHEN spc.service_name = 'Photography' THEN 'Sipho'
        WHEN spc.service_name = 'Videography' THEN 'Mandla'
        WHEN spc.service_name = 'Catering' THEN 'Thabo'
        WHEN spc.service_name = 'Decoration' THEN 'Grace'
        WHEN spc.service_name = 'DJ Services' THEN 'DJ'
        WHEN spc.service_name = 'Venue' THEN 'Sarah'
        WHEN spc.service_name = 'Security' THEN 'Johan'
        WHEN spc.service_name = 'Event Planning' THEN 'Amanda'
        WHEN spc.service_name = 'Florist' THEN 'Emma'
        WHEN spc.service_name = 'MC' THEN 'MC'
        WHEN spc.service_name = 'Makeup & Hair' THEN 'Thandi'
        WHEN spc.service_name = 'Makeup Artist' THEN 'Jennifer'
        WHEN spc.service_name = 'Sound System' THEN 'Robert'
        WHEN spc.service_name = 'Stage Design' THEN 'James'
        WHEN spc.service_name = 'Photo Booth' THEN 'Daniel'
        WHEN spc.service_name = 'Hair Styling' THEN 'Anthony'
        WHEN spc.service_name = 'Lighting' THEN 'Donald'
        WHEN spc.service_name = 'Musician' THEN 'Paul'
        WHEN spc.service_name = 'Caterer' THEN 'Joshua'
        WHEN spc.service_name = 'DJ' THEN 'Kevin'
        WHEN spc.service_name = 'Decorator' THEN 'George'
        WHEN spc.service_name = 'Flowers' THEN 'Ronald'
        WHEN spc.service_name = 'Music' THEN 'Ryan'
        WHEN spc.service_name = 'Photographer' THEN 'Gary'
        WHEN spc.service_name = 'Hair Stylist' THEN 'Eric'
        ELSE 'Provider'
    END,
    CASE 
        WHEN spc.service_name = 'Hair Styling & Makeup' THEN 'Mthembu'
        WHEN spc.service_name = 'Photography' THEN 'Mthembu'
        WHEN spc.service_name = 'Videography' THEN 'Dlamini'
        WHEN spc.service_name = 'Catering' THEN 'Molefe'
        WHEN spc.service_name = 'Decoration' THEN 'Van Zyl'
        WHEN spc.service_name = 'DJ Services' THEN 'Khaya'
        WHEN spc.service_name = 'Venue' THEN 'Johnson'
        WHEN spc.service_name = 'Security' THEN 'Pretorius'
        WHEN spc.service_name = 'Event Planning' THEN 'Davis'
        WHEN spc.service_name = 'Florist' THEN 'Wilson'
        WHEN spc.service_name = 'MC' THEN 'Tebogo'
        WHEN spc.service_name = 'Makeup & Hair' THEN 'Nkosi'
        WHEN spc.service_name = 'Makeup Artist' THEN 'Taylor'
        WHEN spc.service_name = 'Sound System' THEN 'Jones'
        WHEN spc.service_name = 'Stage Design' THEN 'Miller'
        WHEN spc.service_name = 'Photo Booth' THEN 'Rodriguez'
        WHEN spc.service_name = 'Hair Styling' THEN 'Perez'
        WHEN spc.service_name = 'Lighting' THEN 'Wilson'
        WHEN spc.service_name = 'Musician' THEN 'Thomas'
        WHEN spc.service_name = 'Caterer' THEN 'White'
        WHEN spc.service_name = 'DJ' THEN 'Martin'
        WHEN spc.service_name = 'Decorator' THEN 'Martinez'
        WHEN spc.service_name = 'Flowers' THEN 'Clark'
        WHEN spc.service_name = 'Music' THEN 'Lewis'
        WHEN spc.service_name = 'Photographer' THEN 'Walker'
        WHEN spc.service_name = 'Hair Stylist' THEN 'Allen'
        ELSE 'Smith'
    END,
    'password123',
    '082 ' || LPAD((ROW_NUMBER() OVER (PARTITION BY spc.service_id ORDER BY spc.service_id) + 100)::TEXT, 3, '0') || ' ' || LPAD((ROW_NUMBER() OVER (PARTITION BY spc.service_id ORDER BY spc.service_id) + 1000)::TEXT, 4, '0'),
    LOWER(REPLACE(spc.service_name, ' ', '')) || '.' || ROW_NUMBER() OVER (PARTITION BY spc.service_id ORDER BY spc.service_id) || '@email.com',
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY spc.service_id ORDER BY spc.service_id) % 4 = 0 THEN 'Sandton'
        WHEN ROW_NUMBER() OVER (PARTITION BY spc.service_id ORDER BY spc.service_id) % 4 = 1 THEN 'Rosebank'
        WHEN ROW_NUMBER() OVER (PARTITION BY spc.service_id ORDER BY spc.service_id) % 4 = 2 THEN 'Soweto'
        ELSE 'Johannesburg'
    END,
    4.0 + (RANDOM() * 1.0),
    CASE 
        WHEN spc.service_name IN ('Hair Styling & Makeup', 'Makeup & Hair', 'Makeup Artist', 'Hair Styling', 'Hair Stylist') THEN 'Beauty'
        WHEN spc.service_name IN ('Photography', 'Videography', 'Photographer') THEN 'Media'
        WHEN spc.service_name IN ('DJ Services', 'MC', 'Sound System', 'Photo Booth', 'Musician', 'DJ', 'Music') THEN 'Entertainment'
        WHEN spc.service_name IN ('Catering', 'Caterer') THEN 'Food & Beverage'
        WHEN spc.service_name IN ('Decoration', 'Stage Design', 'Lighting', 'Decorator', 'Flowers', 'Florist') THEN 'Design'
        WHEN spc.service_name = 'Venue' THEN 'Venue'
        WHEN spc.service_name = 'Security' THEN 'Security'
        WHEN spc.service_name = 'Event Planning' THEN 'Planning'
        ELSE 'General'
    END,
    true,
    NOW()
FROM service_provider_counts spc
CROSS JOIN generate_series(1, spc.provider_count) as gs
ON CONFLICT (service_provider_id) DO NOTHING;

-- Step 4: Restore quotations (recreate the 4,000+ quotations)
-- This will create multiple quotations per job cart
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
-- Create multiple quotations per job cart
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
        WHEN ROW_NUMBER() OVER (PARTITION BY jc.job_cart_id ORDER BY sp.service_provider_id) = 1 THEN 'Professional ' || s.service_name || ' services for your special event.'
        WHEN ROW_NUMBER() OVER (PARTITION BY jc.job_cart_id ORDER BY sp.service_provider_id) = 2 THEN 'Alternative ' || s.service_name || ' package with competitive pricing.'
        WHEN ROW_NUMBER() OVER (PARTITION BY jc.job_cart_id ORDER BY sp.service_provider_id) = 3 THEN 'Budget-friendly ' || s.service_name || ' option with quality service.'
        ELSE 'Premium ' || s.service_name || ' services with enhanced features.'
    END,
    'confirmed',
    '2025-10-10',
    '09:30:00'::TIME + (INTERVAL '1 minute' * (ROW_NUMBER() OVER (PARTITION BY jc.job_cart_id ORDER BY sp.service_provider_id) - 1)),
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
SELECT 'Total Job Carts:' AS type, COUNT(*) AS count FROM job_cart WHERE job_cart_created_date = '2025-10-10';
SELECT 'Total Service Providers:' AS type, COUNT(*) AS count FROM service_provider;
SELECT 'Total Quotations:' AS type, COUNT(*) AS count FROM quotation WHERE quotation_submission_date = '2025-10-10';

-- Step 6: Show quotations per service
SELECT 
    'Quotations per Service:' AS info,
    s.service_name,
    COUNT(q.quotation_id) AS quotation_count
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
ORDER BY COUNT(q.quotation_id) DESC;
