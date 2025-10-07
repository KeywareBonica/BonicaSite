-- Create test bookings for client: Dineo Nyoni (ff33d598-3d94-4fc1-9287-8760290651d3)
-- This script creates test events and bookings to test the booking management system

-- First, create test events only if they don't exist
INSERT INTO public.event (
    event_id,
    event_type,
    event_date,
    event_start_time,
    event_end_time,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'Wedding',
    CURRENT_DATE + INTERVAL '7 days',
    '14:00:00',
    '22:00:00',
    now()
WHERE NOT EXISTS (
    SELECT 1 FROM public.event 
    WHERE event_type = 'Wedding' 
    AND event_date = CURRENT_DATE + INTERVAL '7 days'
);

INSERT INTO public.event (
    event_id,
    event_type,
    event_date,
    event_start_time,
    event_end_time,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'Birthday Party',
    CURRENT_DATE + INTERVAL '14 days',
    '18:00:00',
    '23:00:00',
    now()
WHERE NOT EXISTS (
    SELECT 1 FROM public.event 
    WHERE event_type = 'Birthday Party' 
    AND event_date = CURRENT_DATE + INTERVAL '14 days'
);

INSERT INTO public.event (
    event_id,
    event_type,
    event_date,
    event_start_time,
    event_end_time,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'Corporate Event',
    CURRENT_DATE + INTERVAL '21 days',
    '09:00:00',
    '17:00:00',
    now()
WHERE NOT EXISTS (
    SELECT 1 FROM public.event 
    WHERE event_type = 'Corporate Event' 
    AND event_date = CURRENT_DATE + INTERVAL '21 days'
);

-- Get the event IDs we just created
WITH new_events AS (
    SELECT event_id, event_type, event_date 
    FROM public.event 
    WHERE event_type IN ('Wedding', 'Birthday Party', 'Corporate Event')
    ORDER BY created_at DESC 
    LIMIT 3
)
-- Create bookings for the client only if they don't exist
INSERT INTO public.booking (
    booking_id,
    booking_date,
    booking_status,
    booking_special_requests,
    client_id,
    event_id,
    booking_min_price,
    booking_max_price,
    booking_location,
    payment_status,
    created_at
)
SELECT 
    gen_random_uuid() as booking_id,
    CURRENT_DATE + INTERVAL '7 days' as booking_date,
    'confirmed' as booking_status,
    CASE 
        WHEN event_type = 'Wedding' THEN 'Need professional photography and catering for 150 guests'
        WHEN event_type = 'Birthday Party' THEN 'Theme: 25th birthday celebration with DJ and decorations'
        WHEN event_type = 'Corporate Event' THEN 'Company team building event with lunch and activities'
    END as booking_special_requests,
    'ff33d598-3d94-4fc1-9287-8760290651d3' as client_id, -- Dineo Nyoni's client_id
    event_id,
    CASE 
        WHEN event_type = 'Wedding' THEN 25000.00
        WHEN event_type = 'Birthday Party' THEN 8000.00
        WHEN event_type = 'Corporate Event' THEN 15000.00
    END as booking_min_price,
    CASE 
        WHEN event_type = 'Wedding' THEN 45000.00
        WHEN event_type = 'Birthday Party' THEN 15000.00
        WHEN event_type = 'Corporate Event' THEN 25000.00
    END as booking_max_price,
    CASE 
        WHEN event_type = 'Wedding' THEN 'Garden Venue, Johannesburg'
        WHEN event_type = 'Birthday Party' THEN 'Community Hall, Soweto'
        WHEN event_type = 'Corporate Event' THEN 'Sandton Convention Centre'
    END as booking_location,
    'pending' as payment_status,
    now() as created_at
FROM new_events
WHERE NOT EXISTS (
    SELECT 1 FROM public.booking b
    WHERE b.client_id = 'ff33d598-3d94-4fc1-9287-8760290651d3'
    AND b.event_id = new_events.event_id
);

-- Create some job carts for these bookings to test the full flow
WITH booking_events AS (
    SELECT b.booking_id, b.event_id, e.event_type
    FROM public.booking b
    JOIN public.event e ON b.event_id = e.event_id
    WHERE b.client_id = 'ff33d598-3d94-4fc1-9287-8760290651d3'
    ORDER BY b.created_at DESC
    LIMIT 3
),
-- Get some sample services
sample_services AS (
    SELECT service_id, service_name 
    FROM public.service 
    LIMIT 5
)
INSERT INTO public.job_cart (
    job_cart_id,
    event_id,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    service_id,
    client_id,
    created_at
)
SELECT 
    gen_random_uuid() as job_cart_id,
    be.event_id,
    CURRENT_DATE as job_cart_created_date,
    CURRENT_TIME as job_cart_created_time,
    'pending' as job_cart_status,
    ss.service_id,
    'ff33d598-3d94-4fc1-9287-8760290651d3' as client_id,
    now() as created_at
FROM booking_events be
CROSS JOIN sample_services ss
WHERE NOT EXISTS (
    SELECT 1 FROM public.job_cart jc
    WHERE jc.event_id = be.event_id
    AND jc.service_id = ss.service_id
    AND jc.client_id = 'ff33d598-3d94-4fc1-9287-8760290651d3'
);

-- Create some test quotations for these job carts
WITH job_carts_with_details AS (
    SELECT jc.job_cart_id, jc.event_id, e.event_type, s.service_name
    FROM public.job_cart jc
    JOIN public.event e ON jc.event_id = e.event_id
    JOIN public.service s ON jc.service_id = s.service_id
    WHERE jc.client_id = 'ff33d598-3d94-4fc1-9287-8760290651d3'
    ORDER BY jc.created_at DESC
    LIMIT 6
),
-- Get some service providers
sample_providers AS (
    SELECT service_provider_id, service_provider_name, service_provider_surname
    FROM public.service_provider 
    LIMIT 3
)
INSERT INTO public.quotation (
    quotation_id,
    service_provider_id,
    job_cart_id,
    quotation_price,
    quotation_details,
    quotation_file_path,
    quotation_file_name,
    quotation_submission_date,
    quotation_submission_time,
    quotation_status,
    event_id,
    created_at
)
SELECT 
    gen_random_uuid() as quotation_id,
    sp.service_provider_id,
    jc.job_cart_id,
    CASE 
        WHEN jc.service_name LIKE '%Photography%' THEN 8500.00
        WHEN jc.service_name LIKE '%Catering%' THEN 12000.00
        WHEN jc.service_name LIKE '%DJ%' THEN 3500.00
        WHEN jc.service_name LIKE '%Decoration%' THEN 2500.00
        ELSE 5000.00
    END as quotation_price,
    CASE 
        WHEN jc.event_type = 'Wedding' THEN 'Professional wedding ' || jc.service_name || ' package with premium quality'
        WHEN jc.event_type = 'Birthday Party' THEN 'Birthday party ' || jc.service_name || ' with party decorations'
        WHEN jc.event_type = 'Corporate Event' THEN 'Corporate ' || jc.service_name || ' for professional event'
        ELSE 'Standard ' || jc.service_name || ' service package'
    END as quotation_details,
    CASE 
        WHEN jc.service_name LIKE '%Photography%' THEN 'sample-quotations/wedding-photography-quote.pdf'
        WHEN jc.service_name LIKE '%Catering%' THEN 'sample-quotations/catering-menu-quote.pdf'
        ELSE NULL
    END as quotation_file_path,
    CASE 
        WHEN jc.service_name LIKE '%Photography%' THEN 'Wedding Photography Quote.pdf'
        WHEN jc.service_name LIKE '%Catering%' THEN 'Catering Menu & Quote.pdf'
        ELSE NULL
    END as quotation_file_name,
    CURRENT_DATE as quotation_submission_date,
    CURRENT_TIME as quotation_submission_time,
    'confirmed' as quotation_status,
    jc.event_id,
    now() as created_at
FROM job_carts_with_details jc
CROSS JOIN sample_providers sp
WHERE NOT EXISTS (
    SELECT 1 FROM public.quotation q
    WHERE q.job_cart_id = jc.job_cart_id
    AND q.service_provider_id = sp.service_provider_id
)
LIMIT 9; -- Create 3 quotations per service provider

-- Display summary of what was created
SELECT 'Test data created successfully!' as status;

SELECT 
    'BOOKINGS' as data_type,
    COUNT(*) as count,
    string_agg(DISTINCT booking_status, ', ') as statuses
FROM public.booking 
WHERE client_id = 'ff33d598-3d94-4fc1-9287-8760290651d3'

UNION ALL

SELECT 
    'JOB CARTS' as data_type,
    COUNT(*) as count,
    string_agg(DISTINCT job_cart_status, ', ') as statuses
FROM public.job_cart 
WHERE client_id = 'ff33d598-3d94-4fc1-9287-8760290651d3'

UNION ALL

SELECT 
    'QUOTATIONS' as data_type,
    COUNT(*) as count,
    string_agg(DISTINCT quotation_status, ', ') as statuses
FROM public.quotation q
JOIN public.job_cart jc ON q.job_cart_id = jc.job_cart_id
WHERE jc.client_id = 'ff33d598-3d94-4fc1-9287-8760290651d3';

-- Show the created bookings with details
SELECT 
    b.booking_id,
    b.booking_status,
    e.event_type,
    e.event_date,
    b.booking_location,
    b.booking_special_requests,
    b.booking_min_price,
    b.booking_max_price,
    b.payment_status,
    b.created_at
FROM public.booking b
JOIN public.event e ON b.event_id = e.event_id
WHERE b.client_id = 'ff33d598-3d94-4fc1-9287-8760290651d3'
ORDER BY b.created_at DESC;
