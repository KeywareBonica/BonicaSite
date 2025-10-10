-- ===============================================
-- Add New Service Providers and Ensure 3 Quotations Per Service
-- ===============================================

-- Step 1: Add new South African service providers for each service
-- This ensures we have enough providers to create 3 different quotations per service

INSERT INTO service_provider (
    service_provider_id,
    service_id,
    service_provider_name,
    service_provider_surname,
    service_provider_email,
    service_provider_contact,
    service_provider_location,
    service_provider_rating,
    service_provider_service_type,
    service_provider_verification,
    created_at
)
-- Hair Styling & Makeup providers
SELECT gen_random_uuid(), s.service_id, 'Nomsa', 'Mthembu', 'nomsa.mthembu@email.com', '082 123 4567', 'Sandton', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling & Makeup'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Thandi', 'Nkosi', 'thandi.nkosi@email.com', '083 234 5678', 'Rosebank', 4.6, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling & Makeup'

UNION ALL
-- Photography providers
SELECT gen_random_uuid(), s.service_id, 'Sipho', 'Mthembu', 'sipho.mthembu@email.com', '084 345 6789', 'Soweto', 4.9, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photography'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Lerato', 'Molefe', 'lerato.molefe@email.com', '085 456 7890', 'Johannesburg', 4.7, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photography'

UNION ALL
-- Videography providers
SELECT gen_random_uuid(), s.service_id, 'Mandla', 'Dlamini', 'mandla.dlamini@email.com', '086 567 8901', 'Sandton', 4.8, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Videography'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Zanele', 'Khumalo', 'zanele.khumalo@email.com', '087 678 9012', 'Rosebank', 4.5, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Videography'

UNION ALL
-- Catering providers
SELECT gen_random_uuid(), s.service_id, 'Bongani', 'Mthembu', 'bongani.mthembu@email.com', '088 789 0123', 'Soweto', 4.9, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Catering'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Nomsa', 'Zulu', 'nomsa.zulu@email.com', '089 890 1234', 'Johannesburg', 4.6, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Catering'

UNION ALL
-- Decoration providers
SELECT gen_random_uuid(), s.service_id, 'Thabo', 'Molefe', 'thabo.molefe@email.com', '090 901 2345', 'Sandton', 4.7, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decoration'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Precious', 'Nkosi', 'precious.nkosi@email.com', '091 012 3456', 'Rosebank', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decoration'

UNION ALL
-- DJ Services providers
SELECT gen_random_uuid(), s.service_id, 'DJ', 'Khaya', 'dj.khaya@email.com', '092 123 4567', 'Soweto', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ Services'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'DJ', 'Sbu', 'dj.sbu@email.com', '093 234 5678', 'Johannesburg', 4.5, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ Services'

UNION ALL
-- Venue providers
SELECT gen_random_uuid(), s.service_id, 'Grace', 'Van Zyl', 'grace.vanzyl@email.com', '094 345 6789', 'Sandton', 4.8, 'Venue', true, NOW()
FROM service s WHERE s.service_name = 'Venue'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Samuel', 'Van Heerden', 'samuel.vanheerden@email.com', '095 456 7890', 'Rosebank', 4.7, 'Venue', true, NOW()
FROM service s WHERE s.service_name = 'Venue'

UNION ALL
-- Security providers
SELECT gen_random_uuid(), s.service_id, 'Johan', 'Pretorius', 'johan.pretorius@email.com', '096 567 8901', 'Soweto', 4.6, 'Security', true, NOW()
FROM service s WHERE s.service_name = 'Security'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Pieter', 'Botha', 'pieter.botha@email.com', '097 678 9012', 'Johannesburg', 4.8, 'Security', true, NOW()
FROM service s WHERE s.service_name = 'Security'

UNION ALL
-- Event Planning providers
SELECT gen_random_uuid(), s.service_id, 'Sarah', 'Johnson', 'sarah.johnson@email.com', '098 789 0123', 'Sandton', 4.9, 'Planning', true, NOW()
FROM service s WHERE s.service_name = 'Event Planning'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Michael', 'Smith', 'michael.smith@email.com', '099 890 1234', 'Rosebank', 4.7, 'Planning', true, NOW()
FROM service s WHERE s.service_name = 'Event Planning'

UNION ALL
-- Florist providers
SELECT gen_random_uuid(), s.service_id, 'Emma', 'Wilson', 'emma.wilson@email.com', '010 901 2345', 'Soweto', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Florist'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'David', 'Brown', 'david.brown@email.com', '011 012 3456', 'Johannesburg', 4.6, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Florist'

UNION ALL
-- MC providers
SELECT gen_random_uuid(), s.service_id, 'MC', 'Tebogo', 'mc.tebogo@email.com', '012 123 4567', 'Sandton', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'MC'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'MC', 'Lebo', 'mc.lebo@email.com', '013 234 5678', 'Rosebank', 4.7, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'MC'

UNION ALL
-- Makeup & Hair providers
SELECT gen_random_uuid(), s.service_id, 'Amanda', 'Davis', 'amanda.davis@email.com', '014 345 6789', 'Soweto', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup & Hair'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Lisa', 'Anderson', 'lisa.anderson@email.com', '015 456 7890', 'Johannesburg', 4.6, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup & Hair'

UNION ALL
-- Makeup Artist providers
SELECT gen_random_uuid(), s.service_id, 'Jennifer', 'Taylor', 'jennifer.taylor@email.com', '016 567 8901', 'Sandton', 4.7, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup Artist'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Michelle', 'White', 'michelle.white@email.com', '017 678 9012', 'Rosebank', 4.9, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup Artist'

UNION ALL
-- Sound System providers
SELECT gen_random_uuid(), s.service_id, 'Robert', 'Jones', 'robert.jones@email.com', '018 789 0123', 'Soweto', 4.8, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Sound System'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'William', 'Garcia', 'william.garcia@email.com', '019 890 1234', 'Johannesburg', 4.5, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Sound System'

UNION ALL
-- Stage Design providers
SELECT gen_random_uuid(), s.service_id, 'James', 'Miller', 'james.miller@email.com', '020 901 2345', 'Sandton', 4.7, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Stage Design'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Christopher', 'Martinez', 'christopher.martinez@email.com', '021 012 3456', 'Rosebank', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Stage Design'

UNION ALL
-- Photo Booth providers
SELECT gen_random_uuid(), s.service_id, 'Daniel', 'Rodriguez', 'daniel.rodriguez@email.com', '022 123 4567', 'Soweto', 4.6, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Photo Booth'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Matthew', 'Lee', 'matthew.lee@email.com', '023 234 5678', 'Johannesburg', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Photo Booth'

UNION ALL
-- Hair Styling providers
SELECT gen_random_uuid(), s.service_id, 'Anthony', 'Perez', 'anthony.perez@email.com', '024 345 6789', 'Sandton', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Mark', 'Thompson', 'mark.thompson@email.com', '025 456 7890', 'Rosebank', 4.7, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling'

UNION ALL
-- Lighting providers
SELECT gen_random_uuid(), s.service_id, 'Donald', 'Wilson', 'donald.wilson@email.com', '026 567 8901', 'Soweto', 4.6, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Lighting'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Steven', 'Anderson', 'steven.anderson@email.com', '027 678 9012', 'Johannesburg', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Lighting'

UNION ALL
-- Musician providers
SELECT gen_random_uuid(), s.service_id, 'Paul', 'Thomas', 'paul.thomas@email.com', '028 789 0123', 'Sandton', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Musician'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Andrew', 'Jackson', 'andrew.jackson@email.com', '029 890 1234', 'Rosebank', 4.7, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Musician'

UNION ALL
-- Caterer providers
SELECT gen_random_uuid(), s.service_id, 'Joshua', 'White', 'joshua.white@email.com', '030 901 2345', 'Soweto', 4.8, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Caterer'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Kenneth', 'Harris', 'kenneth.harris@email.com', '031 012 3456', 'Johannesburg', 4.6, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Caterer'

UNION ALL
-- DJ providers
SELECT gen_random_uuid(), s.service_id, 'Kevin', 'Martin', 'kevin.martin@email.com', '032 123 4567', 'Sandton', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Brian', 'Garcia', 'brian.garcia@email.com', '033 234 5678', 'Rosebank', 4.5, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ'

UNION ALL
-- Decorator providers
SELECT gen_random_uuid(), s.service_id, 'George', 'Martinez', 'george.martinez@email.com', '034 345 6789', 'Soweto', 4.7, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decorator'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Timothy', 'Robinson', 'timothy.robinson@email.com', '035 456 7890', 'Johannesburg', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decorator'

UNION ALL
-- Flowers providers
SELECT gen_random_uuid(), s.service_id, 'Ronald', 'Clark', 'ronald.clark@email.com', '036 567 8901', 'Sandton', 4.6, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Flowers'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Jason', 'Rodriguez', 'jason.rodriguez@email.com', '037 678 9012', 'Rosebank', 4.9, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Flowers'

UNION ALL
-- Music providers
SELECT gen_random_uuid(), s.service_id, 'Ryan', 'Lewis', 'ryan.lewis@email.com', '038 789 0123', 'Soweto', 4.8, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Music'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Jacob', 'Lee', 'jacob.lee@email.com', '039 890 1234', 'Johannesburg', 4.7, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Music'

UNION ALL
-- Photographer providers
SELECT gen_random_uuid(), s.service_id, 'Gary', 'Walker', 'gary.walker@email.com', '040 901 2345', 'Sandton', 4.9, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photographer'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Nicholas', 'Hall', 'nicholas.hall@email.com', '041 012 3456', 'Rosebank', 4.6, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photographer'

UNION ALL
-- Hair Stylist providers
SELECT gen_random_uuid(), s.service_id, 'Eric', 'Allen', 'eric.allen@email.com', '042 123 4567', 'Soweto', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Stylist'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Jonathan', 'Young', 'jonathan.young@email.com', '043 234 5678', 'Johannesburg', 4.7, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Stylist'

ON CONFLICT (service_provider_id) DO NOTHING;

-- Step 2: Create additional quotations to ensure 3 per service
-- This will create quotations for services that have less than 3

-- Create 2nd quotation for each service (if not exists)
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
     AND service_id = s.service_id
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
AND s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
)
AND NOT EXISTS (
    SELECT 1 FROM quotation q 
    WHERE q.job_cart_id = jc.job_cart_id 
    AND q.quotation_file_path LIKE 'quotations/alt_quotation_%'
)
ON CONFLICT (quotation_id) DO NOTHING;

-- Step 3: Create 3rd quotation for each service (if not exists)
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
     AND service_id = s.service_id
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
AND s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
)
AND NOT EXISTS (
    SELECT 1 FROM quotation q 
    WHERE q.job_cart_id = jc.job_cart_id 
    AND q.quotation_file_path LIKE 'quotations/budget_quotation_%'
)
ON CONFLICT (quotation_id) DO NOTHING;

-- Step 4: Verification - Check final quotation counts per service
SELECT 
    'Final Quotation Count Per Service' AS info,
    s.service_name,
    COUNT(q.quotation_id) AS final_count,
    CASE 
        WHEN COUNT(q.quotation_id) = 3 THEN '✅ Perfect'
        WHEN COUNT(q.quotation_id) > 3 THEN '⚠️ More than 3'
        WHEN COUNT(q.quotation_id) < 3 THEN '❌ Less than 3'
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

-- Step 5: Show sample quotations with new providers
SELECT 
    'Sample Quotations with New Providers' AS info,
    q.quotation_id,
    s.service_name,
    sp.service_provider_name || ' ' || sp.service_provider_surname AS provider_name,
    sp.service_provider_location,
    q.quotation_price,
    q.quotation_file_path,
    q.quotation_status
FROM quotation q
JOIN service s ON q.service_id = s.service_id
JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
WHERE q.quotation_submission_date = '2025-10-10'
AND q.quotation_status = 'confirmed'
ORDER BY s.service_name, q.quotation_price
LIMIT 15;

-- Step 6: Final summary
SELECT 
    'Total Records Summary' AS info,
    'Service Providers Added' AS type,
    COUNT(*) AS count
FROM service_provider 
WHERE service_provider_location IN ('Sandton', 'Rosebank', 'Soweto', 'Johannesburg')

UNION ALL

SELECT 
    'Total Records Summary' AS info,
    'Quotations Created' AS type,
    COUNT(*) AS count
FROM quotation 
WHERE quotation_submission_date = '2025-10-10'

UNION ALL

SELECT 
    'Total Records Summary' AS info,
    'Services Covered' AS type,
    COUNT(DISTINCT service_id) AS count
FROM quotation 
WHERE quotation_submission_date = '2025-10-10';
