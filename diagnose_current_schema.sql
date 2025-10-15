-- =====================================================
-- DIAGNOSTIC SCRIPT: Check Current Database State
-- =====================================================
-- Run this to understand your current data structure
-- before applying the fix

-- Test 1: Check booking relationships
SELECT '=== TEST 1: Booking Relationships ===' as test_name;

SELECT 
    COUNT(*) as total_bookings,
    COUNT(quotation_id) as bookings_with_quotation_id,
    COUNT(CASE WHEN quotation_id IS NULL THEN 1 END) as bookings_without_quotation,
    ROUND(COUNT(quotation_id) * 100.0 / COUNT(*), 2) as percentage_with_quotation
FROM public.booking;

-- Test 2: Check if service_provider_id column exists in booking
SELECT '=== TEST 2: Check for service_provider_id column ===' as test_name;

SELECT 
    EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'booking' 
        AND column_name = 'service_provider_id'
    ) as service_provider_id_exists;

-- Test 3: Check circular references
SELECT '=== TEST 3: Circular References ===' as test_name;

SELECT 
    COUNT(*) as total_circular_refs,
    COUNT(CASE WHEN b.quotation_id = q.quotation_id AND q.booking_id = b.booking_id THEN 1 END) as perfect_circular,
    COUNT(CASE WHEN b.quotation_id IS NOT NULL AND q.booking_id IS NULL THEN 1 END) as booking_has_quotation_only,
    COUNT(CASE WHEN b.quotation_id IS NULL AND q.booking_id IS NOT NULL THEN 1 END) as quotation_has_booking_only
FROM public.booking b
LEFT JOIN public.quotation q ON b.quotation_id = q.quotation_id;

-- Test 4: Service provider linkage paths
SELECT '=== TEST 4: How to Find Service Provider ===' as test_name;

SELECT 
    b.booking_id,
    b.quotation_id as booking_quotation_id,
    q1.quotation_id as q1_id,
    q1.service_provider_id as sp_via_booking_quotation,
    q2.quotation_id as q2_id,
    q2.service_provider_id as sp_via_quotation_booking,
    CASE 
        WHEN q1.service_provider_id IS NOT NULL THEN 'Via booking.quotation_id → quotation'
        WHEN q2.service_provider_id IS NOT NULL THEN 'Via quotation.booking_id ← quotation'
        ELSE 'NO SERVICE PROVIDER LINKED'
    END as lookup_method
FROM public.booking b
LEFT JOIN public.quotation q1 ON b.quotation_id = q1.quotation_id
LEFT JOIN public.quotation q2 ON q2.booking_id = b.booking_id AND q2.quotation_status = 'accepted'
LIMIT 10;

-- Test 5: Orphaned bookings (no service provider)
SELECT '=== TEST 5: Orphaned Bookings ===' as test_name;

SELECT 
    COUNT(*) as orphaned_bookings,
    ARRAY_AGG(b.booking_id) as orphaned_booking_ids
FROM public.booking b
LEFT JOIN public.quotation q1 ON b.quotation_id = q1.quotation_id
LEFT JOIN public.quotation q2 ON q2.booking_id = b.booking_id
WHERE q1.service_provider_id IS NULL AND q2.service_provider_id IS NULL;

-- Test 6: Check booking statuses
SELECT '=== TEST 6: Booking Status Distribution ===' as test_name;

SELECT 
    booking_status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM public.booking
GROUP BY booking_status
ORDER BY count DESC;

-- Test 7: Sample booking with full details
SELECT '=== TEST 7: Sample Booking Details ===' as test_name;

SELECT 
    b.booking_id,
    b.booking_status,
    b.client_id,
    c.client_name,
    c.client_surname,
    b.quotation_id,
    q.service_provider_id,
    sp.service_provider_name,
    sp.service_provider_surname,
    e.event_type,
    e.event_date
FROM public.booking b
JOIN public.client c ON b.client_id = c.client_id
LEFT JOIN public.quotation q ON b.quotation_id = q.quotation_id
LEFT JOIN public.service_provider sp ON q.service_provider_id = sp.service_provider_id
LEFT JOIN public.event e ON b.event_id = e.event_id
LIMIT 5;

-- Test 8: Check quotation statuses
SELECT '=== TEST 8: Quotation Status Distribution ===' as test_name;

SELECT 
    quotation_status,
    COUNT(*) as count,
    COUNT(booking_id) as quotations_with_booking_id,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM public.quotation
GROUP BY quotation_status
ORDER BY count DESC;

-- Summary Report
SELECT '
====================================================================
DIAGNOSTIC SUMMARY
====================================================================

Based on the tests above, you should see:

1. How many bookings have quotation_id set
2. Whether service_provider_id column exists in booking table
3. How many circular references exist
4. Different paths to find service provider for a booking
5. Any orphaned bookings without service provider
6. Distribution of booking statuses
7. Sample booking data with full relationship chain
8. Quotation status distribution

NEXT STEPS:
-----------
1. Review the test results
2. Share them with me
3. I will create a custom fix based on your actual data

====================================================================
' as summary;

