-- Debug job_cart data structure and relationships
-- Run this in your Supabase SQL editor

-- 1. Check job_cart table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'job_cart' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check sample job_cart data with relationships
SELECT 
    jc.job_cart_id,
    jc.client_id,
    jc.service_id,
    jc.event_id,
    jc.booking_id,
    jc.job_cart_status,
    jc.created_at,
    -- Event details
    e.event_type,
    e.event_date,
    e.event_location,
    e.event_start_time,
    e.event_end_time,
    -- Client details
    c.client_name,
    c.client_surname,
    c.client_email,
    -- Service details
    s.service_name,
    s.service_type,
    -- Booking details (if exists)
    b.booking_status,
    b.booking_start_time,
    b.booking_end_time
FROM job_cart jc
LEFT JOIN event e ON jc.event_id = e.event_id
LEFT JOIN client c ON jc.client_id = c.client_id
LEFT JOIN service s ON jc.service_id = s.service_id
LEFT JOIN booking b ON jc.booking_id = b.booking_id
ORDER BY jc.created_at DESC
LIMIT 10;

-- 3. Count job carts by status and relationships
SELECT 
    job_cart_status,
    COUNT(*) as total,
    COUNT(event_id) as has_event_id,
    COUNT(booking_id) as has_booking_id,
    COUNT(CASE WHEN event_id IS NOT NULL AND booking_id IS NOT NULL THEN 1 END) as has_both
FROM job_cart 
GROUP BY job_cart_status;

-- 4. Check if we have any complete job carts with all relationships
SELECT 
    jc.job_cart_id,
    jc.job_cart_status,
    CASE 
        WHEN jc.event_id IS NOT NULL AND jc.booking_id IS NOT NULL THEN 'Complete'
        WHEN jc.event_id IS NOT NULL THEN 'Has Event Only'
        WHEN jc.booking_id IS NOT NULL THEN 'Has Booking Only'
        ELSE 'Incomplete'
    END as relationship_status,
    e.event_type,
    c.client_name,
    s.service_name
FROM job_cart jc
LEFT JOIN event e ON jc.event_id = e.event_id
LEFT JOIN client c ON jc.client_id = c.client_id
LEFT JOIN service s ON jc.service_id = s.service_id
ORDER BY jc.created_at DESC
LIMIT 15;

