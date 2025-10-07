-- Fix job_cart and event relationship issues
-- Run this in your Supabase SQL editor

-- 1. First, let's see the current state
SELECT 
    'Current job_cart entries' as info,
    COUNT(*) as total_job_carts,
    COUNT(event_id) as job_carts_with_event_id,
    COUNT(*) - COUNT(event_id) as job_carts_without_event_id
FROM job_cart;

-- 2. Check if we have events that could be linked
SELECT 
    'Current events' as info,
    COUNT(*) as total_events,
    MIN(event_date) as earliest_event,
    MAX(event_date) as latest_event
FROM event;

-- 3. Try to link job_carts to events by client_id and date proximity
-- This is a temporary fix - ideally we should fix the application logic
UPDATE job_cart 
SET event_id = (
    SELECT e.event_id 
    FROM event e 
    WHERE e.client_id = job_cart.client_id 
    AND e.created_at >= job_cart.created_at - INTERVAL '1 hour'
    AND e.created_at <= job_cart.created_at + INTERVAL '1 hour'
    LIMIT 1
)
WHERE job_cart.event_id IS NULL
AND EXISTS (
    SELECT 1 FROM event e 
    WHERE e.client_id = job_cart.client_id 
    AND e.created_at >= job_cart.created_at - INTERVAL '1 hour'
    AND e.created_at <= job_cart.created_at + INTERVAL '1 hour'
);

-- 4. Check the results
SELECT 
    'After linking attempt' as info,
    COUNT(*) as total_job_carts,
    COUNT(event_id) as job_carts_with_event_id,
    COUNT(*) - COUNT(event_id) as job_carts_without_event_id
FROM job_cart;

-- 5. Show some examples of the relationships
SELECT 
    jc.job_cart_id,
    jc.client_id,
    jc.service_id,
    jc.event_id,
    jc.job_cart_status,
    jc.created_at as job_cart_created,
    e.event_type,
    e.event_date,
    e.event_location,
    e.created_at as event_created
FROM job_cart jc
LEFT JOIN event e ON jc.event_id = e.event_id
ORDER BY jc.created_at DESC
LIMIT 10;

