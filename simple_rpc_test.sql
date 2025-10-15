-- Very simple RPC test
-- First, let's see if we can call the RPC function at all

-- Get a client ID
SELECT 'Client ID to test:' as info, client_id FROM client LIMIT 1;

-- Try the simplest possible RPC call
SELECT 'Testing RPC function...' as info;

-- Call the RPC function with just the client ID
SELECT booking_id, event_type, event_date, event_location 
FROM get_client_bookings(
    (SELECT client_id FROM client LIMIT 1), 
    NULL
) 
LIMIT 1;

