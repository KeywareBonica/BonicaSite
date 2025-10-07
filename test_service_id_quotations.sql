-- Test script to verify service_id approach works for presentation
-- Run this after executing add_service_id_to_quotation.sql

-- Test 1: Check if service_id column exists and has data
SELECT 
    'Column Check' as test_name,
    COUNT(*) as total_quotations,
    COUNT(service_id) as quotations_with_service_id,
    COUNT(*) - COUNT(service_id) as quotations_missing_service_id
FROM quotation;

-- Test 2: Show quotations with their linked services
SELECT 
    'Service Linking' as test_name,
    q.quotation_id,
    q.quotation_price,
    q.service_id,
    s.service_name,
    sp.service_provider_name
FROM quotation q
LEFT JOIN service s ON q.service_id = s.service_id
LEFT JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
ORDER BY q.created_at DESC
LIMIT 5;

-- Test 3: Test direct service_id filtering (this is what the JavaScript will use)
SELECT 
    'Direct Filtering Test' as test_name,
    q.quotation_id,
    q.quotation_price,
    q.service_id,
    s.service_name,
    sp.service_provider_name
FROM quotation q
LEFT JOIN service s ON q.service_id = s.service_id
LEFT JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
WHERE q.quotation_status = 'confirmed'
AND q.service_id IS NOT NULL
LIMIT 3;

-- Test 4: Show available services for testing
SELECT 
    'Available Services' as test_name,
    service_id,
    service_name,
    service_type
FROM service
ORDER BY service_name;

-- Test 5: Count quotations per service
SELECT 
    'Quotations per Service' as test_name,
    s.service_name,
    COUNT(q.quotation_id) as quotation_count
FROM service s
LEFT JOIN quotation q ON s.service_id = q.service_id
GROUP BY s.service_id, s.service_name
ORDER BY quotation_count DESC;
