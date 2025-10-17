-- automated_realtime_test.sql
-- This script simulates real-time quotation uploads to test the system

-- =====================================================
-- 1. Setup: Get test data
-- =====================================================

-- Get test client and service providers
SELECT '📋 TEST SETUP:' as section;

SELECT 
    'Client' as type,
    client_email as email,
    client_name || ' ' || client_surname as name,
    client_id::text as id
FROM public.client 
ORDER BY created_at DESC 
LIMIT 1;

SELECT 
    'Service Provider 1' as type,
    service_provider_email as email,
    service_provider_name || ' ' || service_provider_surname as name,
    service_provider_id::text as id,
    service_provider_service_type as service_type
FROM public.service_provider 
WHERE service_provider_verification = true
ORDER BY created_at DESC 
LIMIT 1;

-- =====================================================
-- 2. Create fresh job cart for testing
-- =====================================================

SELECT '🛒 Creating fresh job cart for real-time testing...' as section;

-- Create a new job cart specifically for testing
INSERT INTO public.job_cart (
    event_id,
    service_id,
    client_id,
    job_cart_item,
    job_cart_details,
    job_cart_status,
    job_cart_min_price,
    job_cart_max_price
)
SELECT 
    e.event_id,
    s.service_id,
    c.client_id,
    s.service_name || ' Service (Real-Time Test)',
    'Real-time testing for ' || s.service_name || ' service',
    'pending',
    1000.00,
    5000.00
FROM public.client c
CROSS JOIN public.event e  
CROSS JOIN public.service s
WHERE c.client_email = (
    SELECT client_email FROM public.client ORDER BY created_at DESC LIMIT 1
)
AND e.event_type = (
    SELECT event_type FROM public.event ORDER BY created_at DESC LIMIT 1
)
AND s.service_name = (
    SELECT service_name FROM public.service ORDER BY service_name LIMIT 1
)
ORDER BY c.created_at DESC, e.created_at DESC, s.service_name
LIMIT 1
RETURNING job_cart_id, job_cart_item;

-- =====================================================
-- 3. Simulate real-time quotation uploads
-- =====================================================

SELECT '📤 Simulating real-time quotation uploads...' as section;

-- Upload quotation 1 (simulate provider 1)
INSERT INTO public.quotation (
    service_provider_id,
    job_cart_id,
    quotation_price,
    quotation_details,
    quotation_status,
    service_id,
    event_id
)
SELECT 
    sp.service_provider_id,
    jc.job_cart_id,
    2500.00 as quotation_price,
    'Real-time test quotation #1 - ' || sp.service_provider_name || ' ' || sp.service_provider_surname,
    'pending' as quotation_status,
    jc.service_id,
    jc.event_id
FROM public.job_cart jc
JOIN public.service_provider sp ON sp.service_id = jc.service_id
WHERE jc.job_cart_item LIKE '%Real-Time Test%'
AND sp.service_provider_verification = true
ORDER BY sp.service_provider_rating DESC
LIMIT 1
RETURNING quotation_id, quotation_price, quotation_status, quotation_details;

-- Wait a moment (simulate real-time delay)
SELECT '⏳ Simulating 5-second delay between uploads...' as delay_message;
SELECT pg_sleep(5);

-- Upload quotation 2 (simulate provider 2)
INSERT INTO public.quotation (
    service_provider_id,
    job_cart_id,
    quotation_price,
    quotation_details,
    quotation_status,
    service_id,
    event_id
)
SELECT 
    sp.service_provider_id,
    jc.job_cart_id,
    3200.00 as quotation_price,
    'Real-time test quotation #2 - ' || sp.service_provider_name || ' ' || sp.service_provider_surname,
    'pending' as quotation_status,
    jc.service_id,
    jc.event_id
FROM public.job_cart jc
JOIN public.service_provider sp ON sp.service_id = jc.service_id
WHERE jc.job_cart_item LIKE '%Real-Time Test%'
AND sp.service_provider_verification = true
ORDER BY sp.service_provider_rating DESC
LIMIT 1 OFFSET 1  -- Skip the first one to get a different provider
RETURNING quotation_id, quotation_price, quotation_status, quotation_details;

-- Wait another moment
SELECT '⏳ Simulating 3-second delay between uploads...' as delay_message;
SELECT pg_sleep(3);

-- Upload quotation 3 (simulate provider 3)
INSERT INTO public.quotation (
    service_provider_id,
    job_cart_id,
    quotation_price,
    quotation_details,
    quotation_status,
    service_id,
    event_id
)
SELECT 
    sp.service_provider_id,
    jc.job_cart_id,
    2800.00 as quotation_price,
    'Real-time test quotation #3 - ' || sp.service_provider_name || ' ' || sp.service_provider_surname,
    'pending' as quotation_status,
    jc.service_id,
    jc.event_id
FROM public.job_cart jc
JOIN public.service_provider sp ON sp.service_id = jc.service_id
WHERE jc.job_cart_item LIKE '%Real-Time Test%'
AND sp.service_provider_verification = true
ORDER BY sp.service_provider_rating DESC
LIMIT 1 OFFSET 2  -- Skip the first two to get a third provider
RETURNING quotation_id, quotation_price, quotation_status, quotation_details;

-- =====================================================
-- 4. Verify real-time data
-- =====================================================

SELECT '📊 REAL-TIME TEST RESULTS:' as section;

-- Show all quotations that were just created
SELECT 
    'Pending Quotations' as type,
    quotation_id::text as id,
    quotation_price,
    quotation_details,
    quotation_status,
    service_provider_name || ' ' || service_provider_surname as provider
FROM public.quotation q
JOIN public.service_provider sp ON q.service_provider_id = sp.service_provider_id
JOIN public.job_cart jc ON q.job_cart_id = jc.job_cart_id
WHERE jc.job_cart_item LIKE '%Real-Time Test%'
ORDER BY q.created_at ASC;

-- Show job cart details
SELECT 
    'Job Cart Details' as type,
    job_cart_id::text as id,
    job_cart_item,
    job_cart_status,
    job_cart_min_price || ' - ' || job_cart_max_price as price_range
FROM public.job_cart 
WHERE job_cart_item LIKE '%Real-Time Test%';

-- =====================================================
-- 5. Test client acceptance simulation
-- =====================================================

SELECT '✅ Testing client acceptance...' as section;

-- Simulate client accepting the first quotation
UPDATE public.quotation 
SET quotation_status = 'confirmed'
WHERE quotation_id = (
    SELECT quotation_id 
    FROM public.quotation q
    JOIN public.job_cart jc ON q.job_cart_id = jc.job_cart_id
    WHERE jc.job_cart_item LIKE '%Real-Time Test%'
    ORDER BY q.created_at ASC
    LIMIT 1
);

-- Reject other quotations for the same job cart
UPDATE public.quotation 
SET quotation_status = 'rejected'
WHERE job_cart_id = (
    SELECT job_cart_id 
    FROM public.job_cart 
    WHERE job_cart_item LIKE '%Real-Time Test%'
)
AND quotation_status = 'pending';

-- Show final status
SELECT 
    'Final Status After Acceptance' as type,
    quotation_id::text as id,
    quotation_price,
    quotation_status,
    service_provider_name || ' ' || service_provider_surname as provider
FROM public.quotation q
JOIN public.service_provider sp ON q.service_provider_id = sp.service_provider_id
JOIN public.job_cart jc ON q.job_cart_id = jc.job_cart_id
WHERE jc.job_cart_item LIKE '%Real-Time Test%'
ORDER BY q.created_at ASC;

-- =====================================================
-- 6. Test instructions
-- =====================================================

SELECT '
🧪 AUTOMATED REAL-TIME TEST COMPLETE!

📋 What Just Happened:
1. ✅ Created a fresh job cart for testing
2. ✅ Simulated 3 providers uploading quotations with delays
3. ✅ Tested client acceptance (1 confirmed, 2 rejected)
4. ✅ Verified database status changes

🎯 Now Test Your UI:
1. Login as the client email shown above
2. Go to quotation.html
3. Look for job cart with "Real-Time Test" in the name
4. You should see 3 quotations (1 confirmed, 2 rejected)
5. Test the UI interaction with this real data

📊 Expected Results:
- Client should see the confirmed quotation prominently
- Rejected quotations should be disabled/grayed out
- Price breakdown should show the confirmed quotation price
- "Continue to Payment" should be available

🔍 If Issues Found:
- Check browser console for JavaScript errors
- Verify quotation.html loads the test data
- Test the "Select This Quote" functionality
- Verify payment flow works with confirmed quotation

' as instructions;
