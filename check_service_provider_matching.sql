-- Check if service provider IDs and their service IDs match service names correctly
-- This will help identify why makeup artists might be seeing photography quotations

-- 1. Check service providers and their service types
SELECT 
    sp.service_provider_id,
    sp.service_provider_name,
    sp.service_provider_surname,
    sp.service_provider_service_type,
    COUNT(s.service_id) as service_count
FROM service_provider sp
LEFT JOIN service s ON sp.service_provider_service_type = s.service_type
GROUP BY sp.service_provider_id, sp.service_provider_name, sp.service_provider_surname, sp.service_provider_service_type
ORDER BY sp.service_provider_service_type, sp.service_provider_name;

-- 2. Check services and their types
SELECT 
    s.service_id,
    s.service_name,
    s.service_type,
    s.service_provider_id,
    sp.service_provider_name,
    sp.service_provider_surname,
    sp.service_provider_service_type
FROM service s
JOIN service_provider sp ON s.service_provider_id = sp.service_provider_id
ORDER BY s.service_type, s.service_name;

-- 3. Check for mismatches between service_provider.service_provider_service_type and service.service_type
SELECT 
    sp.service_provider_id,
    sp.service_provider_name,
    sp.service_provider_service_type as provider_service_type,
    s.service_id,
    s.service_name,
    s.service_type as service_service_type,
    CASE 
        WHEN sp.service_provider_service_type != s.service_type THEN 'MISMATCH'
        ELSE 'MATCH'
    END as status
FROM service_provider sp
JOIN service s ON s.service_provider_id = sp.service_provider_id
WHERE sp.service_provider_service_type != s.service_type
ORDER BY sp.service_provider_name;

-- 4. Check job carts and their service relationships
SELECT 
    jc.job_cart_id,
    jc.job_cart_created_date,
    jc.job_cart_status,
    jci.service_id,
    s.service_name,
    s.service_type,
    sp.service_provider_id,
    sp.service_provider_name,
    sp.service_provider_service_type
FROM job_cart jc
JOIN job_cart_item jci ON jc.job_cart_id = jci.job_cart_id
JOIN service s ON jci.service_id = s.service_id
JOIN service_provider sp ON s.service_provider_id = sp.service_provider_id
ORDER BY jc.job_cart_created_date DESC;

-- 5. Check quotations and their service relationships
SELECT 
    q.quotation_id,
    q.service_id,
    q.quotation_status,
    q.quotation_price,
    s.service_name,
    s.service_type,
    sp.service_provider_id,
    sp.service_provider_name,
    sp.service_provider_service_type,
    CASE 
        WHEN sp.service_provider_service_type != s.service_type THEN 'MISMATCH'
        ELSE 'MATCH'
    END as provider_service_match
FROM quotation q
JOIN service s ON q.service_id = s.service_id
JOIN service_provider sp ON s.service_provider_id = sp.service_provider_id
ORDER BY q.quotation_submission_date DESC
LIMIT 20;



