-- ===============================================
-- FIX DUPLICATE SERVICE_PROVIDER_ID IN QUOTATIONS
-- ===============================================

-- Step 1: Check current duplicates
SELECT 
    'Current Duplicate Service Provider IDs in Quotations:' AS info,
    service_provider_id,
    COUNT(*) AS quotation_count,
    STRING_AGG(quotation_id::text, ', ') AS quotation_ids
FROM quotation
WHERE quotation_submission_date = '2025-10-10'
GROUP BY service_provider_id
HAVING COUNT(*) > 1
ORDER BY quotation_count DESC;

-- Step 2: Update quotations to have unique service_provider_id
-- For each service, assign different service providers to quotations
WITH quotation_updates AS (
    SELECT 
        q.quotation_id,
        q.service_id,
        q.quotation_price,
        -- Get different service providers for the same service using array indexing
        (SELECT service_provider_id 
         FROM (
             SELECT service_provider_id, 
                    ROW_NUMBER() OVER (ORDER BY service_provider_rating DESC) as rn
             FROM service_provider sp 
             WHERE sp.service_id = q.service_id
         ) ranked_providers
         WHERE rn = CASE 
             WHEN q.quotation_price = (SELECT MIN(quotation_price) FROM quotation WHERE service_id = q.service_id AND quotation_submission_date = '2025-10-10') THEN 1
             WHEN q.quotation_price = (SELECT MAX(quotation_price) FROM quotation WHERE service_id = q.service_id AND quotation_submission_date = '2025-10-10') THEN 3
             ELSE 2
         END
        ) as new_service_provider_id
    FROM quotation q
    WHERE q.quotation_submission_date = '2025-10-10'
    AND q.quotation_status = 'confirmed'
)
UPDATE quotation 
SET service_provider_id = quo.new_service_provider_id
FROM quotation_updates quo
WHERE quotation.quotation_id = quo.quotation_id
AND quo.new_service_provider_id IS NOT NULL;

-- Step 3: If we don't have enough service providers per service, create more
-- First check how many service providers we have per service
SELECT 
    'Service Providers per Service:' AS info,
    s.service_name,
    COUNT(sp.service_provider_id) AS provider_count
FROM service s
LEFT JOIN service_provider sp ON s.service_id = sp.service_id
WHERE s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
)
GROUP BY s.service_name
ORDER BY provider_count DESC;

-- Step 4: Create additional service providers for services that need them
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
-- Add more service providers for services that need them
SELECT
    gen_random_uuid(),
    s.service_id,
    CASE 
        WHEN s.service_name = 'Catering' THEN 'Bongani'
        WHEN s.service_name = 'Photography' THEN 'Lerato'
        WHEN s.service_name = 'Videography' THEN 'Zanele'
        WHEN s.service_name = 'Decoration' THEN 'Samuel'
        WHEN s.service_name = 'DJ Services' THEN 'DJ'
        WHEN s.service_name = 'Venue' THEN 'Michael'
        WHEN s.service_name = 'Security' THEN 'David'
        WHEN s.service_name = 'Event Planning' THEN 'Lisa'
        WHEN s.service_name = 'Florist' THEN 'Michelle'
        WHEN s.service_name = 'MC' THEN 'Christopher'
        WHEN s.service_name = 'Makeup & Hair' THEN 'Matthew'
        WHEN s.service_name = 'Makeup Artist' THEN 'Steven'
        WHEN s.service_name = 'Sound System' THEN 'Andrew'
        WHEN s.service_name = 'Stage Design' THEN 'Brian'
        WHEN s.service_name = 'Photo Booth' THEN 'Timothy'
        WHEN s.service_name = 'Hair Styling' THEN 'Jacob'
        WHEN s.service_name = 'Lighting' THEN 'Nicholas'
        WHEN s.service_name = 'Musician' THEN 'Brandon'
        WHEN s.service_name = 'Caterer' THEN 'Benjamin'
        WHEN s.service_name = 'DJ' THEN 'Logan'
        WHEN s.service_name = 'Decorator' THEN 'Nathan'
        WHEN s.service_name = 'Flowers' THEN 'Jack'
        WHEN s.service_name = 'Music' THEN 'Connor'
        WHEN s.service_name = 'Photographer' THEN 'Adrian'
        WHEN s.service_name = 'Hair Stylist' THEN 'Austin'
        ELSE 'Provider'
    END,
    CASE 
        WHEN s.service_name = 'Catering' THEN 'Mthembu'
        WHEN s.service_name = 'Photography' THEN 'Molefe'
        WHEN s.service_name = 'Videography' THEN 'Khumalo'
        WHEN s.service_name = 'Decoration' THEN 'Van Heerden'
        WHEN s.service_name = 'DJ Services' THEN 'Sbu'
        WHEN s.service_name = 'Venue' THEN 'Smith'
        WHEN s.service_name = 'Security' THEN 'Brown'
        WHEN s.service_name = 'Event Planning' THEN 'Anderson'
        WHEN s.service_name = 'Florist' THEN 'White'
        WHEN s.service_name = 'MC' THEN 'Martinez'
        WHEN s.service_name = 'Makeup & Hair' THEN 'Lee'
        WHEN s.service_name = 'Makeup Artist' THEN 'Anderson'
        WHEN s.service_name = 'Sound System' THEN 'Jackson'
        WHEN s.service_name = 'Stage Design' THEN 'Garcia'
        WHEN s.service_name = 'Photo Booth' THEN 'Robinson'
        WHEN s.service_name = 'Hair Styling' THEN 'Lee'
        WHEN s.service_name = 'Lighting' THEN 'Hall'
        WHEN s.service_name = 'Musician' THEN 'King'
        WHEN s.service_name = 'Caterer' THEN 'Hill'
        WHEN s.service_name = 'DJ' THEN 'Adams'
        WHEN s.service_name = 'Decorator' THEN 'Nelson'
        WHEN s.service_name = 'Flowers' THEN 'Roberts'
        WHEN s.service_name = 'Music' THEN 'Phillips'
        WHEN s.service_name = 'Photographer' THEN 'Evans'
        WHEN s.service_name = 'Hair Stylist' THEN 'Stewart'
        ELSE 'Smith'
    END,
    'password123',
    '082 ' || LPAD((ROW_NUMBER() OVER (ORDER BY s.service_id) + 200)::TEXT, 3, '0') || ' ' || LPAD((ROW_NUMBER() OVER (ORDER BY s.service_id) + 2000)::TEXT, 4, '0'),
    LOWER(REPLACE(s.service_name, ' ', '')) || '.alt.' || ROW_NUMBER() OVER (ORDER BY s.service_id) || '@email.com',
    CASE 
        WHEN ROW_NUMBER() OVER (ORDER BY s.service_id) % 4 = 0 THEN 'Sandton'
        WHEN ROW_NUMBER() OVER (ORDER BY s.service_id) % 4 = 1 THEN 'Rosebank'
        WHEN ROW_NUMBER() OVER (ORDER BY s.service_id) % 4 = 2 THEN 'Soweto'
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
WHERE s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
)
AND NOT EXISTS (
    SELECT 1 FROM service_provider sp 
    WHERE sp.service_id = s.service_id 
    AND sp.service_provider_name = CASE 
        WHEN s.service_name = 'Catering' THEN 'Bongani'
        WHEN s.service_name = 'Photography' THEN 'Lerato'
        WHEN s.service_name = 'Videography' THEN 'Zanele'
        WHEN s.service_name = 'Decoration' THEN 'Samuel'
        WHEN s.service_name = 'DJ Services' THEN 'DJ'
        WHEN s.service_name = 'Venue' THEN 'Michael'
        WHEN s.service_name = 'Security' THEN 'David'
        WHEN s.service_name = 'Event Planning' THEN 'Lisa'
        WHEN s.service_name = 'Florist' THEN 'Michelle'
        WHEN s.service_name = 'MC' THEN 'Christopher'
        WHEN s.service_name = 'Makeup & Hair' THEN 'Matthew'
        WHEN s.service_name = 'Makeup Artist' THEN 'Steven'
        WHEN s.service_name = 'Sound System' THEN 'Andrew'
        WHEN s.service_name = 'Stage Design' THEN 'Brian'
        WHEN s.service_name = 'Photo Booth' THEN 'Timothy'
        WHEN s.service_name = 'Hair Styling' THEN 'Jacob'
        WHEN s.service_name = 'Lighting' THEN 'Nicholas'
        WHEN s.service_name = 'Musician' THEN 'Brandon'
        WHEN s.service_name = 'Caterer' THEN 'Benjamin'
        WHEN s.service_name = 'DJ' THEN 'Logan'
        WHEN s.service_name = 'Decorator' THEN 'Nathan'
        WHEN s.service_name = 'Flowers' THEN 'Jack'
        WHEN s.service_name = 'Music' THEN 'Connor'
        WHEN s.service_name = 'Photographer' THEN 'Adrian'
        WHEN s.service_name = 'Hair Stylist' THEN 'Austin'
        ELSE 'Provider'
    END
)
ON CONFLICT (service_provider_id) DO NOTHING;

-- Step 5: Re-run the quotation update to assign unique service providers
WITH quotation_updates AS (
    SELECT 
        q.quotation_id,
        q.service_id,
        q.quotation_price,
        -- Get different service providers for the same service using array indexing
        (SELECT service_provider_id 
         FROM (
             SELECT service_provider_id, 
                    ROW_NUMBER() OVER (ORDER BY service_provider_rating DESC) as rn
             FROM service_provider sp 
             WHERE sp.service_id = q.service_id
         ) ranked_providers
         WHERE rn = CASE 
             WHEN q.quotation_price = (SELECT MIN(quotation_price) FROM quotation WHERE service_id = q.service_id AND quotation_submission_date = '2025-10-10') THEN 1
             WHEN q.quotation_price = (SELECT MAX(quotation_price) FROM quotation WHERE service_id = q.service_id AND quotation_submission_date = '2025-10-10') THEN 3
             ELSE 2
         END
        ) as new_service_provider_id
    FROM quotation q
    WHERE q.quotation_submission_date = '2025-10-10'
    AND q.quotation_status = 'confirmed'
)
UPDATE quotation 
SET service_provider_id = quo.new_service_provider_id
FROM quotation_updates quo
WHERE quotation.quotation_id = quo.quotation_id
AND quo.new_service_provider_id IS NOT NULL;

-- Step 6: Final verification
SELECT '=== FIX COMPLETE ===' AS info;

-- Check if duplicates are resolved
SELECT 
    'After Fix - Duplicate Service Provider IDs:' AS info,
    service_provider_id,
    COUNT(*) AS quotation_count
FROM quotation
WHERE quotation_submission_date = '2025-10-10'
GROUP BY service_provider_id
HAVING COUNT(*) > 1
ORDER BY quotation_count DESC;

-- Show quotations per service with different providers
SELECT 
    'Quotations per Service with Different Providers:' AS info,
    s.service_name,
    COUNT(q.quotation_id) AS quotation_count,
    COUNT(DISTINCT q.service_provider_id) AS unique_providers,
    STRING_AGG(DISTINCT sp.service_provider_name || ' ' || sp.service_provider_surname, ', ') AS provider_names
FROM service s
LEFT JOIN quotation q ON s.service_id = q.service_id 
    AND q.quotation_submission_date = '2025-10-10'
    AND q.quotation_status = 'confirmed'
LEFT JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
WHERE s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
)
GROUP BY s.service_name
ORDER BY s.service_name;
