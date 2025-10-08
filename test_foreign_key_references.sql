-- Test script to verify all foreign key references are valid
-- This script checks that all bookings reference existing clients, events, and service providers

-- Test 1: Check booking -> client references
SELECT 
    'Booking -> Client References' as test_name,
    COUNT(*) as total_bookings,
    COUNT(c.client_id) as valid_client_references,
    COUNT(*) - COUNT(c.client_id) as invalid_client_references
FROM booking b
LEFT JOIN client c ON b.client_id = c.client_id;

-- Test 2: Check booking -> event references
SELECT 
    'Booking -> Event References' as test_name,
    COUNT(*) as total_bookings,
    COUNT(e.event_id) as valid_event_references,
    COUNT(*) - COUNT(e.event_id) as invalid_event_references
FROM booking b
LEFT JOIN event e ON b.event_id = e.event_id;

-- Test 3: Check quotation -> service_provider references
SELECT 
    'Quotation -> Service Provider References' as test_name,
    COUNT(*) as total_quotations,
    COUNT(sp.service_provider_id) as valid_sp_references,
    COUNT(*) - COUNT(sp.service_provider_id) as invalid_sp_references
FROM quotation q
LEFT JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id;

-- Test 4: Check quotation -> booking references
SELECT 
    'Quotation -> Booking References' as test_name,
    COUNT(*) as total_quotations,
    COUNT(b.booking_id) as valid_booking_references,
    COUNT(*) - COUNT(b.booking_id) as invalid_booking_references
FROM quotation q
LEFT JOIN booking b ON q.booking_id = b.booking_id;

-- Test 5: Check job_cart -> client references
SELECT 
    'Job Cart -> Client References' as test_name,
    COUNT(*) as total_job_carts,
    COUNT(c.client_id) as valid_client_references,
    COUNT(*) - COUNT(c.client_id) as invalid_client_references
FROM job_cart jc
LEFT JOIN client c ON jc.client_id = c.client_id;

-- Test 6: Check job_cart -> service references
SELECT 
    'Job Cart -> Service References' as test_name,
    COUNT(*) as total_job_carts,
    COUNT(s.service_id) as valid_service_references,
    COUNT(*) - COUNT(s.service_id) as invalid_service_references
FROM job_cart jc
LEFT JOIN service s ON jc.service_id = s.service_id;

-- Test 7: Check job_cart -> event references
SELECT 
    'Job Cart -> Event References' as test_name,
    COUNT(*) as total_job_carts,
    COUNT(e.event_id) as valid_event_references,
    COUNT(*) - COUNT(e.event_id) as invalid_event_references
FROM job_cart jc
LEFT JOIN event e ON jc.event_id = e.event_id;

-- Test 8: Show sample data with all valid references
SELECT 
    'Sample Valid Data' as test_name,
    b.booking_id,
    c.client_name || ' ' || c.client_surname as client_name,
    e.event_type,
    e.event_date,
    e.event_location,
    sp.service_provider_name || ' ' || sp.service_provider_surname as service_provider_name,
    q.quotation_price,
    b.booking_status
FROM booking b
JOIN client c ON b.client_id = c.client_id
JOIN event e ON b.event_id = e.event_id
LEFT JOIN quotation q ON b.booking_id = q.booking_id
LEFT JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
ORDER BY b.created_at DESC
LIMIT 5;

-- Test 9: Check for any orphaned records
SELECT 
    'Orphaned Records Check' as test_name,
    'Bookings without valid clients' as record_type,
    COUNT(*) as count
FROM booking b
LEFT JOIN client c ON b.client_id = c.client_id
WHERE c.client_id IS NULL

UNION ALL

SELECT 
    'Orphaned Records Check' as test_name,
    'Bookings without valid events' as record_type,
    COUNT(*) as count
FROM booking b
LEFT JOIN event e ON b.event_id = e.event_id
WHERE e.event_id IS NULL

UNION ALL

SELECT 
    'Orphaned Records Check' as test_name,
    'Quotations without valid service providers' as record_type,
    COUNT(*) as count
FROM quotation q
LEFT JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
WHERE sp.service_provider_id IS NULL

UNION ALL

SELECT 
    'Orphaned Records Check' as test_name,
    'Job carts without valid clients' as record_type,
    COUNT(*) as count
FROM job_cart jc
LEFT JOIN client c ON jc.client_id = c.client_id
WHERE c.client_id IS NULL;



