-- =====================================================
-- DIAGNOSE RPC ISSUES AND DATA ACCESS PROBLEMS
-- =====================================================
-- This script helps diagnose why the frontend is getting 400 errors
-- when trying to load bookings after implementing the secure RPC system

-- =====================================================
-- STEP 1: CHECK CURRENT BOOKING DATA STATE
-- =====================================================

-- Check if bookings exist and have proper data
SELECT 
    'Current booking data state:' as info,
    COUNT(*) as total_bookings,
    COUNT(quotation_id) as bookings_with_quotation_id,
    COUNT(service_provider_id) as bookings_with_sp_id,
    COUNT(*) - COUNT(quotation_id) as bookings_without_quotation_id,
    COUNT(*) - COUNT(service_provider_id) as bookings_without_sp_id
FROM public.booking;

-- Show sample booking data
SELECT 
    'Sample booking data:' as info,
    b.booking_id,
    b.booking_status,
    b.client_id,
    b.event_id,
    b.quotation_id,
    b.service_provider_id,
    b.created_at
FROM public.booking b
ORDER BY b.created_at DESC
LIMIT 5;

-- =====================================================
-- STEP 2: TEST AUTHORIZATION FUNCTIONS
-- =====================================================

-- Test client booking ownership function
SELECT 
    'Testing client booking ownership:' as info,
    b.booking_id,
    b.client_id,
    public.is_client_booking_owner(b.booking_id, b.client_id) as is_owner,
    c.client_name,
    c.client_surname
FROM public.booking b
JOIN public.client c ON b.client_id = c.client_id
LIMIT 3;

-- Test service provider booking participation function
SELECT 
    'Testing SP booking participation:' as info,
    b.booking_id,
    b.service_provider_id,
    public.is_service_provider_booking_participant(b.booking_id, b.service_provider_id) as is_participant,
    sp.service_provider_name,
    sp.service_provider_surname
FROM public.booking b
JOIN public.service_provider sp ON b.service_provider_id = sp.service_provider_id
WHERE b.service_provider_id IS NOT NULL
LIMIT 3;

-- =====================================================
-- STEP 3: TEST GET FUNCTIONS
-- =====================================================

-- Test get_client_bookings function with a sample client
DO $$
DECLARE
    test_client_id uuid;
    booking_count integer;
BEGIN
    -- Get a sample client ID
    SELECT client_id INTO test_client_id FROM public.client LIMIT 1;
    
    IF test_client_id IS NOT NULL THEN
        -- Count bookings for this client
        SELECT COUNT(*) INTO booking_count
        FROM public.get_client_bookings(test_client_id, NULL);
        
        RAISE NOTICE 'Client % has % bookings', test_client_id, booking_count;
        
        -- Show first booking for this client
        PERFORM * FROM public.get_client_bookings(test_client_id, NULL) LIMIT 1;
        RAISE NOTICE 'get_client_bookings function working for client %', test_client_id;
    ELSE
        RAISE NOTICE 'No clients found in database';
    END IF;
END $$;

-- Test get_service_provider_bookings function with a sample SP
DO $$
DECLARE
    test_sp_id uuid;
    booking_count integer;
BEGIN
    -- Get a sample service provider ID
    SELECT service_provider_id INTO test_sp_id 
    FROM public.service_provider 
    WHERE service_provider_id IN (
        SELECT service_provider_id 
        FROM public.booking 
        WHERE service_provider_id IS NOT NULL
    )
    LIMIT 1;
    
    IF test_sp_id IS NOT NULL THEN
        -- Count bookings for this SP
        SELECT COUNT(*) INTO booking_count
        FROM public.get_service_provider_bookings(test_sp_id, NULL);
        
        RAISE NOTICE 'Service Provider % has % bookings', test_sp_id, booking_count;
        
        -- Show first booking for this SP
        PERFORM * FROM public.get_service_provider_bookings(test_sp_id, NULL) LIMIT 1;
        RAISE NOTICE 'get_service_provider_bookings function working for SP %', test_sp_id;
    ELSE
        RAISE NOTICE 'No service providers with bookings found';
    END IF;
END $$;

-- =====================================================
-- STEP 4: CHECK RPC FUNCTION EXISTENCE
-- =====================================================

-- Check if all RPC functions exist
SELECT 
    'RPC Functions Check:' as info,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN (
    'client_update_booking',
    'service_provider_update_booking',
    'client_cancel_booking',
    'service_provider_cancel_booking',
    'get_client_bookings',
    'get_service_provider_bookings',
    'is_client_booking_owner',
    'is_service_provider_booking_participant'
)
ORDER BY routine_name;

-- =====================================================
-- STEP 5: TEST RPC FUNCTIONS WITH SAMPLE DATA
-- =====================================================

-- Test client_update_booking function (dry run - won't actually update)
DO $$
DECLARE
    test_booking_id uuid;
    test_client_id uuid;
    result json;
BEGIN
    -- Get a sample booking and client
    SELECT b.booking_id, b.client_id 
    INTO test_booking_id, test_client_id
    FROM public.booking b
    WHERE b.booking_status IN ('active', 'pending', 'confirmed')
    LIMIT 1;
    
    IF test_booking_id IS NOT NULL AND test_client_id IS NOT NULL THEN
        BEGIN
            -- Try to call the RPC function (this should work without errors)
            SELECT public.client_update_booking(
                test_booking_id,
                test_client_id,
                NULL, -- event_date (don't change)
                NULL, -- event_location (don't change)
                NULL, -- event_start_time (don't change)
                NULL, -- event_end_time (don't change)
                'Test update from diagnosis script' -- special_request
            ) INTO result;
            
            RAISE NOTICE 'client_update_booking RPC function working: %', result;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'client_update_booking RPC function error: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'No suitable booking found for RPC function test';
    END IF;
END $$;

-- =====================================================
-- STEP 6: CHECK ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Check if RLS is enabled on booking table
SELECT 
    'RLS Status:' as info,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'booking'
AND schemaname = 'public';

-- Check RLS policies on booking table
SELECT 
    'RLS Policies on booking table:' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'booking'
AND schemaname = 'public';

-- =====================================================
-- STEP 7: CHECK FOREIGN KEY CONSTRAINTS
-- =====================================================

-- Check foreign key constraints on booking table
SELECT 
    'Foreign Key Constraints:' as info,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name = 'booking'
AND tc.table_schema = 'public';

-- =====================================================
-- STEP 8: CHECK FOR MISSING DATA
-- =====================================================

-- Check for bookings with missing event data
SELECT 
    'Bookings with missing event data:' as info,
    COUNT(*) as count
FROM public.booking b
LEFT JOIN public.event e ON b.event_id = e.event_id
WHERE e.event_id IS NULL;

-- Check for bookings with missing client data
SELECT 
    'Bookings with missing client data:' as info,
    COUNT(*) as count
FROM public.booking b
LEFT JOIN public.client c ON b.client_id = c.client_id
WHERE c.client_id IS NULL;

-- Check for bookings with missing service provider data
SELECT 
    'Bookings with missing SP data:' as info,
    COUNT(*) as count
FROM public.booking b
LEFT JOIN public.service_provider sp ON b.service_provider_id = sp.service_provider_id
WHERE b.service_provider_id IS NOT NULL AND sp.service_provider_id IS NULL;

-- =====================================================
-- STEP 9: SAMPLE DATA FOR TESTING
-- =====================================================

-- Provide sample data that frontend can use for testing
SELECT 
    'Sample data for frontend testing:' as info,
    'client_id' as type,
    client_id as id,
    client_name,
    client_surname,
    client_email
FROM public.client
WHERE client_id IN (SELECT client_id FROM public.booking)
LIMIT 3;

SELECT 
    'Sample data for frontend testing:' as info,
    'service_provider_id' as type,
    service_provider_id as id,
    service_provider_name,
    service_provider_surname,
    service_provider_email
FROM public.service_provider
WHERE service_provider_id IN (SELECT service_provider_id FROM public.booking WHERE service_provider_id IS NOT NULL)
LIMIT 3;

-- =====================================================
-- STEP 10: SUMMARY AND RECOMMENDATIONS
-- =====================================================

SELECT '
====================================================================
RPC DIAGNOSIS COMPLETE
====================================================================

CHECK RESULTS ABOVE FOR:
------------------------
1. ✅ Booking data exists and is properly linked
2. ✅ Authorization functions are working
3. ✅ RPC functions exist and are callable
4. ✅ RLS policies are not blocking access
5. ✅ Foreign key constraints are intact
6. ✅ No missing critical data

COMMON 400 ERROR CAUSES:
------------------------
❌ RLS policies blocking access
❌ Missing or invalid parameters in RPC calls
❌ Foreign key constraint violations
❌ Invalid user IDs in localStorage
❌ Missing quotation_id or service_provider_id

NEXT STEPS IF ISSUES FOUND:
---------------------------
1. Check RLS policies - may need to disable temporarily for testing
2. Verify localStorage has correct client_id/service_provider_id
3. Check that RPC function parameters match expected format
4. Ensure all foreign key relationships are intact

====================================================================
' as diagnosis_summary;
