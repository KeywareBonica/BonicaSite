-- Check specifically for "Dineo Morei" service provider
-- Let's see if this service provider exists and what their situation is

-- 1. Search for service providers with "Dineo" in the name
SELECT 'Service Providers with "Dineo":' as info,
       service_provider_id,
       service_provider_name,
       service_provider_surname,
       service_provider_email,
       service_provider_service_type
FROM service_provider
WHERE service_provider_name ILIKE '%dineo%'
   OR service_provider_surname ILIKE '%dineo%';

-- 2. Search for service providers with "Morei" in the name
SELECT 'Service Providers with "Morei":' as info,
       service_provider_id,
       service_provider_name,
       service_provider_surname,
       service_provider_email,
       service_provider_service_type
FROM service_provider
WHERE service_provider_name ILIKE '%morei%'
   OR service_provider_surname ILIKE '%morei%';

-- 3. Search for exact match "Dineo Morei"
SELECT 'Exact Match "Dineo Morei":' as info,
       service_provider_id,
       service_provider_name,
       service_provider_surname,
       service_provider_email,
       service_provider_service_type
FROM service_provider
WHERE service_provider_name || ' ' || service_provider_surname ILIKE '%dineo morei%';

-- 4. Check if this service provider has any bookings
SELECT 'Bookings for Dineo Morei (if found):' as info,
       b.booking_id,
       b.booking_status,
       b.service_provider_id,
       e.event_type,
       e.event_date,
       b.created_at
FROM booking b
JOIN service_provider sp ON b.service_provider_id = sp.service_provider_id
JOIN event e ON b.event_id = e.event_id
WHERE sp.service_provider_name || ' ' || sp.service_provider_surname ILIKE '%dineo morei%'
ORDER BY b.created_at DESC;

-- 5. Check all service providers to see what names we actually have
SELECT 'All Service Provider Names:' as info,
       service_provider_name,
       service_provider_surname,
       service_provider_name || ' ' || service_provider_surname as full_name,
       service_provider_email
FROM service_provider
ORDER BY service_provider_name;
