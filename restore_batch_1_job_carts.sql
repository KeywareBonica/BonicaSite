-- ===============================================
-- RESTORE QUOTATIONS - BATCH 1 (Job Carts)
-- ===============================================

-- Step 1: Create job carts for all services (smaller batches)
INSERT INTO job_cart (
    job_cart_id,
    event_id,
    client_id,
    service_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
)
WITH existing_data AS (
    SELECT 
        (SELECT client_id FROM client LIMIT 1) as client_id,
        (SELECT event_id FROM event LIMIT 1) as event_id
)
SELECT
    gen_random_uuid(),
    ed.event_id,
    ed.client_id,
    s.service_id,
    s.service_name,
    s.service_description,
    '2025-10-10',
    '09:00:00'::TIME + (INTERVAL '1 minute' * (ROW_NUMBER() OVER (ORDER BY s.service_id) - 1)),
    'pending',
    NOW()
FROM service s
CROSS JOIN existing_data ed
CROSS JOIN generate_series(1, 50) as gs  -- 50 job carts per service
WHERE s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
)
ON CONFLICT (job_cart_id) DO NOTHING;

-- Verification
SELECT 'Job Carts Created:' AS info, COUNT(*) AS count FROM job_cart WHERE job_cart_created_date = '2025-10-10';
