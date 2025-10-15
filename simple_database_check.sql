-- Simple database content check
-- Check what data exists in your tables

-- 1. Check if there are any bookings at all
SELECT 'BOOKINGS COUNT' as check_type, COUNT(*) as count FROM booking;

-- 2. Check if there are any events at all  
SELECT 'EVENTS COUNT' as check_type, COUNT(*) as count FROM event;

-- 3. Check if there are any clients at all
SELECT 'CLIENTS COUNT' as check_type, COUNT(*) as count FROM client;

-- 4. Check if there are any service providers at all
SELECT 'SERVICE PROVIDERS COUNT' as check_type, COUNT(*) as count FROM service_provider;

-- 5. Show sample booking data (if any exists)
SELECT 'SAMPLE BOOKINGS' as check_type, booking_id, client_id, event_id, booking_status FROM booking LIMIT 3;

-- 6. Show sample event data (if any exists)
SELECT 'SAMPLE EVENTS' as check_type, event_id, event_type, event_date, event_location FROM event LIMIT 3;

-- 7. Check if booking table has the service_provider_id column
SELECT 'BOOKING TABLE COLUMNS' as check_type, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'booking' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 8. Check if RPC functions exist
SELECT 'RPC FUNCTIONS' as check_type, routine_name 
FROM information_schema.routines 
WHERE routine_name IN ('get_client_bookings', 'get_service_provider_bookings')
AND routine_schema = 'public';
