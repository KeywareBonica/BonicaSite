-- ===============================================
-- RESTORE QUOTATIONS - BATCH 2 (Service Providers)
-- ===============================================

-- Step 2: Create service providers (smaller batches)
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
-- Create 50 service providers per service
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
        WHEN ROW_NUMBER() OVER (PARTITION BY s.service_id ORDER BY s.service_id) % 4 = 0 THEN 'Sandton'
        WHEN ROW_NUMBER() OVER (PARTITION BY s.service_id ORDER BY s.service_id) % 4 = 1 THEN 'Rosebank'
        WHEN ROW_NUMBER() OVER (PARTITION BY s.service_id ORDER BY s.service_id) % 4 = 2 THEN 'Soweto'
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

-- Verification
SELECT 'Service Providers Created:' AS info, COUNT(*) AS count FROM service_provider;
