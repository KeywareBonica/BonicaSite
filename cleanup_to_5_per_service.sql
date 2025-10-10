-- ===============================================
-- CLEANUP: KEEP EXACTLY 5 QUOTATIONS PER SERVICE
-- ===============================================

-- Step 1: Check current counts
SELECT 'Current quotation count:' AS info, COUNT(*) AS count FROM quotation WHERE quotation_submission_date = '2025-10-10';
SELECT 'Current job_cart count:' AS info, COUNT(*) AS count FROM job_cart WHERE job_cart_created_date = '2025-10-10';
SELECT 'Current service_provider count:' AS info, COUNT(*) AS count FROM service_provider;

-- Step 2: Delete extra quotations FIRST (keep only 5 per service)
-- This must be done before deleting service providers to avoid foreign key violations
WITH quotations_to_keep AS (
    SELECT 
        q.quotation_id,
        ROW_NUMBER() OVER (PARTITION BY s.service_name ORDER BY q.quotation_price) as rn
    FROM quotation q
    JOIN service s ON q.service_id = s.service_id
    WHERE q.quotation_submission_date = '2025-10-10'
    AND q.quotation_status = 'confirmed'
)
DELETE FROM quotation 
WHERE quotation_id IN (
    SELECT quotation_id 
    FROM quotations_to_keep 
    WHERE rn > 5
);

-- Step 3: Delete extra service providers (keep only 5 per service)
-- Only delete service providers that are NOT referenced in quotations
WITH service_providers_to_keep AS (
    SELECT 
        sp.service_provider_id,
        ROW_NUMBER() OVER (PARTITION BY s.service_name ORDER BY sp.service_provider_rating DESC) as rn
    FROM service_provider sp
    JOIN service s ON sp.service_id = s.service_id
)
DELETE FROM service_provider 
WHERE service_provider_id IN (
    SELECT sp.service_provider_id 
    FROM service_providers_to_keep sp
    WHERE sp.rn > 5
    AND NOT EXISTS (
        SELECT 1 FROM quotation q 
        WHERE q.service_provider_id = sp.service_provider_id
    )
);

-- Step 4: Clean up any remaining orphaned service providers
-- Delete service providers that are not referenced in any quotations
DELETE FROM service_provider 
WHERE service_provider_id NOT IN (
    SELECT DISTINCT service_provider_id 
    FROM quotation 
    WHERE service_provider_id IS NOT NULL
);

-- Step 5: Delete extra job_carts (keep only 1 per service)
WITH job_carts_to_keep AS (
    SELECT 
        jc.job_cart_id,
        ROW_NUMBER() OVER (PARTITION BY s.service_name ORDER BY jc.job_cart_created_time) as rn
    FROM job_cart jc
    JOIN service s ON jc.service_id = s.service_id
    WHERE jc.job_cart_created_date = '2025-10-10'
)
DELETE FROM job_cart 
WHERE job_cart_id IN (
    SELECT job_cart_id 
    FROM job_carts_to_keep 
    WHERE rn > 1
);

-- Step 6: Final verification
SELECT '=== CLEANUP COMPLETE ===' AS info;

SELECT 'Final Job Carts:' AS type, COUNT(*) AS count FROM job_cart WHERE job_cart_created_date = '2025-10-10';

SELECT 'Final Service Providers:' AS type, COUNT(*) AS count FROM service_provider;

SELECT 'Final Quotations:' AS type, COUNT(*) AS count FROM quotation WHERE quotation_submission_date = '2025-10-10';

-- Show quotations per service (should be exactly 5 each)
SELECT 
    'Quotations per Service:' AS info,
    s.service_name,
    COUNT(q.quotation_id) AS quotation_count,
    CASE 
        WHEN COUNT(q.quotation_id) = 5 THEN '✅ Perfect (5 quotations)'
        WHEN COUNT(q.quotation_id) > 5 THEN '⚠️ More than 5'
        WHEN COUNT(q.quotation_id) < 5 THEN '❌ Less than 5'
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
