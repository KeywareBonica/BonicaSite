-- Show which service providers have bookings assigned
SELECT 'Service providers with bookings:' as info,
       sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
       sp.service_provider_email,
       sp.service_provider_service_type,
       COUNT(b.booking_id) as booking_count
FROM service_provider sp
LEFT JOIN booking b ON sp.service_provider_id = b.service_provider_id
GROUP BY sp.service_provider_id, sp.service_provider_name, sp.service_provider_surname, sp.service_provider_email, sp.service_provider_service_type
HAVING COUNT(b.booking_id) > 0
ORDER BY booking_count DESC;

-- Show service providers with NO bookings
SELECT 'Service providers with NO bookings:' as info,
       sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
       sp.service_provider_email,
       sp.service_provider_service_type
FROM service_provider sp
LEFT JOIN booking b ON sp.service_provider_id = b.service_provider_id
WHERE b.service_provider_id IS NULL
ORDER BY sp.service_provider_name;

-- Show sample bookings for testing
SELECT 'Sample bookings for testing:' as info,
       b.booking_id,
       sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
       sp.service_provider_email,
       e.event_type,
       e.event_date,
       b.booking_status
FROM booking b
JOIN service_provider sp ON b.service_provider_id = sp.service_provider_id
JOIN event e ON b.event_id = e.event_id
WHERE b.service_provider_id IS NOT NULL
ORDER BY b.created_at DESC
LIMIT 10;
