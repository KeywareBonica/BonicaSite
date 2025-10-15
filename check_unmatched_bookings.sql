-- Check what service types are still unmatched
SELECT 'Unmatched booking service types:' as info,
       s.service_type,
       COUNT(*) as unmatched_count
FROM booking b
JOIN event_service es ON b.event_id = es.event_id
JOIN service s ON es.service_id = s.service_id
WHERE b.service_provider_id IS NULL
GROUP BY s.service_type
ORDER BY unmatched_count DESC;

-- Show specific unmatched bookings
SELECT 'Unmatched bookings details:' as info,
       b.booking_id,
       s.service_type,
       e.event_type,
       e.event_date,
       b.booking_status
FROM booking b
JOIN event_service es ON b.event_id = es.event_id
JOIN service s ON es.service_id = s.service_id
JOIN event e ON b.event_id = e.event_id
WHERE b.service_provider_id IS NULL
ORDER BY e.event_date DESC;

-- Check if we have service providers for these service types
SELECT 'Available service providers by type:' as info,
       service_provider_service_type,
       COUNT(*) as provider_count
FROM service_provider
WHERE service_provider_service_type IS NOT NULL
GROUP BY service_provider_service_type
ORDER BY provider_count DESC;
