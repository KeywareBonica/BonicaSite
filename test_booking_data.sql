-- Test booking data for cancel booking pages
-- Run this in your Supabase SQL editor

-- 1. Check if there are any bookings in the database
SELECT 
    COUNT(*) as total_bookings,
    COUNT(CASE WHEN booking_status = 'active' THEN 1 END) as active_bookings,
    COUNT(CASE WHEN booking_status = 'pending' THEN 1 END) as pending_bookings,
    COUNT(CASE WHEN booking_status = 'confirmed' THEN 1 END) as confirmed_bookings
FROM booking;

-- 2. Show sample bookings with client information
SELECT 
    b.booking_id,
    b.booking_status,
    b.booking_date,
    b.booking_total_price,
    c.client_name,
    c.client_surname,
    c.client_email,
    e.event_type,
    e.event_date,
    e.event_location
FROM booking b
LEFT JOIN client c ON b.client_id = c.client_id
LEFT JOIN event e ON b.event_id = e.event_id
ORDER BY b.booking_date DESC
LIMIT 10;

-- 3. Check quotations with service providers
SELECT 
    q.quotation_id,
    q.quotation_status,
    q.quotation_price,
    sp.service_provider_name,
    sp.service_provider_surname,
    sp.service_provider_service_type,
    b.booking_id,
    b.booking_status
FROM quotation q
LEFT JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
LEFT JOIN booking b ON q.booking_id = b.booking_id
WHERE q.quotation_status IN ('accepted', 'pending', 'submitted')
AND b.booking_id IS NOT NULL
ORDER BY q.quotation_submission_date DESC
LIMIT 10;

-- 4. Check if there are any clients in the database
SELECT 
    client_id,
    client_name,
    client_surname,
    client_email,
    created_at
FROM client
ORDER BY created_at DESC
LIMIT 5;

-- 5. Check if there are any service providers in the database
SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_service_type,
    service_provider_verification,
    created_at
FROM service_provider
ORDER BY created_at DESC
LIMIT 5;


