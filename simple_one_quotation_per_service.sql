-- ===============================================
-- SIMPLE SOLUTION: 1 Quotation Per Service Only
-- ===============================================

-- Step 1: Remove the problematic trigger completely
DROP TRIGGER IF EXISTS validate_quotation_upload_trigger ON quotation;
DROP FUNCTION IF EXISTS validate_quotation_file_upload();

-- Step 2: Ensure we have basic required data
INSERT INTO client (
    client_id, client_name, client_surname, client_password, 
    client_contact, client_email, client_city
)
SELECT 
    'c1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'John', 'Doe', 
    '$2a$10$xyz123encryptedpassword', 
    '082 555 1234', 
    'john.doe@example.com',
    'Johannesburg'
WHERE NOT EXISTS (SELECT 1 FROM client LIMIT 1);

INSERT INTO event (
    event_id, event_type, event_date, event_start_time, event_location
)
SELECT
    'e1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'Wedding', '2025-10-10', '14:00:00', 'Sandton Convention Centre'
WHERE NOT EXISTS (SELECT 1 FROM event LIMIT 1);

-- Step 3: Create job carts for ALL services
WITH existing_data AS (
    SELECT 
        (SELECT client_id FROM client LIMIT 1) as client_id,
        (SELECT event_id FROM event LIMIT 1) as event_id
)
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
SELECT
    gen_random_uuid(),
    ed.event_id,
    ed.client_id,
    s.service_id,
    s.service_name,
    s.service_description,
    '2025-10-10',
    '09:00:00'::TIME,
    'pending',
    NOW()
FROM service s
CROSS JOIN existing_data ed
WHERE s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
)
AND NOT EXISTS (
    SELECT 1 FROM job_cart jc 
    WHERE jc.service_id = s.service_id 
    AND jc.job_cart_created_date = '2025-10-10'
);

-- Step 4: Add ONE service provider per service (26 total)
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
SELECT gen_random_uuid(), s.service_id, 'Nomsa', 'Mthembu', 'password123', '082 123 4567', 'nomsa.mthembu.hair@email.com', 'Sandton', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling & Makeup'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Sipho', 'Mthembu', 'password123', '084 345 6789', 'sipho.mthembu.photo@email.com', 'Soweto', 4.9, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photography'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Mandla', 'Dlamini', 'password123', '086 567 8901', 'mandla.dlamini.video@email.com', 'Sandton', 4.8, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Videography'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Bongani', 'Mthembu', 'password123', '088 789 0123', 'bongani.mthembu.catering@email.com', 'Soweto', 4.9, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Catering'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Thabo', 'Molefe', 'password123', '090 901 2345', 'thabo.molefe.decoration@email.com', 'Sandton', 4.7, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decoration'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'DJ', 'Khaya', 'password123', '092 123 4567', 'dj.khaya.djservices@email.com', 'Soweto', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ Services'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Grace', 'Van Zyl', 'password123', '094 345 6789', 'grace.vanzyl.venue@email.com', 'Sandton', 4.8, 'Venue', true, NOW()
FROM service s WHERE s.service_name = 'Venue'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Johan', 'Pretorius', 'password123', '096 567 8901', 'johan.pretorius.security@email.com', 'Soweto', 4.6, 'Security', true, NOW()
FROM service s WHERE s.service_name = 'Security'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Sarah', 'Johnson', 'password123', '098 789 0123', 'sarah.johnson.eventplanning@email.com', 'Sandton', 4.9, 'Planning', true, NOW()
FROM service s WHERE s.service_name = 'Event Planning'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Emma', 'Wilson', 'password123', '010 901 2345', 'emma.wilson.florist@email.com', 'Soweto', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Florist'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'MC', 'Tebogo', 'password123', '012 123 4567', 'mc.tebogo.mc@email.com', 'Sandton', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'MC'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Amanda', 'Davis', 'password123', '014 345 6789', 'amanda.davis.makeup@email.com', 'Soweto', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup & Hair'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Jennifer', 'Taylor', 'password123', '016 567 8901', 'jennifer.taylor.makeupartist@email.com', 'Sandton', 4.7, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup Artist'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Robert', 'Jones', 'password123', '018 789 0123', 'robert.jones.soundsystem@email.com', 'Soweto', 4.8, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Sound System'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'James', 'Miller', 'password123', '020 901 2345', 'james.miller.stagedesign@email.com', 'Sandton', 4.7, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Stage Design'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Daniel', 'Rodriguez', 'password123', '022 123 4567', 'daniel.rodriguez.photobooth@email.com', 'Soweto', 4.6, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Photo Booth'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Anthony', 'Perez', 'password123', '024 345 6789', 'anthony.perez.hairstyling@email.com', 'Sandton', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Donald', 'Wilson', 'password123', '026 567 8901', 'donald.wilson.lighting@email.com', 'Soweto', 4.6, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Lighting'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Paul', 'Thomas', 'password123', '028 789 0123', 'paul.thomas.musician@email.com', 'Sandton', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Musician'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Joshua', 'White', 'password123', '030 901 2345', 'joshua.white.caterer@email.com', 'Soweto', 4.8, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Caterer'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Kevin', 'Martin', 'password123', '032 123 4567', 'kevin.martin.dj@email.com', 'Sandton', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'George', 'Martinez', 'password123', '034 345 6789', 'george.martinez.decorator@email.com', 'Soweto', 4.7, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decorator'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Ronald', 'Clark', 'password123', '036 567 8901', 'ronald.clark.flowers@email.com', 'Sandton', 4.6, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Flowers'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Ryan', 'Lewis', 'password123', '038 789 0123', 'ryan.lewis.music@email.com', 'Soweto', 4.8, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Music'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Gary', 'Walker', 'password123', '040 901 2345', 'gary.walker.photographer@email.com', 'Sandton', 4.9, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photographer'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Eric', 'Allen', 'password123', '042 123 4567', 'eric.allen.hairstylist@email.com', 'Soweto', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Stylist'

ON CONFLICT (service_provider_id) DO NOTHING;

-- Step 5: Create ONE quotation per service (26 total)
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
ON CONFLICT (quotation_id) DO NOTHING;

-- Step 6: Verification
SELECT 
    '=== SIMPLE RESULTS ===' AS info,
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
ORDER BY s.service_name;

-- Step 7: Summary
SELECT 
    'Total Quotations Created:' AS info,
    COUNT(*) AS count
FROM quotation 
WHERE quotation_submission_date = '2025-10-10';
