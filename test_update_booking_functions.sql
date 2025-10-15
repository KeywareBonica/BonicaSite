-- Test the update booking RPC functions
-- This will help us understand if the update functionality is working

-- 1. Check if the RPC functions exist
SELECT 'Update Booking RPC Functions:' as info,
       routine_name,
       routine_type,
       data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND (routine_name LIKE '%update_booking%' OR routine_name LIKE '%get_%_bookings%')
ORDER BY routine_name;

-- 2. Test get_client_bookings function (if it exists)
-- First, get a sample client ID
SELECT 'Sample Client for Testing:' as info,
       client_id,
       client_name || ' ' || client_surname as client_name,
       client_email
FROM client
ORDER BY client_name
LIMIT 1;

-- 3. Test get_service_provider_bookings function (if it exists)  
-- First, get a sample service provider ID
SELECT 'Sample Service Provider for Testing:' as info,
       service_provider_id,
       service_provider_name || ' ' || service_provider_surname as provider_name,
       service_provider_email
FROM service_provider
ORDER BY service_provider_name
LIMIT 1;

-- 4. Check if there are any bookings at all
SELECT 'Total Bookings Available:' as info,
       COUNT(*) as total_bookings
FROM booking;

-- 5. Check booking statuses
SELECT 'Booking Statuses:' as info,
       booking_status,
       COUNT(*) as count
FROM booking
GROUP BY booking_status
ORDER BY count DESC;

-- 6. Sample booking data with relationships
SELECT 'Sample Booking Data:' as info,
       b.booking_id,
       b.booking_status,
       b.client_id,
       b.service_provider_id,
       c.client_name || ' ' || c.client_surname as client_name,
       sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
       e.event_type,
       e.event_date
FROM booking b
LEFT JOIN client c ON b.client_id = c.client_id
LEFT JOIN service_provider sp ON b.service_provider_id = sp.service_provider_id
LEFT JOIN event e ON b.event_id = e.event_id
ORDER BY b.created_at DESC
LIMIT 5;

-- 7. Check for bookings that could be used for testing updates
SELECT 'Bookings Available for Update Testing:' as info,
       b.booking_id,
       b.booking_status,
       CASE 
           WHEN b.client_id IS NOT NULL AND b.service_provider_id IS NOT NULL THEN 'Both client and SP assigned'
           WHEN b.client_id IS NOT NULL AND b.service_provider_id IS NULL THEN 'Client assigned, SP missing'
           WHEN b.client_id IS NULL AND b.service_provider_id IS NOT NULL THEN 'SP assigned, client missing'
           ELSE 'Both missing'
       END as assignment_status,
       e.event_type,
       e.event_date
FROM booking b
LEFT JOIN event e ON b.event_id = e.event_id
WHERE b.booking_status IN ('active', 'pending', 'confirmed', 'accepted')
ORDER BY b.created_at DESC;
