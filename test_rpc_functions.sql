-- Test what the RPC functions actually return
-- This will help us see if the issue is in the RPC functions or JavaScript

-- Test 1: Get a sample client ID and test client bookings RPC
SELECT 'TESTING CLIENT BOOKINGS RPC' as test_type;

-- Get first client ID
SELECT client_id FROM client LIMIT 1;

-- Test the RPC function with that client
SELECT 
    booking_id,
    event_type,
    event_date,
    event_location,
    booking_status
FROM get_client_bookings(
    p_client_id := (SELECT client_id FROM client LIMIT 1),
    p_status_filter := ARRAY['active', 'pending', 'confirmed']
)
LIMIT 3;

-- Test 2: Get a sample service provider ID and test service provider bookings RPC  
SELECT 'TESTING SERVICE PROVIDER BOOKINGS RPC' as test_type;

-- Get first service provider ID
SELECT service_provider_id FROM service_provider LIMIT 1;

-- Test the RPC function with that service provider
SELECT 
    booking_id,
    event_type,
    event_date,
    event_location,
    booking_status,
    client_name,
    client_surname
FROM get_service_provider_bookings(
    p_service_provider_id := (SELECT service_provider_id FROM service_provider LIMIT 1),
    p_status_filter := ARRAY['active', 'pending', 'confirmed', 'accepted']
)
LIMIT 3;