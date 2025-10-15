-- Quick script to assign bookings to a service provider for testing
-- This will help us test the cancel/update functionality

-- First, let's see what service providers we have
SELECT 'Available Service Providers:' as info,
       service_provider_id,
       service_provider_name || ' ' || service_provider_surname as full_name,
       service_provider_email,
       service_provider_service_type
FROM service_provider
ORDER BY service_provider_name
LIMIT 5;

-- Check which bookings are unmatched
SELECT 'Unmatched Bookings:' as info,
       COUNT(*) as unmatched_count
FROM booking
WHERE service_provider_id IS NULL;

-- Assign 3 random bookings to the first service provider for testing
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
    LIMIT 3
);

-- Verify the assignment
SELECT 'Test Assignments Made:' as info,
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
LIMIT 5;

-- Show remaining unmatched
SELECT 'Remaining Unmatched:' as info,
       COUNT(*) as remaining_count
FROM booking
WHERE service_provider_id IS NULL;
