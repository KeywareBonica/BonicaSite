-- Check job_cart table schema and sample data
-- Run this in your Supabase SQL editor

-- 1. Check the job_cart table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'job_cart' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check sample data in job_cart table
SELECT 
    job_cart_id,
    client_id,
    service_id,
    event_id,
    job_cart_status,
    created_at
FROM job_cart 
LIMIT 10;

-- 3. Check if event_id values exist in event table
SELECT 
    jc.job_cart_id,
    jc.event_id,
    jc.job_cart_status,
    e.event_id as event_exists,
    e.event_type,
    e.event_date,
    e.event_location
FROM job_cart jc
LEFT JOIN event e ON jc.event_id = e.event_id
LIMIT 10;

-- 4. Count job carts with and without event_id
SELECT 
    CASE 
        WHEN event_id IS NULL THEN 'No event_id'
        ELSE 'Has event_id'
    END as event_status,
    COUNT(*) as count
FROM job_cart 
GROUP BY (event_id IS NULL);

-- 5. Check foreign key constraints
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'job_cart'
ORDER BY tc.table_name, kcu.column_name;

