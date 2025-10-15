-- =====================================================
-- POPULATE BOTH QUOTATION_ID AND SERVICE_PROVIDER_ID
-- =====================================================
-- This script creates quotations and assigns them to bookings
-- Then populates both quotation_id and service_provider_id based on service type matching

-- =====================================================
-- STEP 1: CHECK CURRENT STATE
-- =====================================================

SELECT 'Current booking state:' as info,
       COUNT(*) as total_bookings,
       COUNT(quotation_id) as bookings_with_quotation,
       COUNT(service_provider_id) as bookings_with_sp,
       COUNT(*) - COUNT(quotation_id) as bookings_needing_quotation
FROM booking;

-- =====================================================
-- STEP 2: CREATE QUOTATIONS FOR BOOKINGS
-- =====================================================

-- First, create quotations for bookings that don't have them
-- This creates realistic quotations with random prices and service providers
INSERT INTO quotation (
    service_provider_id,
    job_cart_id,
    quotation_price,
    quotation_details,
    quotation_submission_date,
    quotation_submission_time,
    quotation_status,
    booking_id,
    event_id,
    service_id
)
SELECT DISTINCT
    sp.service_provider_id,
    jc.job_cart_id,
    -- Generate realistic quotation prices based on service type
    CASE 
        WHEN sp.service_provider_service_type ILIKE '%photography%' THEN 
            ROUND((RANDOM() * 5000 + 2000)::numeric, 2)  -- R2000-R7000 for photography
        WHEN sp.service_provider_service_type ILIKE '%dj%' OR sp.service_provider_service_type ILIKE '%music%' THEN 
            ROUND((RANDOM() * 3000 + 1500)::numeric, 2)  -- R1500-R4500 for DJ
        WHEN sp.service_provider_service_type ILIKE '%catering%' OR sp.service_provider_service_type ILIKE '%food%' THEN 
            ROUND((RANDOM() * 4000 + 1000)::numeric, 2)  -- R1000-R5000 for catering
        WHEN sp.service_provider_service_type ILIKE '%decor%' OR sp.service_provider_service_type ILIKE '%flower%' THEN 
            ROUND((RANDOM() * 2500 + 800)::numeric, 2)   -- R800-R3300 for decor
        ELSE 
            ROUND((RANDOM() * 2000 + 1000)::numeric, 2)  -- R1000-R3000 default
    END as quotation_price,
    'Professional ' || sp.service_provider_service_type || ' service for your event' as quotation_details,
    CURRENT_DATE - INTERVAL '7 days' + (RANDOM() * 7)::int as quotation_submission_date,
    CURRENT_TIME as quotation_submission_time,
    'accepted' as quotation_status,
    b.booking_id,
    b.event_id,
    s.service_id
FROM booking b
JOIN event_service es ON b.event_id = es.event_id
JOIN service s ON es.service_id = s.service_id
JOIN service_provider sp ON s.service_type = sp.service_provider_service_type
JOIN job_cart jc ON b.event_id = jc.event_id AND b.client_id = jc.client_id
WHERE b.quotation_id IS NULL
AND sp.service_provider_id IS NOT NULL
-- Limit to avoid too many quotations per booking
AND (b.booking_id, sp.service_provider_id) NOT IN (
    SELECT booking_id, service_provider_id 
    FROM quotation 
    WHERE booking_id IS NOT NULL
)
-- Only create 1-2 quotations per booking for diversity
AND RANDOM() < 0.3  -- 30% chance to create a quotation for each booking-provider combination
LIMIT 100;  -- Create up to 100 quotations

-- =====================================================
-- STEP 3: UPDATE BOOKINGS WITH QUOTATION_ID AND SERVICE_PROVIDER_ID
-- =====================================================

-- Update bookings with quotation_id and service_provider_id from accepted quotations
UPDATE booking 
SET 
    quotation_id = q.quotation_id,
    service_provider_id = q.service_provider_id,
    booking_total_price = q.quotation_price
FROM quotation q
WHERE booking.booking_id = q.booking_id
AND booking.quotation_id IS NULL
AND q.quotation_status = 'accepted';

-- =====================================================
-- STEP 4: VERIFY THE RESULTS
-- =====================================================

-- Check final state
SELECT 'After update - booking state:' as info,
       COUNT(*) as total_bookings,
       COUNT(quotation_id) as bookings_with_quotation,
       COUNT(service_provider_id) as bookings_with_sp,
       COUNT(*) - COUNT(quotation_id) as bookings_still_needing_quotation
FROM booking;

-- Show service provider distribution
SELECT 'Service provider distribution:' as info,
       sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
       sp.service_provider_service_type,
       COUNT(b.booking_id) as booking_count
FROM service_provider sp
LEFT JOIN booking b ON sp.service_provider_id = b.service_provider_id
WHERE b.service_provider_id IS NOT NULL
GROUP BY sp.service_provider_id, sp.service_provider_name, sp.service_provider_surname, sp.service_provider_service_type
ORDER BY booking_count DESC, provider_name;

-- Show sample updated bookings with quotations
SELECT 'Sample updated bookings:' as info,
       b.booking_id,
       b.quotation_id,
       b.service_provider_id,
       sp.service_provider_name,
       sp.service_provider_surname,
       sp.service_provider_service_type,
       q.quotation_price,
       q.quotation_status,
       e.event_type,
       e.event_date
FROM booking b
JOIN service_provider sp ON b.service_provider_id = sp.service_provider_id
JOIN quotation q ON b.quotation_id = q.quotation_id
JOIN event e ON b.event_id = e.event_id
WHERE b.quotation_id IS NOT NULL
ORDER BY b.created_at DESC
LIMIT 10;
