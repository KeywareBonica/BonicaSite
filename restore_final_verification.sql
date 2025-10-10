-- ===============================================
-- RESTORE QUOTATIONS - FINAL VERIFICATION
-- ===============================================

-- Final verification queries
SELECT '=== RESTORATION COMPLETE ===' AS info;

SELECT 'Total Job Carts:' AS type, COUNT(*) AS count FROM job_cart WHERE job_cart_created_date = '2025-10-10';

SELECT 'Total Service Providers:' AS type, COUNT(*) AS count FROM service_provider;

SELECT 'Total Quotations:' AS type, COUNT(*) AS count FROM quotation WHERE quotation_submission_date = '2025-10-10';

-- Show quotations per service
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
