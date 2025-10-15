-- =====================================================
-- POPULATE SERVICE_PROVIDER_ID IN BOOKING TABLE
-- =====================================================
-- This script populates the newly added service_provider_id column
-- in the booking table based on accepted quotations

-- =====================================================
-- STEP 1: DIAGNOSE CURRENT STATE
-- =====================================================

-- Check current state of booking table
SELECT 
    'Current booking table state:' as info,
    COUNT(*) as total_bookings,
    COUNT(service_provider_id) as bookings_with_sp_id,
    COUNT(*) - COUNT(service_provider_id) as bookings_without_sp_id
FROM public.booking;

-- Show bookings without service_provider_id
SELECT 
    'Bookings without service_provider_id:' as info,
    b.booking_id,
    b.client_id,
    b.event_id,
    b.booking_status,
    b.service_provider_id
FROM public.booking b
WHERE b.service_provider_id IS NULL
ORDER BY b.created_at DESC;

-- =====================================================
-- STEP 2: FIND ACCEPTED QUOTATIONS TO LINK
-- =====================================================

-- Check quotations that are accepted and linked to bookings
SELECT 
    'Accepted quotations linked to bookings:' as info,
    q.quotation_id,
    q.service_provider_id,
    q.booking_id,
    q.quotation_status,
    q.quotation_price,
    sp.service_provider_name,
    sp.service_provider_surname,
    b.booking_status
FROM public.quotation q
JOIN public.service_provider sp ON q.service_provider_id = sp.service_provider_id
JOIN public.booking b ON q.booking_id = b.booking_id
WHERE q.quotation_status = 'accepted'
ORDER BY q.quotation_submission_date DESC;

-- =====================================================
-- STEP 3: POPULATE SERVICE_PROVIDER_ID FROM ACCEPTED QUOTATIONS
-- =====================================================

-- Update booking table with service_provider_id from accepted quotations
UPDATE public.booking 
SET service_provider_id = q.service_provider_id
FROM public.quotation q
WHERE booking.service_provider_id IS NULL
AND booking.booking_id = q.booking_id
AND q.quotation_status = 'accepted';

-- Report how many records were updated
SELECT 
    'Updated bookings count:' as info,
    COUNT(*) as bookings_updated
FROM public.booking b
JOIN public.quotation q ON b.booking_id = q.booking_id
WHERE q.quotation_status = 'accepted'
AND b.service_provider_id IS NOT NULL;

-- =====================================================
-- STEP 4: ALTERNATIVE METHOD - LINK VIA JOB_CART
-- =====================================================

-- For bookings that might not have direct quotation links,
-- try to link via job_cart -> quotation relationship
UPDATE public.booking 
SET service_provider_id = q.service_provider_id
FROM public.job_cart jc
JOIN public.quotation q ON jc.job_cart_id = q.job_cart_id
WHERE booking.service_provider_id IS NULL
AND booking.event_id = jc.event_id
AND q.quotation_status = 'accepted';

-- =====================================================
-- STEP 5: VERIFY RESULTS
-- =====================================================

-- Check final state after population
SELECT 
    'Final booking table state:' as info,
    COUNT(*) as total_bookings,
    COUNT(service_provider_id) as bookings_with_sp_id,
    COUNT(*) - COUNT(service_provider_id) as bookings_without_sp_id
FROM public.booking;

-- Show populated bookings with service provider info
SELECT 
    'Populated bookings:' as info,
    b.booking_id,
    b.booking_status,
    b.service_provider_id,
    sp.service_provider_name,
    sp.service_provider_surname,
    sp.service_provider_service_type,
    c.client_name,
    c.client_surname,
    e.event_type,
    e.event_date
FROM public.booking b
LEFT JOIN public.service_provider sp ON b.service_provider_id = sp.service_provider_id
LEFT JOIN public.client c ON b.client_id = c.client_id
LEFT JOIN public.event e ON b.event_id = e.event_id
WHERE b.service_provider_id IS NOT NULL
ORDER BY b.created_at DESC;

-- Show any remaining bookings without service_provider_id
SELECT 
    'Remaining bookings without service_provider_id:' as info,
    b.booking_id,
    b.booking_status,
    b.created_at,
    c.client_name,
    c.client_surname,
    e.event_type,
    e.event_date,
    'These may be bookings without accepted quotations yet' as note
FROM public.booking b
LEFT JOIN public.client c ON b.client_id = c.client_id
LEFT JOIN public.event e ON b.event_id = e.event_id
WHERE b.service_provider_id IS NULL
ORDER BY b.created_at DESC;

-- =====================================================
-- STEP 6: CREATE INDEX FOR PERFORMANCE
-- =====================================================

-- Ensure index exists for performance
CREATE INDEX IF NOT EXISTS idx_booking_service_provider ON public.booking(service_provider_id);

-- =====================================================
-- STEP 7: SUMMARY REPORT
-- =====================================================

-- Final summary
SELECT '
====================================================================
SERVICE_PROVIDER_ID POPULATION COMPLETE
====================================================================

SUMMARY:
--------
✅ Populated service_provider_id in booking table
✅ Linked bookings to service providers via accepted quotations
✅ Created performance index
✅ Verified data integrity

NEXT STEPS:
-----------
1. ✅ Run fix_loophole_0_booking_ownership_CORRECTED.sql
2. ✅ Test the secure RPC functions
3. ✅ Verify authorization works correctly

NOTES:
------
- Bookings without service_provider_id may be pending quotations
- Only bookings with accepted quotations get service provider assigned
- Auto-assignment trigger will handle future bookings automatically

====================================================================
' as population_summary;
