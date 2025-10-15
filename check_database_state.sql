-- Check the current database state to understand why no bookings are found
-- Let's see what's actually in the database

-- 1. Check all service providers
SELECT 'All Service Providers:' as info,
       service_provider_id,
       service_provider_name,
       service_provider_surname,
       service_provider_email,
       service_provider_service_type
FROM service_provider
ORDER BY service_provider_name;

-- 2. Check all bookings and their service provider assignments
SELECT 'All Bookings with Service Provider Info:' as info,
       b.booking_id,
       b.booking_status,
       b.service_provider_id,
       sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
       sp.service_provider_email,
       e.event_type,
       e.event_date
FROM booking b
LEFT JOIN service_provider sp ON b.service_provider_id = sp.service_provider_id
LEFT JOIN event e ON b.event_id = e.event_id
ORDER BY b.created_at DESC;

-- 3. Count bookings by service provider
SELECT 'Booking Count by Service Provider:' as info,
       COALESCE(sp.service_provider_name || ' ' || sp.service_provider_surname, 'No Provider Assigned') as provider_name,
       sp.service_provider_email,
       COUNT(b.booking_id) as booking_count
FROM booking b
LEFT JOIN service_provider sp ON b.service_provider_id = sp.service_provider_id
GROUP BY sp.service_provider_id, sp.service_provider_name, sp.service_provider_surname, sp.service_provider_email
ORDER BY booking_count DESC;

-- 4. Check for bookings without service providers
SELECT 'Bookings WITHOUT Service Providers:' as info,
       COUNT(*) as unmatched_count
FROM booking
WHERE service_provider_id IS NULL;

-- 5. Check if there are any bookings at all
SELECT 'Total Bookings in Database:' as info,
       COUNT(*) as total_bookings
FROM booking;

-- 6. Check if there are any service providers at all
SELECT 'Total Service Providers in Database:' as info,
       COUNT(*) as total_providers
FROM service_provider;
