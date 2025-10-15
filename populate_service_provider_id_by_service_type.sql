-- =====================================================
-- POPULATE SERVICE_PROVIDER_ID BY SERVICE TYPE MATCHING
-- =====================================================
-- This script matches service providers to bookings based on their actual service types
-- Maximum 3 bookings per service provider for diversity

-- =====================================================
-- STEP 1: CHECK SERVICE TYPE RELATIONSHIPS
-- =====================================================

-- Check what service types exist in service_provider table
SELECT 'Service provider service types:' as info, 
       service_provider_service_type, 
       COUNT(*) as provider_count 
FROM service_provider 
WHERE service_provider_service_type IS NOT NULL
GROUP BY service_provider_service_type 
ORDER BY provider_count DESC;

-- Check what service types exist in service table
SELECT 'Available services:' as info, 
       service_type, 
       COUNT(*) as service_count 
FROM service 
GROUP BY service_type 
ORDER BY service_count DESC;

-- =====================================================
-- STEP 2: MATCH BY SERVICE TYPE WITH DIVERSITY
-- =====================================================

-- Update bookings by matching service providers to their service types
WITH service_matches AS (
    -- Get bookings with their associated services
    SELECT DISTINCT
        b.booking_id,
        b.created_at,
        s.service_type,
        s.service_name
    FROM booking b
    JOIN event_service es ON b.event_id = es.event_id
    JOIN service s ON es.service_id = s.service_id
    WHERE b.service_provider_id IS NULL
),
provider_availability AS (
    -- Get available service providers with their current booking counts
    SELECT 
        sp.service_provider_id,
        sp.service_provider_name,
        sp.service_provider_surname,
        sp.service_provider_service_type,
        COALESCE(COUNT(b.booking_id), 0) as current_booking_count
    FROM service_provider sp
    LEFT JOIN booking b ON sp.service_provider_id = b.service_provider_id
    WHERE sp.service_provider_service_type IS NOT NULL
    GROUP BY sp.service_provider_id, sp.service_provider_name, sp.service_provider_surname, sp.service_provider_service_type
),
matched_assignments AS (
    -- Match bookings to service providers by service type
    SELECT 
        sm.booking_id,
        pa.service_provider_id,
        sm.service_type,
        pa.service_provider_name,
        pa.current_booking_count,
        ROW_NUMBER() OVER (
            PARTITION BY sm.booking_id 
            ORDER BY pa.current_booking_count ASC, RANDOM()
        ) as rn
    FROM service_matches sm
    JOIN provider_availability pa ON sm.service_type = pa.service_provider_service_type
    WHERE pa.current_booking_count < 3  -- Maximum 3 bookings per provider
)
-- Update bookings with matched service providers
UPDATE booking 
SET service_provider_id = ma.service_provider_id
FROM matched_assignments ma
WHERE booking.booking_id = ma.booking_id 
AND ma.rn = 1  -- Take the first match for each booking
AND booking.service_provider_id IS NULL;

-- =====================================================
-- STEP 3: VERIFY THE MATCHING
-- =====================================================

-- Show service type matching results
SELECT 'Service type matching results:' as info,
       sp.service_provider_service_type,
       sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
       COUNT(b.booking_id) as booking_count
FROM service_provider sp
LEFT JOIN booking b ON sp.service_provider_id = b.service_provider_id
WHERE sp.service_provider_id IN (
    SELECT DISTINCT service_provider_id 
    FROM booking 
    WHERE service_provider_id IS NOT NULL
)
GROUP BY sp.service_provider_id, sp.service_provider_service_type, sp.service_provider_name, sp.service_provider_surname
ORDER BY sp.service_provider_service_type, booking_count DESC;

-- Show sample matches
SELECT 'Sample service type matches:' as info,
       b.booking_id,
       sp.service_provider_service_type,
       sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
       s.service_type as matched_service_type
FROM booking b
JOIN service_provider sp ON b.service_provider_id = sp.service_provider_id
JOIN event_service es ON b.event_id = es.event_id
JOIN service s ON es.service_id = s.service_id
WHERE b.service_provider_id IS NOT NULL
ORDER BY b.created_at DESC
LIMIT 10;

-- Check remaining unmatched bookings
SELECT 'Remaining unmatched bookings:' as info, 
       COUNT(*) as count 
FROM booking 
WHERE service_provider_id IS NULL;
