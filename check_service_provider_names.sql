-- ===============================================
-- CHECK SERVICE PROVIDER NAMES AND SURNAMES
-- ===============================================

-- Step 1: Check current service provider names and surnames
SELECT 
    'Current Service Provider Names:' AS info,
    service_provider_name,
    service_provider_surname,
    COUNT(*) AS count,
    STRING_AGG(service_provider_id::text, ', ') AS provider_ids
FROM service_provider
GROUP BY service_provider_name, service_provider_surname
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- Step 2: Check service providers per service
SELECT 
    'Service Providers per Service:' AS info,
    s.service_name,
    COUNT(sp.service_provider_id) AS provider_count,
    STRING_AGG(DISTINCT sp.service_provider_name || ' ' || sp.service_provider_surname, ', ') AS provider_names
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
ORDER BY s.service_name;

-- Step 3: Sample of duplicate names
SELECT 
    'Sample Duplicate Names:' AS info,
    sp.service_provider_name,
    sp.service_provider_surname,
    sp.service_provider_email,
    s.service_name
FROM service_provider sp
JOIN service s ON sp.service_id = s.service_id
WHERE (sp.service_provider_name, sp.service_provider_surname) IN (
    SELECT service_provider_name, service_provider_surname
    FROM service_provider
    GROUP BY service_provider_name, service_provider_surname
    HAVING COUNT(*) > 1
)
ORDER BY sp.service_provider_name, sp.service_provider_surname
LIMIT 20;
