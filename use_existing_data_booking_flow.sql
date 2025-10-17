-- use_existing_data_booking_flow.sql
-- Create booking flow test data using EXISTING database records

-- =====================================================
-- 1. Check what data already exists
-- =====================================================

SELECT '📋 EXISTING CLIENTS:' as section;
SELECT 
    client_id, 
    client_name, 
    client_surname, 
    client_email,
    client_city
FROM public.client 
ORDER BY created_at DESC 
LIMIT 5;

SELECT '📅 EXISTING EVENTS:' as section;
SELECT 
    event_id, 
    event_type, 
    event_date, 
    event_location,
    event_start_time,
    event_end_time
FROM public.event 
ORDER BY created_at DESC 
LIMIT 5;

SELECT '👔 EXISTING SERVICE PROVIDERS:' as section;
SELECT 
    service_provider_id,
    service_provider_name || ' ' || service_provider_surname as name,
    service_provider_service_type,
    service_provider_email,
    service_provider_rating,
    service_id
FROM public.service_provider 
WHERE service_provider_verification = true
ORDER BY service_provider_rating DESC 
LIMIT 10;

SELECT '🛠️ EXISTING SERVICES:' as section;
SELECT 
    service_id,
    service_name,
    service_type,
    service_description
FROM public.service 
ORDER BY service_name
LIMIT 10;

-- =====================================================
-- 2. Create temporary tables with existing IDs
-- =====================================================

-- Store first available client
DROP TABLE IF EXISTS temp_test_client;
CREATE TEMP TABLE temp_test_client AS
SELECT client_id, client_email, client_name, client_surname
FROM public.client 
ORDER BY created_at DESC 
LIMIT 1;

-- Store first available event
DROP TABLE IF EXISTS temp_test_event;
CREATE TEMP TABLE temp_test_event AS
SELECT event_id, event_type, event_date, event_location
FROM public.event 
ORDER BY created_at DESC 
LIMIT 1;

-- Store available service providers (one per service type if possible)
DROP TABLE IF EXISTS temp_test_providers;
CREATE TEMP TABLE temp_test_providers AS
SELECT DISTINCT ON (service_provider_service_type)
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_service_type,
    service_id
FROM public.service_provider 
WHERE service_provider_verification = true
ORDER BY service_provider_service_type, service_provider_rating DESC;

-- =====================================================
-- 3. Display selected test data
-- =====================================================

SELECT '✅ SELECTED TEST DATA:' as section;

SELECT 
    'Client' as type,
    client_name || ' ' || client_surname as name,
    client_email as email,
    client_id::text as id
FROM temp_test_client;

SELECT 
    'Event' as type,
    event_type as name,
    event_date::text || ' at ' || event_location as details,
    event_id::text as id
FROM temp_test_event;

SELECT 
    'Service Provider' as type,
    service_provider_name || ' ' || service_provider_surname as name,
    service_provider_service_type as service_type,
    service_provider_id::text as id
FROM temp_test_providers;

-- =====================================================
-- 4. Create job cart items using existing data
-- =====================================================

SELECT '🛒 Creating Job Cart Items...' as section;

INSERT INTO public.job_cart (
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_status,
    service_id,
    client_id,
    job_cart_min_price,
    job_cart_max_price
)
SELECT 
    te.event_id,
    tp.service_provider_service_type || ' Service' as job_cart_item,
    'Service request for ' || te.event_type || ' on ' || te.event_date::text as job_cart_details,
    'pending' as job_cart_status,
    tp.service_id,
    tc.client_id,
    1000.00 as job_cart_min_price,
    5000.00 as job_cart_max_price
FROM temp_test_client tc
CROSS JOIN temp_test_event te
CROSS JOIN temp_test_providers tp
ON CONFLICT DO NOTHING
RETURNING job_cart_id, job_cart_item, job_cart_status;

-- =====================================================
-- 5. Create quotations using existing data
-- =====================================================

SELECT '💰 Creating Quotations...' as section;

-- Create 3 quotations per job cart (from different providers)
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
    -- Create varied prices within the client's budget (handle NULL prices with defaults)
    CASE 
        WHEN jc.job_cart_min_price IS NOT NULL AND jc.job_cart_max_price IS NOT NULL THEN
            (jc.job_cart_min_price + (jc.job_cart_max_price - jc.job_cart_min_price) * 
                CASE row_num 
                    WHEN 1 THEN 0.5  -- First quotation: 50% of range
                    WHEN 2 THEN 0.7  -- Second quotation: 70% of range
                    WHEN 3 THEN 0.9  -- Third quotation: 90% of range
                    ELSE 0.7
                END
            )::numeric(10,2)
        ELSE
            -- Default prices if job cart doesn't have price range
            CASE sp.service_provider_service_type
                WHEN 'Photography' THEN CASE row_num WHEN 1 THEN 3000.00 WHEN 2 THEN 3500.00 ELSE 4000.00 END
                WHEN 'Catering' THEN CASE row_num WHEN 1 THEN 2000.00 WHEN 2 THEN 2500.00 ELSE 3000.00 END
                WHEN 'Decoration' THEN CASE row_num WHEN 1 THEN 1200.00 WHEN 2 THEN 1500.00 ELSE 1800.00 END
                WHEN 'Entertainment' THEN CASE row_num WHEN 1 THEN 1500.00 WHEN 2 THEN 2000.00 ELSE 2500.00 END
                WHEN 'Music' THEN CASE row_num WHEN 1 THEN 1800.00 WHEN 2 THEN 2200.00 ELSE 2600.00 END
                ELSE CASE row_num WHEN 1 THEN 1500.00 WHEN 2 THEN 2000.00 ELSE 2500.00 END
            END::numeric(10,2)
    END as quotation_price,
    'Professional ' || sp.service_provider_service_type || ' service for your ' || te.event_type as quotation_details,
    'pending' as quotation_status,  -- Client will see PENDING quotations and select one
    jc.service_id,
    jc.event_id
FROM (
    SELECT 
        service_provider_id,
        service_provider_service_type,
        service_id,
        ROW_NUMBER() OVER (PARTITION BY service_id ORDER BY service_provider_rating DESC) as row_num
    FROM public.service_provider
    WHERE service_provider_verification = true
) sp
JOIN public.job_cart jc ON jc.service_id = sp.service_id
JOIN temp_test_event te ON jc.event_id = te.event_id
WHERE sp.row_num <= 3  -- Limit to 3 quotations per service
ON CONFLICT DO NOTHING
RETURNING quotation_id, quotation_price, quotation_status;

-- =====================================================
-- 6. Summary of created test data
-- =====================================================

SELECT '📊 BOOKING FLOW TEST DATA SUMMARY:' as section;

SELECT 
    '✅ Job Cart Items' as item,
    COUNT(*) as count
FROM public.job_cart jc
JOIN temp_test_client tc ON jc.client_id = tc.client_id
JOIN temp_test_event te ON jc.event_id = te.event_id;

SELECT 
    '✅ Quotations Available' as item,
    COUNT(*) as count
FROM public.quotation q
JOIN temp_test_event te ON q.event_id = te.event_id;

SELECT 
    '🎯 Quotations by Service' as summary,
    tp.service_provider_service_type as service_type,
    COUNT(q.quotation_id) as quotation_count,
    AVG(q.quotation_price)::numeric(10,2) as avg_price
FROM public.quotation q
JOIN temp_test_providers tp ON q.service_provider_id = tp.service_provider_id
GROUP BY tp.service_provider_service_type;

-- =====================================================
-- 7. Testing instructions
-- =====================================================

SELECT '
🧪 TESTING INSTRUCTIONS:

1. Review the existing data shown above
2. Job cart items and quotations have been created using REAL existing data
3. Login with the client email shown above
4. Navigate to the event booking flow
5. You should see:
   - Job cart items for the selected event
   - Quotations from real service providers
   - Ability to accept quotations
   - Payment upload functionality

📧 Login using the client email displayed in the results above

✨ This script uses YOUR existing database data, so no hardcoded test values!

' as instructions;

-- Show final test client info for login
SELECT 
    '🔑 USE THIS TO LOGIN:' as info,
    client_email as email,
    client_name || ' ' || client_surname as name
FROM temp_test_client;

