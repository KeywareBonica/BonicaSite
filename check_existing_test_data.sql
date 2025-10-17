-- check_existing_test_data.sql
-- Quick check to see if you already have test data

-- =====================================================
-- Check for existing test data
-- =====================================================

SELECT '👥 CLIENTS:' as section;
SELECT COUNT(*) as total_clients FROM public.client;
SELECT client_id, client_name, client_surname, client_email 
FROM public.client 
ORDER BY created_at DESC 
LIMIT 3;

SELECT '📅 EVENTS:' as section;
SELECT COUNT(*) as total_events FROM public.event;
SELECT event_id, event_type, event_date, event_location 
FROM public.event 
ORDER BY created_at DESC 
LIMIT 3;

SELECT '🛒 JOB CART ITEMS:' as section;
SELECT COUNT(*) as total_job_carts FROM public.job_cart;
SELECT 
    jc.job_cart_id, 
    jc.job_cart_item, 
    jc.job_cart_status,
    jc.job_cart_max_price,
    c.client_email
FROM public.job_cart jc
LEFT JOIN public.client c ON jc.client_id = c.client_id
ORDER BY jc.created_at DESC 
LIMIT 5;

SELECT '💰 QUOTATIONS:' as section;
SELECT COUNT(*) as total_quotations FROM public.quotation;
SELECT 
    q.quotation_id,
    q.quotation_price,
    q.quotation_status,
    sp.service_provider_name || ' ' || sp.service_provider_surname as provider,
    s.service_name
FROM public.quotation q
LEFT JOIN public.service_provider sp ON q.service_provider_id = sp.service_provider_id
LEFT JOIN public.service s ON q.service_id = s.service_id
ORDER BY q.created_at DESC 
LIMIT 5;

SELECT '📋 PENDING QUOTATIONS (READY TO TEST):' as section;
SELECT 
    q.quotation_id,
    q.quotation_price,
    q.quotation_status,
    c.client_email as client,
    e.event_type,
    s.service_name
FROM public.quotation q
LEFT JOIN public.job_cart jc ON q.job_cart_id = jc.job_cart_id
LEFT JOIN public.client c ON jc.client_id = c.client_id
LEFT JOIN public.event e ON q.event_id = e.event_id
LEFT JOIN public.service s ON q.service_id = s.service_id
WHERE q.quotation_status = 'pending'
ORDER BY q.created_at DESC 
LIMIT 10;

SELECT '
✅ IF YOU SEE DATA ABOVE:
   → You already have test data!
   → Just login with one of the client emails shown
   → Start testing the booking flow
   → NO NEED to run use_existing_data_booking_flow.sql

❌ IF COUNTS ARE 0 OR VERY LOW:
   → Run use_existing_data_booking_flow.sql first
   → Then come back and test

' as instructions;

