-- Test the booking RPC functions to ensure they're working
-- This will help diagnose the "No Bookings Found" issue

-- Test 1: Check if RPC functions exist
SELECT 'RPC Functions Check:' as info,
       routine_name,
       routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%booking%'
ORDER BY routine_name;

-- Test 2: Get a sample service provider ID
SELECT 'Sample Service Provider:' as info,
       service_provider_id,
       service_provider_name || ' ' || service_provider_surname as full_name,
       service_provider_email
FROM service_provider
ORDER BY service_provider_name
LIMIT 1;

-- Test 3: Check if that service provider has any bookings
SELECT 'Bookings for Sample Provider:' as info,
       COUNT(*) as booking_count
FROM booking
WHERE service_provider_id = (
    SELECT service_provider_id 
    FROM service_provider 
    ORDER BY service_provider_name 
    LIMIT 1
);

-- Test 4: Sample booking data
SELECT 'Sample Booking Data:' as info,
       b.booking_id,
       b.booking_status,
       b.service_provider_id,
       sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
       e.event_type,
       e.event_date
FROM booking b
LEFT JOIN service_provider sp ON b.service_provider_id = sp.service_provider_id
LEFT JOIN event e ON b.event_id = e.event_id
ORDER BY b.created_at DESC
LIMIT 3;
