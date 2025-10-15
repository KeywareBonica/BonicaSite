-- =====================================================
-- DEBUG: BOOKING-EVENT RELATIONSHIPS
-- =====================================================
-- This script checks if bookings are properly linked to events
-- and if the RPC functions should be returning event details

-- Check booking-event relationships
SELECT 
    'BOOKING-EVENT RELATIONSHIPS' as check_type,
    COUNT(*) as total_bookings,
    COUNT(e.event_id) as bookings_with_events,
    COUNT(*) - COUNT(e.event_id) as bookings_without_events
FROM booking b
LEFT JOIN event e ON b.event_id = e.event_id;

-- Show sample booking data with event details
SELECT 
    'SAMPLE BOOKING DATA' as check_type,
    b.booking_id,
    b.client_id,
    b.event_id,
    b.booking_status,
    e.event_type,
    e.event_date,
    e.event_location,
    e.event_start_time,
    e.event_end_time
FROM booking b
LEFT JOIN event e ON b.event_id = e.event_id
LIMIT 5;

-- Check if RPC functions exist and are callable
SELECT 
    'RPC FUNCTION CHECK' as check_type,
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name IN ('get_client_bookings', 'get_service_provider_bookings')
AND routine_schema = 'public';

-- Test the client bookings RPC with a sample client
SELECT 
    'RPC TEST - CLIENT BOOKINGS' as check_type,
    *
FROM get_client_bookings(
    p_client_id := (SELECT client_id FROM client LIMIT 1),
    p_status_filter := ARRAY['active', 'pending', 'confirmed']
)
LIMIT 3;

-- Test the service provider bookings RPC with a sample service provider
SELECT 
    'RPC TEST - SERVICE PROVIDER BOOKINGS' as check_type,
    *
FROM get_service_provider_bookings(
    p_service_provider_id := (SELECT service_provider_id FROM service_provider LIMIT 1),
    p_status_filter := ARRAY['active', 'pending', 'confirmed', 'accepted']
)
LIMIT 3;

-- Check if there are any bookings without proper event data
SELECT 
    'MISSING EVENT DATA' as check_type,
    b.booking_id,
    b.client_id,
    b.event_id,
    b.booking_status,
    CASE 
        WHEN e.event_id IS NULL THEN 'NO EVENT FOUND'
        WHEN e.event_type IS NULL THEN 'EVENT TYPE MISSING'
        WHEN e.event_date IS NULL THEN 'EVENT DATE MISSING'
        WHEN e.event_location IS NULL THEN 'EVENT LOCATION MISSING'
        ELSE 'ALL EVENT DATA PRESENT'
    END as event_data_status
FROM booking b
LEFT JOIN event e ON b.event_id = e.event_id
WHERE e.event_id IS NULL 
   OR e.event_type IS NULL 
   OR e.event_date IS NULL 
   OR e.event_location IS NULL;

-- Summary of what should be working
SELECT 
    'SUMMARY' as check_type,
    'If RPC functions exist and return data, the issue is in JavaScript processing' as note,
    'If RPC functions return NULL event details, check event table data' as troubleshooting;

-- Final summary message
SELECT 'DEBUG COMPLETE - BOOKING-EVENT RELATIONSHIPS CHECKED' as final_status;
