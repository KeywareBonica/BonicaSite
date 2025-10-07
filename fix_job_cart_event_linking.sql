-- Fix job_cart and event linking issues
-- This script addresses the timing issue where job carts are created before events

-- 1. First, let's see what we have
SELECT 
    'Current State' as info,
    COUNT(*) as total_job_carts,
    COUNT(event_id) as with_event_id,
    COUNT(booking_id) as with_booking_id,
    COUNT(CASE WHEN event_id IS NOT NULL AND booking_id IS NOT NULL THEN 1 END) as complete
FROM job_cart;

-- 2. Try to link job_carts to events by client and creation time proximity
-- This is a temporary fix for existing data
UPDATE job_cart 
SET event_id = (
    SELECT e.event_id 
    FROM event e 
    WHERE e.client_id = job_cart.client_id 
    AND e.created_at >= job_cart.created_at - INTERVAL '2 hours'
    AND e.created_at <= job_cart.created_at + INTERVAL '2 hours'
    ORDER BY ABS(EXTRACT(EPOCH FROM (e.created_at - job_cart.created_at)))
    LIMIT 1
)
WHERE job_cart.event_id IS NULL
AND EXISTS (
    SELECT 1 FROM event e 
    WHERE e.client_id = job_cart.client_id 
    AND e.created_at >= job_cart.created_at - INTERVAL '2 hours'
    AND e.created_at <= job_cart.created_at + INTERVAL '2 hours'
);

-- 3. Check results
SELECT 
    'After Linking' as info,
    COUNT(*) as total_job_carts,
    COUNT(event_id) as with_event_id,
    COUNT(booking_id) as with_booking_id,
    COUNT(CASE WHEN event_id IS NOT NULL AND booking_id IS NOT NULL THEN 1 END) as complete
FROM job_cart;

-- 4. Show some examples
SELECT 
    jc.job_cart_id,
    jc.job_cart_status,
    jc.event_id,
    jc.booking_id,
    e.event_type,
    e.event_date,
    e.event_location,
    c.client_name,
    s.service_name
FROM job_cart jc
LEFT JOIN event e ON jc.event_id = e.event_id
LEFT JOIN client c ON jc.client_id = c.client_id
LEFT JOIN service s ON jc.service_id = s.service_id
ORDER BY jc.created_at DESC
LIMIT 10;

