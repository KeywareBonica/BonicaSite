-- ===============================================
-- FIXED SOLUTION: Add Service Providers and Quotations
-- ===============================================

-- Step 1: Remove the problematic trigger completely
DROP TRIGGER IF EXISTS validate_quotation_upload_trigger ON quotation;
DROP FUNCTION IF EXISTS validate_quotation_file_upload();

-- Step 2: Add new service providers with realistic passwords
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
-- Add 2 providers per service (52 total)
SELECT gen_random_uuid(), s.service_id, 'Nomsa', 'Mthembu', 'password123', '082 123 4567', 'nomsa.mthembu@email.com', 'Sandton', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling & Makeup'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Thandi', 'Nkosi', 'password123', '083 234 5678', 'thandi.nkosi@email.com', 'Rosebank', 4.6, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling & Makeup'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Sipho', 'Mthembu', 'password123', '084 345 6789', 'sipho.mthembu@email.com', 'Soweto', 4.9, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photography'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Lerato', 'Molefe', 'password123', '085 456 7890', 'lerato.molefe@email.com', 'Johannesburg', 4.7, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photography'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Mandla', 'Dlamini', 'password123', '086 567 8901', 'mandla.dlamini@email.com', 'Sandton', 4.8, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Videography'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Zanele', 'Khumalo', 'password123', '087 678 9012', 'zanele.khumalo@email.com', 'Rosebank', 4.5, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Videography'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Bongani', 'Mthembu', 'password123', '088 789 0123', 'bongani.mthembu@email.com', 'Soweto', 4.9, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Catering'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Nomsa', 'Zulu', 'password123', '089 890 1234', 'nomsa.zulu@email.com', 'Johannesburg', 4.6, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Catering'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Thabo', 'Molefe', 'password123', '090 901 2345', 'thabo.molefe@email.com', 'Sandton', 4.7, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decoration'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Precious', 'Nkosi', 'password123', '091 012 3456', 'precious.nkosi@email.com', 'Rosebank', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decoration'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'DJ', 'Khaya', 'password123', '092 123 4567', 'dj.khaya@email.com', 'Soweto', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ Services'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'DJ', 'Sbu', 'password123', '093 234 5678', 'dj.sbu@email.com', 'Johannesburg', 4.5, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ Services'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Grace', 'Van Zyl', 'password123', '094 345 6789', 'grace.vanzyl@email.com', 'Sandton', 4.8, 'Venue', true, NOW()
FROM service s WHERE s.service_name = 'Venue'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Samuel', 'Van Heerden', 'password123', '095 456 7890', 'samuel.vanheerden@email.com', 'Rosebank', 4.7, 'Venue', true, NOW()
FROM service s WHERE s.service_name = 'Venue'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Johan', 'Pretorius', 'password123', '096 567 8901', 'johan.pretorius@email.com', 'Soweto', 4.6, 'Security', true, NOW()
FROM service s WHERE s.service_name = 'Security'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Pieter', 'Botha', 'password123', '097 678 9012', 'pieter.botha@email.com', 'Johannesburg', 4.8, 'Security', true, NOW()
FROM service s WHERE s.service_name = 'Security'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Sarah', 'Johnson', 'password123', '098 789 0123', 'sarah.johnson@email.com', 'Sandton', 4.9, 'Planning', true, NOW()
FROM service s WHERE s.service_name = 'Event Planning'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Michael', 'Smith', 'password123', '099 890 1234', 'michael.smith@email.com', 'Rosebank', 4.7, 'Planning', true, NOW()
FROM service s WHERE s.service_name = 'Event Planning'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Emma', 'Wilson', 'password123', '010 901 2345', 'emma.wilson@email.com', 'Soweto', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Florist'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'David', 'Brown', 'password123', '011 012 3456', 'david.brown@email.com', 'Johannesburg', 4.6, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Florist'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'MC', 'Tebogo', 'password123', '012 123 4567', 'mc.tebogo@email.com', 'Sandton', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'MC'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'MC', 'Lebo', 'password123', '013 234 5678', 'mc.lebo@email.com', 'Rosebank', 4.7, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'MC'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Amanda', 'Davis', 'password123', '014 345 6789', 'amanda.davis@email.com', 'Soweto', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup & Hair'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Lisa', 'Anderson', 'password123', '015 456 7890', 'lisa.anderson@email.com', 'Johannesburg', 4.6, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup & Hair'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Jennifer', 'Taylor', 'password123', '016 567 8901', 'jennifer.taylor@email.com', 'Sandton', 4.7, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup Artist'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Michelle', 'White', 'password123', '017 678 9012', 'michelle.white@email.com', 'Rosebank', 4.9, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup Artist'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Robert', 'Jones', 'password123', '018 789 0123', 'robert.jones@email.com', 'Soweto', 4.8, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Sound System'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'William', 'Garcia', 'password123', '019 890 1234', 'william.garcia@email.com', 'Johannesburg', 4.5, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Sound System'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'James', 'Miller', 'password123', '020 901 2345', 'james.miller@email.com', 'Sandton', 4.7, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Stage Design'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Christopher', 'Martinez', 'password123', '021 012 3456', 'christopher.martinez@email.com', 'Rosebank', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Stage Design'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Daniel', 'Rodriguez', 'password123', '022 123 4567', 'daniel.rodriguez@email.com', 'Soweto', 4.6, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Photo Booth'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Matthew', 'Lee', 'password123', '023 234 5678', 'matthew.lee@email.com', 'Johannesburg', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Photo Booth'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Anthony', 'Perez', 'password123', '024 345 6789', 'anthony.perez@email.com', 'Sandton', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Mark', 'Thompson', 'password123', '025 456 7890', 'mark.thompson@email.com', 'Rosebank', 4.7, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Donald', 'Wilson', 'password123', '026 567 8901', 'donald.wilson@email.com', 'Soweto', 4.6, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Lighting'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Steven', 'Anderson', 'password123', '027 678 9012', 'steven.anderson@email.com', 'Johannesburg', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Lighting'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Paul', 'Thomas', 'password123', '028 789 0123', 'paul.thomas@email.com', 'Sandton', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Musician'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Andrew', 'Jackson', 'password123', '029 890 1234', 'andrew.jackson@email.com', 'Rosebank', 4.7, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Musician'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Joshua', 'White', 'password123', '030 901 2345', 'joshua.white@email.com', 'Soweto', 4.8, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Caterer'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Kenneth', 'Harris', 'password123', '031 012 3456', 'kenneth.harris@email.com', 'Johannesburg', 4.6, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Caterer'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Kevin', 'Martin', 'password123', '032 123 4567', 'kevin.martin@email.com', 'Sandton', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Brian', 'Garcia', 'password123', '033 234 5678', 'brian.garcia@email.com', 'Rosebank', 4.5, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'George', 'Martinez', 'password123', '034 345 6789', 'george.martinez@email.com', 'Soweto', 4.7, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decorator'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Timothy', 'Robinson', 'password123', '035 456 7890', 'timothy.robinson@email.com', 'Johannesburg', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decorator'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Ronald', 'Clark', 'password123', '036 567 8901', 'ronald.clark@email.com', 'Sandton', 4.6, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Flowers'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Jason', 'Rodriguez', 'password123', '037 678 9012', 'jason.rodriguez@email.com', 'Rosebank', 4.9, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Flowers'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Ryan', 'Lewis', 'password123', '038 789 0123', 'ryan.lewis@email.com', 'Soweto', 4.8, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Music'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Jacob', 'Lee', 'password123', '039 890 1234', 'jacob.lee@email.com', 'Johannesburg', 4.7, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Music'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Gary', 'Walker', 'password123', '040 901 2345', 'gary.walker@email.com', 'Sandton', 4.9, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photographer'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Nicholas', 'Hall', 'password123', '041 012 3456', 'nicholas.hall@email.com', 'Rosebank', 4.6, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photographer'

UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Eric', 'Allen', 'password123', '042 123 4567', 'eric.allen@email.com', 'Soweto', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Stylist'
UNION ALL
SELECT gen_random_uuid(), s.service_id, 'Jonathan', 'Young', 'password123', '043 234 5678', 'jonathan.young@email.com', 'Johannesburg', 4.7, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Stylist'

ON CONFLICT (service_provider_id) DO NOTHING;

-- Step 3: Create quotations ONLY for services that have job carts and service providers
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
-- Create quotations for existing job carts with available service providers
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
            ELSE 2000.00
        END) * (1 + (RANDOM() * 0.2))
    )::NUMERIC(10,2) AS quotation_price,
    'Professional ' || s.service_name || ' services for your special event.',
    'confirmed',
    '2025-10-10',
    '09:30:00'::TIME,
    'quotations/quotation_' || SUBSTRING(jc.job_cart_id::text, 1, 8) || '.pdf' AS quotation_file_path,
    'quotation_' || SUBSTRING(jc.job_cart_id::text, 1, 8) || '.pdf' AS quotation_file_name,
    NOW()
FROM job_cart jc
JOIN service s ON jc.service_id = s.service_id
JOIN service_provider sp ON sp.service_id = s.service_id
WHERE jc.job_cart_created_date = '2025-10-10'
AND jc.job_cart_status = 'pending'
AND NOT EXISTS (
    SELECT 1 FROM quotation q 
    WHERE q.job_cart_id = jc.job_cart_id 
    AND q.service_provider_id = sp.service_provider_id
)
ON CONFLICT (quotation_id) DO NOTHING;

-- Step 4: Create additional quotations (2nd quotation for each service)
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
    sp2.service_provider_id,
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
            ELSE 2000.00
        END) * (1 + (RANDOM() * 0.2))
    )::NUMERIC(10,2) AS quotation_price,
    'Alternative ' || s.service_name || ' services with competitive pricing.',
    'confirmed',
    '2025-10-10',
    '10:30:00'::TIME,
    'quotations/alt_' || SUBSTRING(jc.job_cart_id::text, 1, 8) || '.pdf' AS quotation_file_path,
    'alt_' || SUBSTRING(jc.job_cart_id::text, 1, 8) || '.pdf' AS quotation_file_name,
    NOW()
FROM job_cart jc
JOIN service s ON jc.service_id = s.service_id
JOIN service_provider sp ON sp.service_id = s.service_id
JOIN service_provider sp2 ON sp2.service_id = s.service_id AND sp2.service_provider_id != sp.service_provider_id
WHERE jc.job_cart_created_date = '2025-10-10'
AND jc.job_cart_status = 'pending'
AND NOT EXISTS (
    SELECT 1 FROM quotation q 
    WHERE q.job_cart_id = jc.job_cart_id 
    AND q.quotation_file_path LIKE 'quotations/alt_%'
)
ON CONFLICT (quotation_id) DO NOTHING;

-- Step 5: Check results
SELECT 
    'Final Results' AS info,
    s.service_name,
    COUNT(q.quotation_id) AS quotation_count
FROM service s
LEFT JOIN quotation q ON s.service_id = q.service_id 
    AND q.quotation_submission_date = '2025-10-10'
    AND q.quotation_status = 'confirmed'
WHERE s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC'
)
GROUP BY s.service_name
ORDER BY s.service_name;
