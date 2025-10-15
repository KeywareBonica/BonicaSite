-- =====================================================
-- POPULATE SERVICE_PROVIDER_ID WITH DIVERSITY
-- =====================================================
-- This script distributes bookings across different service providers
-- Maximum 3 bookings per service provider for diversity

-- =====================================================
-- STEP 1: CHECK CURRENT STATE
-- =====================================================

SELECT 'Current booking distribution:' as info, 
       service_provider_id, 
       COUNT(*) as booking_count 
FROM booking 
WHERE service_provider_id IS NOT NULL 
GROUP BY service_provider_id 
ORDER BY booking_count DESC;

-- =====================================================
-- STEP 2: GET AVAILABLE SERVICE PROVIDERS
-- =====================================================

-- Get all service providers with their current booking counts
WITH sp_booking_counts AS (
    SELECT 
        sp.service_provider_id,
        sp.service_provider_name,
        sp.service_provider_surname,
        COALESCE(COUNT(b.booking_id), 0) as current_booking_count
    FROM service_provider sp
    LEFT JOIN booking b ON sp.service_provider_id = b.service_provider_id
    GROUP BY sp.service_provider_id, sp.service_provider_name, sp.service_provider_surname
),
-- Get bookings that need service_provider_id
bookings_to_update AS (
    SELECT booking_id, created_at
    FROM booking 
    WHERE service_provider_id IS NULL
    ORDER BY created_at DESC
)
-- Update bookings with diverse service provider assignments
UPDATE booking 
SET service_provider_id = (
    SELECT spbc.service_provider_id
    FROM sp_booking_counts spbc
    WHERE spbc.current_booking_count < 3  -- Maximum 3 bookings per provider
    ORDER BY spbc.current_booking_count ASC, RANDOM()  -- Prefer providers with fewer bookings
    LIMIT 1
)
WHERE booking_id IN (
    SELECT booking_id 
    FROM bookings_to_update 
    LIMIT 50  -- Update up to 50 bookings at a time
);

-- =====================================================
-- STEP 3: VERIFY THE DISTRIBUTION
-- =====================================================

SELECT 'After update - Service provider distribution:' as info,
       sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
       COUNT(b.booking_id) as booking_count
FROM service_provider sp
LEFT JOIN booking b ON sp.service_provider_id = b.service_provider_id
GROUP BY sp.service_provider_id, sp.service_provider_name, sp.service_provider_surname
ORDER BY booking_count DESC, provider_name;

-- Check how many bookings still need service_provider_id
SELECT 'Remaining bookings without service_provider_id:' as info, 
       COUNT(*) as count 
FROM booking 
WHERE service_provider_id IS NULL;

-- Show sample of updated bookings
SELECT 'Sample updated bookings:' as info,
       b.booking_id,
       b.service_provider_id,
       sp.service_provider_name,
       sp.service_provider_surname,
       b.booking_status
FROM booking b
JOIN service_provider sp ON b.service_provider_id = sp.service_provider_id
WHERE b.service_provider_id IS NOT NULL
ORDER BY b.created_at DESC
LIMIT 10;
