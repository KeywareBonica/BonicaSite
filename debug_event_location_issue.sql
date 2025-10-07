-- Debug event_location not showing issue
-- Run this in your Supabase SQL editor

-- 1. Check if event table has event_location column
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'event' 
AND table_schema = 'public'
AND column_name LIKE '%location%'
ORDER BY ordinal_position;

-- 2. Check sample event data to see if event_location is populated
SELECT 
    event_id,
    event_type,
    event_date,
    event_location,
    event_start_time,
    event_end_time,
    created_at
FROM event 
ORDER BY created_at DESC
LIMIT 10;

-- 3. Check job_cart with event relationships
SELECT 
    jc.job_cart_id,
    jc.event_id,
    jc.job_cart_status,
    e.event_type,
    e.event_date,
    e.event_location,
    e.event_start_time,
    e.event_end_time,
    c.client_name,
    s.service_name
FROM job_cart jc
LEFT JOIN event e ON jc.event_id = e.event_id
LEFT JOIN client c ON jc.client_id = c.client_id
LEFT JOIN service s ON jc.service_id = s.service_id
WHERE jc.event_id IS NOT NULL
ORDER BY jc.created_at DESC
LIMIT 10;

-- 4. Check if there are any events with NULL event_location
SELECT 
    COUNT(*) as total_events,
    COUNT(event_location) as events_with_location,
    COUNT(*) - COUNT(event_location) as events_without_location
FROM event;

-- 5. Show events without location
SELECT 
    event_id,
    event_type,
    event_date,
    event_location,
    created_at
FROM event 
WHERE event_location IS NULL
ORDER BY created_at DESC
LIMIT 5;

