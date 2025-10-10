-- Generate new booking data for October 10, 2025
-- This script creates multiple bookings using existing client IDs and event IDs

-- Step 1: Delete existing booking data (as requested)
DELETE FROM booking;

-- Step 2: Generate new booking data for October 10, 2025
INSERT INTO booking (
    booking_id,
    booking_date,
    booking_status,
    booking_special_requests,
    client_id,
    event_id,
    created_at,
    booking_min_price,
    booking_max_price,
    booking_location,
    payment_status
)
VALUES 
    -- Booking 1: Ompilela Mulaudzi - Wedding
    (
        gen_random_uuid(),
        '2025-10-10',
        'confirmed',
        'Outdoor wedding ceremony with garden decorations and live music',
        'ef7f6da4-0b4b-4ca4-ae9d-1a7da8b25f7c',
        '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2',
        NOW(),
        8000.00,
        15000.00,
        'Thohoyandou, Limpopo',
        'pending'
    ),
    
    -- Booking 2: Lerato Mahlangu - Birthday Party
    (
        gen_random_uuid(),
        '2025-10-10',
        'confirmed',
        '50th birthday celebration with catering and entertainment',
        'b4bd1528-107a-41ca-ae45-9af84b5208a1',
        'c755ba4a-d889-49b1-9eb5-1f1dc9340969',
        NOW(),
        3000.00,
        6000.00,
        'Pretoria, Gauteng',
        'pending'
    ),
    
    -- Booking 3: Thabo Nkosi - Matric Dance
    (
        gen_random_uuid(),
        '2025-10-10',
        'confirmed',
        'School matric dance with DJ, photography, and venue decoration',
        'd95d24b0-7541-40e9-80d5-c283532780eb',
        'aa8b7c83-78cd-40cd-bf6e-216b45c5c867',
        NOW(),
        4000.00,
        8000.00,
        'Johannesburg, Gauteng',
        'pending'
    ),
    
    -- Booking 4: Sibongile Dlamini - Wedding
    (
        gen_random_uuid(),
        '2025-10-10',
        'confirmed',
        'Traditional wedding with cultural music and catering for 200 guests',
        '5d97b845-16b8-4a83-a16d-30fb90e0a9a9',
        '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2',
        NOW(),
        12000.00,
        20000.00,
        'Cape Town, Western Cape',
        'pending'
    ),
    
    -- Booking 5: Test Client - Birthday Party
    (
        gen_random_uuid(),
        '2025-10-10',
        'pending',
        'Children''s birthday party with magician and photo booth',
        '123e4567-e89b-12d3-a456-426614174000',
        'c755ba4a-d889-49b1-9eb5-1f1dc9340969',
        NOW(),
        1500.00,
        3000.00,
        'Johannesburg, Gauteng',
        'pending'
    ),
    
    -- Booking 6: Ompilela Mulaudzi - Matric Dance
    (
        gen_random_uuid(),
        '2025-10-10',
        'confirmed',
        'Community matric dance with live band and catering',
        'ef7f6da4-0b4b-4ca4-ae9d-1a7da8b25f7c',
        'aa8b7c83-78cd-40cd-bf6e-216b45c5c867',
        NOW(),
        5000.00,
        10000.00,
        'Thohoyandou, Limpopo',
        'pending'
    ),
    
    -- Booking 7: Lerato Mahlangu - Wedding
    (
        gen_random_uuid(),
        '2025-10-10',
        'confirmed',
        'Intimate wedding ceremony with close family and friends',
        'b4bd1528-107a-41ca-ae45-9af84b5208a1',
        '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2',
        NOW(),
        6000.00,
        12000.00,
        'Pretoria, Gauteng',
        'pending'
    ),
    
    -- Booking 8: Thabo Nkosi - Birthday Party
    (
        gen_random_uuid(),
        '2025-10-10',
        'confirmed',
        'Corporate birthday celebration with formal dinner and entertainment',
        'd95d24b0-7541-40e9-80d5-c283532780eb',
        'c755ba4a-d889-49b1-9eb5-1f1dc9340969',
        NOW(),
        3500.00,
        7000.00,
        'Johannesburg, Gauteng',
        'pending'
    ),
    
    -- Booking 9: Sibongile Dlamini - Matric Dance
    (
        gen_random_uuid(),
        '2025-10-10',
        'confirmed',
        'Elegant matric dance with professional photography and catering',
        '5d97b845-16b8-4a83-a16d-30fb90e0a9a9',
        'aa8b7c83-78cd-40cd-bf6e-216b45c5c867',
        NOW(),
        4500.00,
        9000.00,
        'Cape Town, Western Cape',
        'pending'
    ),
    
    -- Booking 10: Test Client - Wedding
    (
        gen_random_uuid(),
        '2025-10-10',
        'pending',
        'Small wedding ceremony with basic catering and decoration',
        '123e4567-e89b-12d3-a456-426614174000',
        '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2',
        NOW(),
        2000.00,
        4000.00,
        'Johannesburg, Gauteng',
        'pending'
    );

-- Step 3: Verify the new booking data
SELECT 
    'New Bookings Created' as status,
    COUNT(*) as total_bookings,
    COUNT(CASE WHEN booking_status = 'confirmed' THEN 1 END) as confirmed_bookings,
    COUNT(CASE WHEN booking_status = 'pending' THEN 1 END) as pending_bookings
FROM booking;

-- Step 4: Show detailed booking information
SELECT 
    b.booking_id,
    b.booking_date,
    b.booking_status,
    c.client_name || ' ' || c.client_surname as client_name,
    e.event_type,
    b.booking_min_price,
    b.booking_max_price,
    b.booking_location,
    b.payment_status,
    b.booking_special_requests
FROM booking b
JOIN client c ON b.client_id = c.client_id
JOIN event e ON b.event_id = e.event_id
ORDER BY b.booking_date, c.client_name;

-- Step 5: Show booking summary by event type
SELECT 
    e.event_type,
    COUNT(b.booking_id) as booking_count,
    AVG(b.booking_min_price)::numeric(10,2) as avg_min_price,
    AVG(b.booking_max_price)::numeric(10,2) as avg_max_price,
    SUM(b.booking_max_price)::numeric(10,2) as total_potential_revenue
FROM booking b
JOIN event e ON b.event_id = e.event_id
GROUP BY e.event_type
ORDER BY booking_count DESC;

-- Step 6: Show booking summary by client
SELECT 
    c.client_name || ' ' || c.client_surname as client_name,
    COUNT(b.booking_id) as booking_count,
    STRING_AGG(e.event_type, ', ') as event_types,
    SUM(b.booking_max_price)::numeric(10,2) as total_potential_spend
FROM booking b
JOIN client c ON b.client_id = c.client_id
JOIN event e ON b.event_id = e.event_id
GROUP BY c.client_id, c.client_name, c.client_surname
ORDER BY booking_count DESC, total_potential_spend DESC;
