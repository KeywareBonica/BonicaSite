-- Assign bookings to service provider "Dineo Morei" for testing
-- This will fix the "No bookings found" issue

-- First, find the service provider ID for "Dineo Morei"
SELECT 'Finding Dineo Morei:' as info,
       service_provider_id,
       service_provider_name,
       service_provider_surname,
       service_provider_email,
       service_provider_service_type
FROM service_provider
WHERE service_provider_name ILIKE '%dineo%' 
   OR service_provider_surname ILIKE '%morei%'
   OR service_provider_name || ' ' || service_provider_surname ILIKE '%dineo morei%';

-- Check how many unmatched bookings we have
SELECT 'Unmatched Bookings Available:' as info,
       COUNT(*) as total_unmatched
FROM booking
WHERE service_provider_id IS NULL;

-- Assign 3 random bookings to Dineo Morei (or first service provider if Dineo not found)
UPDATE booking 
SET service_provider_id = (
    SELECT service_provider_id 
    FROM service_provider 
    WHERE service_provider_name ILIKE '%dineo%' 
       OR service_provider_surname ILIKE '%morei%'
       OR service_provider_name || ' ' || service_provider_surname ILIKE '%dineo morei%'
    LIMIT 1
)
WHERE booking_id IN (
    SELECT booking_id 
    FROM booking 
    WHERE service_provider_id IS NULL 
    ORDER BY RANDOM() 
    LIMIT 3
);

-- If Dineo Morei not found, assign to first available service provider
UPDATE booking 
SET service_provider_id = (
    SELECT service_provider_id 
    FROM service_provider 
    ORDER BY service_provider_name 
    LIMIT 1
)
WHERE booking_id IN (
    SELECT booking_id 
    FROM booking 
    WHERE service_provider_id IS NULL 
    ORDER BY RANDOM() 
    LIMIT 2
)
AND NOT EXISTS (
    SELECT 1 FROM service_provider 
    WHERE service_provider_name ILIKE '%dineo%' 
       OR service_provider_surname ILIKE '%morei%'
);

-- Verify the assignments
SELECT 'Bookings Assigned to Service Providers:' as info,
       sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
       sp.service_provider_email,
       COUNT(b.booking_id) as booking_count
FROM service_provider sp
LEFT JOIN booking b ON sp.service_provider_id = b.service_provider_id
GROUP BY sp.service_provider_id, sp.service_provider_name, sp.service_provider_surname, sp.service_provider_email
HAVING COUNT(b.booking_id) > 0
ORDER BY booking_count DESC;

-- Show specific bookings for testing
SELECT 'Sample Bookings for Testing:' as info,
       b.booking_id,
       sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
       sp.service_provider_email,
       e.event_type,
       e.event_date,
       b.booking_status,
       b.service_provider_id
FROM booking b
JOIN service_provider sp ON b.service_provider_id = sp.service_provider_id
JOIN event e ON b.event_id = e.event_id
WHERE b.service_provider_id IS NOT NULL
ORDER BY b.created_at DESC
LIMIT 5;
