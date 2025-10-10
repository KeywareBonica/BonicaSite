-- ===============================================
-- Check Current Quotation Count Per Service
-- ===============================================

-- Step 1: Check current quotation count per service
SELECT 
    'Current Quotation Count Per Service' AS info,
    s.service_name,
    COUNT(q.quotation_id) AS current_count,
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

-- Step 2: Check current service provider count per service
SELECT 
    'Service Provider Count Per Service' AS info,
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
ORDER BY s.service_name;
