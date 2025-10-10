-- ===============================================
-- CHECK QUOTATION STATUSES
-- ===============================================

-- Check what quotation statuses exist
SELECT 
    'Quotation Statuses:' AS info,
    quotation_status,
    COUNT(*) AS count
FROM quotation 
WHERE quotation_submission_date = '2025-10-10'
GROUP BY quotation_status
ORDER BY count DESC;

-- Check quotations per service
SELECT 
    'Quotations per Service:' AS info,
    s.service_name,
    COUNT(q.quotation_id) AS quotation_count,
    STRING_AGG(DISTINCT q.quotation_status, ', ') AS statuses
FROM service s
LEFT JOIN quotation q ON s.service_id = q.service_id 
    AND q.quotation_submission_date = '2025-10-10'
WHERE s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
)
GROUP BY s.service_name
ORDER BY s.service_name;

-- Sample quotations to see their data
SELECT 
    'Sample Quotations:' AS info,
    q.quotation_id,
    s.service_name,
    q.quotation_status,
    q.quotation_price,
    sp.service_provider_name || ' ' || sp.service_provider_surname AS provider_name
FROM quotation q
JOIN service s ON q.service_id = s.service_id
JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
WHERE q.quotation_submission_date = '2025-10-10'
ORDER BY s.service_name, q.quotation_price
LIMIT 10;
