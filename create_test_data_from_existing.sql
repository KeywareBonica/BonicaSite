-- create_test_data_from_existing.sql
-- Create test data using existing records from your database

-- =====================================================
-- 1. Check what data we have to work with
-- =====================================================
SELECT '=== EXISTING DATA CHECK ===' as info;

SELECT 'Clients:' as type, COUNT(*) as count FROM public.client;
SELECT 'Events:' as type, COUNT(*) as count FROM public.event;
SELECT 'Services:' as type, COUNT(*) as count FROM public.service;
SELECT 'Service Providers:' as type, COUNT(*) as count FROM public.service_provider;
SELECT 'Job Carts:' as type, COUNT(*) as count FROM public.job_cart;
SELECT 'Quotations:' as type, COUNT(*) as count FROM public.quotation;

-- =====================================================
-- 2. Show sample existing data
-- =====================================================
SELECT '=== SAMPLE CLIENTS ===' as info;
SELECT client_id, client_name, client_surname, client_email FROM public.client LIMIT 3;

SELECT '=== SAMPLE EVENTS ===' as info;
SELECT event_id, event_type, event_date, event_location FROM public.event LIMIT 3;

SELECT '=== SAMPLE SERVICES ===' as info;
SELECT service_id, service_name, service_type FROM public.service LIMIT 3;

SELECT '=== SAMPLE SERVICE PROVIDERS ===' as info;
SELECT service_provider_id, service_provider_name, service_provider_surname, service_provider_email, service_provider_service_type FROM public.service_provider LIMIT 3;

-- =====================================================
-- 3. Create test data using existing records
-- =====================================================

-- Get the first client for testing
DO $$
DECLARE
    test_client_id uuid;
    test_event_id uuid;
    test_service_id uuid;
    test_sp_id uuid;
    test_job_cart_id uuid;
BEGIN
    -- Get first client
    SELECT client_id INTO test_client_id FROM public.client LIMIT 1;
    
    IF test_client_id IS NULL THEN
        RAISE NOTICE 'No clients found. Please create a client first.';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Using client ID: %', test_client_id;
    
    -- Get or create a test event
    SELECT event_id INTO test_event_id FROM public.event LIMIT 1;
    
    IF test_event_id IS NULL THEN
        INSERT INTO public.event (event_type, event_date, event_start_time, event_end_time, event_location)
        VALUES ('Test Event', CURRENT_DATE + INTERVAL '30 days', '10:00:00', '18:00:00', 'Test Location')
        RETURNING event_id INTO test_event_id;
        RAISE NOTICE 'Created test event with ID: %', test_event_id;
    ELSE
        RAISE NOTICE 'Using existing event ID: %', test_event_id;
    END IF;
    
    -- Get first service
    SELECT service_id INTO test_service_id FROM public.service LIMIT 1;
    
    IF test_service_id IS NULL THEN
        INSERT INTO public.service (service_name, service_type, service_description)
        VALUES ('Test Service', 'General', 'Test service for booking flow')
        RETURNING service_id INTO test_service_id;
        RAISE NOTICE 'Created test service with ID: %', test_service_id;
    ELSE
        RAISE NOTICE 'Using existing service ID: %', test_service_id;
    END IF;
    
    -- Get first service provider
    SELECT service_provider_id INTO test_sp_id FROM public.service_provider LIMIT 1;
    
    IF test_sp_id IS NULL THEN
        INSERT INTO public.service_provider (
            service_provider_name, service_provider_surname, service_provider_password,
            service_provider_contactno, service_provider_email, service_provider_location,
            service_provider_base_rate, service_provider_service_type, service_id
        ) VALUES (
            'Test', 'Provider', 'password123',
            '0123456789', 'test.provider@test.com', 'Johannesburg',
            1000.00, 'General', test_service_id
        ) RETURNING service_provider_id INTO test_sp_id;
        RAISE NOTICE 'Created test service provider with ID: %', test_sp_id;
    ELSE
        RAISE NOTICE 'Using existing service provider ID: %', test_sp_id;
    END IF;
    
    -- Create job cart
    INSERT INTO public.job_cart (
        event_id, service_id, client_id, job_cart_item, job_cart_details,
        job_cart_min_price, job_cart_max_price
    ) VALUES (
        test_event_id, test_service_id, test_client_id, 'Test Service Request',
        'Test service for booking flow demonstration', 500.00, 2000.00
    ) RETURNING job_cart_id INTO test_job_cart_id;
    
    RAISE NOTICE 'Created job cart with ID: %', test_job_cart_id;
    
    -- Create test quotations
    INSERT INTO public.quotation (
        service_provider_id, job_cart_id, quotation_price, quotation_details,
        service_id, event_id
    ) VALUES 
        (test_sp_id, test_job_cart_id, 1500.00, 'Standard package for test service', test_service_id, test_event_id),
        (test_sp_id, test_job_cart_id, 1200.00, 'Budget package for test service', test_service_id, test_event_id);
    
    RAISE NOTICE 'Created test quotations';
    
END $$;

-- =====================================================
-- 4. Show what we created
-- =====================================================
SELECT '=== TEST DATA CREATED ===' as info;

SELECT 'Recent Job Carts:' as type;
SELECT jc.job_cart_id, jc.job_cart_item, c.client_name, e.event_type
FROM public.job_cart jc
JOIN public.client c ON jc.client_id = c.client_id
JOIN public.event e ON jc.event_id = e.event_id
ORDER BY jc.created_at DESC
LIMIT 3;

SELECT 'Recent Quotations:' as type;
SELECT q.quotation_id, q.quotation_price, sp.service_provider_name, q.quotation_status
FROM public.quotation q
JOIN public.service_provider sp ON q.service_provider_id = sp.service_provider_id
ORDER BY q.created_at DESC
LIMIT 3;

-- =====================================================
-- 5. Instructions for testing
-- =====================================================
SELECT '
🧪 TESTING INSTRUCTIONS:

1. The test data has been created using existing records from your database
2. To test the booking flow:
   - Login as any existing client
   - Go to quotations page
   - You should see the test quotations we just created
   - Select quotations and proceed to payment
   - Upload proof of payment
3. Check admin dashboard for payment verification

📋 What was created:
- Job cart with test service request
- 2 test quotations for the service
- All linked to existing client, event, and service provider

🎯 Expected Flow:
- Quotations should be visible in quotation page
- Can select quotations and proceed to payment
- Payment upload should create payment records
- Admin can verify payments

' as instructions;





