-- Generate Comprehensive Booking Data with Proper Foreign Key Links
-- This script creates realistic booking data and links all tables properly

-- Step 1: Check existing data counts
SELECT 'Current Data Counts' as status;
SELECT 'Events' as table_name, COUNT(*) as count FROM event;
SELECT 'Clients' as table_name, COUNT(*) as count FROM client;
SELECT 'Services' as table_name, COUNT(*) as count FROM service;
SELECT 'Service Providers' as table_name, COUNT(*) as count FROM service_provider;
SELECT 'Job Carts' as table_name, COUNT(*) as count FROM job_cart;
SELECT 'Bookings' as table_name, COUNT(*) as count FROM booking;
SELECT 'Quotations' as table_name, COUNT(*) as count FROM quotation;

-- Step 2: Create additional realistic events if needed
INSERT INTO event (event_id, event_type, event_date, event_start_time, event_end_time, event_location)
VALUES 
    (gen_random_uuid(), 'Wedding', '2024-12-28', '14:00:00', '23:00:00', 'The Westcliff Hotel, Johannesburg'),
    (gen_random_uuid(), 'Corporate Conference', '2025-01-08', '08:00:00', '17:00:00', 'Sandton Convention Centre, Johannesburg'),
    (gen_random_uuid(), 'Birthday Celebration', '2025-01-12', '19:00:00', '02:00:00', 'One&Only Cape Town'),
    (gen_random_uuid(), 'Anniversary Dinner', '2025-01-18', '18:30:00', '23:30:00', 'The Saxon Hotel, Johannesburg'),
    (gen_random_uuid(), 'Product Launch', '2025-01-22', '18:00:00', '22:00:00', 'Cape Town International Convention Centre'),
    (gen_random_uuid(), 'Charity Gala', '2025-01-25', '19:00:00', '01:00:00', 'The Table Bay Hotel, Cape Town'),
    (gen_random_uuid(), 'Graduation Party', '2025-01-30', '16:00:00', '22:00:00', 'Durban Exhibition Centre'),
    (gen_random_uuid(), 'Team Building', '2025-02-05', '09:00:00', '16:00:00', 'Sun City Resort, North West'),
    (gen_random_uuid(), 'Valentine Dinner', '2025-02-14', '19:00:00', '23:00:00', 'The Twelve Apostles Hotel, Cape Town'),
    (gen_random_uuid(), 'Easter Celebration', '2025-03-31', '12:00:00', '18:00:00', 'Kruger National Park Lodge')
ON CONFLICT (event_id) DO NOTHING;

-- Step 3: Create additional clients if needed
INSERT INTO client (client_id, client_name, client_surname, client_password, client_contact, client_email, client_city, client_province, client_town, client_street_name, client_house_number, client_postal_code, client_preferred_notification)
VALUES 
    (gen_random_uuid(), 'Jennifer', 'Taylor', '$2a$10$hashedpassword9', '0901234567', 'jennifer.taylor@email.com', 'Johannesburg', 'Gauteng', 'Sandton', 'Rivonia Road', '456', '2196', 'email'),
    (gen_random_uuid(), 'Robert', 'Miller', '$2a$10$hashedpassword10', '0912345678', 'robert.miller@email.com', 'Cape Town', 'Western Cape', 'Cape Town', 'Kloof Street', '789', '8001', 'sms'),
    (gen_random_uuid(), 'Amanda', 'Garcia', '$2a$10$hashedpassword11', '0923456789', 'amanda.garcia@email.com', 'Durban', 'KwaZulu-Natal', 'Durban', 'Florida Road', '321', '4001', 'email'),
    (gen_random_uuid(), 'Christopher', 'Lee', '$2a$10$hashedpassword12', '0934567890', 'christopher.lee@email.com', 'Pretoria', 'Gauteng', 'Pretoria', 'Church Square', '654', '0002', 'email'),
    (gen_random_uuid(), 'Michelle', 'Rodriguez', '$2a$10$hashedpassword13', '0945678901', 'michelle.rodriguez@email.com', 'Port Elizabeth', 'Eastern Cape', 'Port Elizabeth', 'Main Road', '987', '6001', 'sms'),
    (gen_random_uuid(), 'Daniel', 'White', '$2a$10$hashedpassword14', '0956789012', 'daniel.white@email.com', 'Bloemfontein', 'Free State', 'Bloemfontein', 'President Brand Street', '147', '9301', 'email'),
    (gen_random_uuid(), 'Nicole', 'Harris', '$2a$10$hashedpassword15', '0967890123', 'nicole.harris@email.com', 'Polokwane', 'Limpopo', 'Polokwane', 'Thabo Mbeki Street', '258', '0700', 'sms'),
    (gen_random_uuid(), 'Kevin', 'Clark', '$2a$10$hashedpassword16', '0978901234', 'kevin.clark@email.com', 'Nelspruit', 'Mpumalanga', 'Nelspruit', 'Samora Machel Drive', '369', '1200', 'email'),
    (gen_random_uuid(), 'Rachel', 'Lewis', '$2a$10$hashedpassword17', '0989012345', 'rachel.lewis@email.com', 'Kimberley', 'Northern Cape', 'Kimberley', 'Diamond Street', '741', '8301', 'email'),
    (gen_random_uuid(), 'Tyler', 'Walker', '$2a$10$hashedpassword18', '0990123456', 'tyler.walker@email.com', 'Rustenburg', 'North West', 'Rustenburg', 'Platinum Street', '852', '0300', 'sms')
ON CONFLICT (client_email) DO NOTHING;

-- Step 4: Create comprehensive job carts with proper event links
DO $$
DECLARE
    client_record RECORD;
    event_record RECORD;
    service_record RECORD;
    job_cart_counter INTEGER := 0;
    event_counter INTEGER := 0;
BEGIN
    -- Create job carts for each client and event combination
    FOR client_record IN SELECT client_id FROM client LOOP
        event_counter := 0;
        
        -- Each client gets 2-4 events
        FOR event_record IN 
            SELECT event_id, event_type, event_date, event_location 
            FROM event 
            ORDER BY RANDOM() 
            LIMIT (2 + RANDOM() * 3)::INTEGER
        LOOP
            event_counter := event_counter + 1;
            
            -- Create job carts for 1-3 services per event
            FOR service_record IN 
                SELECT service_id, service_name, service_type 
                FROM service 
                ORDER BY RANDOM() 
                LIMIT (1 + RANDOM() * 3)::INTEGER
            LOOP
                job_cart_counter := job_cart_counter + 1;
                
                -- Insert job cart with proper event_id
                INSERT INTO job_cart (
                    job_cart_id, 
                    client_id, 
                    service_id, 
                    event_id, 
                    job_cart_status,
                    job_cart_created_date,
                    job_cart_created_time
                )
                VALUES (
                    gen_random_uuid(),
                    client_record.client_id,
                    service_record.service_id,
                    event_record.event_id,
                    CASE 
                        WHEN RANDOM() > 0.8 THEN 'confirmed'
                        WHEN RANDOM() > 0.6 THEN 'pending'
                        WHEN RANDOM() > 0.3 THEN 'available'
                        ELSE 'draft'
                    END,
                    event_record.event_date - INTERVAL (7 + RANDOM() * 30)::INTEGER || ' days',
                    (CURRENT_TIME + (RANDOM() * INTERVAL '8 hours'))
                )
                ON CONFLICT (job_cart_id) DO NOTHING;
            END LOOP;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Created % job carts across % events', job_cart_counter, event_counter;
END $$;

-- Step 5: Create comprehensive bookings
DO $$
DECLARE
    event_record RECORD;
    client_record RECORD;
    booking_counter INTEGER := 0;
BEGIN
    -- Create bookings for each event
    FOR event_record IN 
        SELECT event_id, event_type, event_date, event_location, event_start_time, event_end_time
        FROM event 
        ORDER BY event_date
    LOOP
        -- Get a random client for this booking
        SELECT client_id INTO client_record FROM client ORDER BY RANDOM() LIMIT 1;
        
        booking_counter := booking_counter + 1;
        
        -- Create booking
        INSERT INTO booking (
            booking_id,
            client_id,
            event_id,
            booking_date,
            booking_status,
            booking_min_price,
            booking_max_price,
            booking_location,
            booking_special_requests
        )
        VALUES (
            gen_random_uuid(),
            client_record.client_id,
            event_record.event_id,
            event_record.event_date,
            CASE 
                WHEN RANDOM() > 0.7 THEN 'confirmed'
                WHEN RANDOM() > 0.4 THEN 'pending'
                WHEN RANDOM() > 0.2 THEN 'draft'
                ELSE 'cancelled'
            END,
            (1000 + RANDOM() * 3000)::NUMERIC(10,2),
            (4000 + RANDOM() * 8000)::NUMERIC(10,2),
            event_record.event_location,
            CASE 
                WHEN RANDOM() > 0.8 THEN 'Special dietary requirements needed'
                WHEN RANDOM() > 0.6 THEN 'Outdoor event - weather backup plan required'
                WHEN RANDOM() > 0.4 THEN 'Accessibility requirements for elderly guests'
                WHEN RANDOM() > 0.2 THEN 'Live music performance requested'
                ELSE NULL
            END
        )
        ON CONFLICT (booking_id) DO NOTHING;
    END LOOP;
    
    RAISE NOTICE 'Created % bookings', booking_counter;
END $$;

-- Step 6: Create event_service relationships
DO $$
DECLARE
    event_record RECORD;
    service_record RECORD;
    relationship_counter INTEGER := 0;
BEGIN
    -- Link events with their services
    FOR event_record IN SELECT event_id, event_type FROM event LOOP
        -- Add 2-5 services per event
        FOR service_record IN 
            SELECT service_id, service_name 
            FROM service 
            ORDER BY RANDOM() 
            LIMIT (2 + RANDOM() * 4)::INTEGER
        LOOP
            relationship_counter := relationship_counter + 1;
            
            INSERT INTO event_service (
                event_service_id,
                event_id,
                service_id,
                event_service_status,
                event_service_notes
            )
            VALUES (
                gen_random_uuid(),
                event_record.event_id,
                service_record.service_id,
                CASE 
                    WHEN RANDOM() > 0.7 THEN 'confirmed'
                    WHEN RANDOM() > 0.4 THEN 'pending'
                    ELSE 'available'
                END,
                'Service for ' || event_record.event_type || ' - ' || service_record.service_name || 
                CASE 
                    WHEN RANDOM() > 0.8 THEN ' (Premium package)'
                    WHEN RANDOM() > 0.6 THEN ' (Standard package)'
                    WHEN RANDOM() > 0.4 THEN ' (Basic package)'
                    ELSE ''
                END
            )
            ON CONFLICT (event_service_id) DO NOTHING;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Created % event-service relationships', relationship_counter;
END $$;

-- Step 7: Create comprehensive quotations
DO $$
DECLARE
    job_cart_record RECORD;
    service_provider_record RECORD;
    booking_record RECORD;
    quotation_counter INTEGER := 0;
BEGIN
    -- Create quotations for job carts
    FOR job_cart_record IN 
        SELECT 
            jc.job_cart_id, 
            jc.client_id, 
            jc.service_id, 
            jc.event_id,
            jc.job_cart_status,
            s.service_name,
            s.service_type,
            e.event_type,
            e.event_date
        FROM job_cart jc
        JOIN service s ON jc.service_id = s.service_id
        JOIN event e ON jc.event_id = e.event_id
        WHERE jc.job_cart_status IN ('pending', 'available', 'confirmed')
    LOOP
        -- Get 2-4 service providers for this service type
        FOR service_provider_record IN 
            SELECT 
                sp.service_provider_id,
                sp.service_provider_name,
                sp.service_provider_surname,
                sp.service_provider_base_rate,
                sp.service_provider_rating
            FROM service_provider sp
            WHERE sp.service_provider_service_type ILIKE '%' || job_cart_record.service_type || '%'
            ORDER BY RANDOM()
            LIMIT (2 + RANDOM() * 3)::INTEGER
        LOOP
            -- Get a random booking for this event
            SELECT booking_id INTO booking_record 
            FROM booking 
            WHERE event_id = job_cart_record.event_id 
            ORDER BY RANDOM() 
            LIMIT 1;
            
            quotation_counter := quotation_counter + 1;
            
            -- Create quotation
            INSERT INTO quotation (
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
                booking_id
            )
            VALUES (
                gen_random_uuid(),
                service_provider_record.service_provider_id,
                job_cart_record.job_cart_id,
                (service_provider_record.service_provider_base_rate * (0.8 + RANDOM() * 0.4))::NUMERIC(10,2),
                'Professional ' || job_cart_record.service_name || ' services for ' || job_cart_record.event_type || 
                ' on ' || job_cart_record.event_date::TEXT || '. ' ||
                CASE 
                    WHEN RANDOM() > 0.8 THEN 'Includes premium equipment and extended coverage.'
                    WHEN RANDOM() > 0.6 THEN 'Standard package with professional service.'
                    WHEN RANDOM() > 0.4 THEN 'Basic package with essential services.'
                    ELSE 'Customized package based on your requirements.'
                END,
                '/quotations/' || LOWER(REPLACE(service_provider_record.service_provider_name, ' ', '_')) || '_' || 
                LOWER(REPLACE(job_cart_record.service_name, ' ', '_')) || '_quote.pdf',
                LOWER(REPLACE(service_provider_record.service_provider_name, ' ', '_')) || '_' || 
                LOWER(REPLACE(job_cart_record.service_name, ' ', '_')) || '_quote.pdf',
                job_cart_record.event_date - INTERVAL (1 + RANDOM() * 14)::INTEGER || ' days',
                (CURRENT_TIME + (RANDOM() * INTERVAL '8 hours')),
                CASE 
                    WHEN RANDOM() > 0.8 THEN 'accepted'
                    WHEN RANDOM() > 0.6 THEN 'pending'
                    WHEN RANDOM() > 0.4 THEN 'submitted'
                    ELSE 'draft'
                END,
                job_cart_record.event_id,
                COALESCE(booking_record.booking_id, NULL)
            )
            ON CONFLICT (quotation_id) DO NOTHING;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Created % quotations', quotation_counter;
END $$;

-- Step 8: Update job cart entries with event_id if they're still NULL
UPDATE job_cart 
SET event_id = (
    SELECT event_id 
    FROM event 
    ORDER BY RANDOM() 
    LIMIT 1
)
WHERE event_id IS NULL;

-- Step 9: Final verification and statistics
SELECT 'Final Data Counts' as status;
SELECT 'Events' as table_name, COUNT(*) as count FROM event;
SELECT 'Clients' as table_name, COUNT(*) as count FROM client;
SELECT 'Services' as table_name, COUNT(*) as count FROM service;
SELECT 'Service Providers' as table_name, COUNT(*) as count FROM service_provider;
SELECT 'Job Carts' as table_name, COUNT(*) as count FROM job_cart;
SELECT 'Job Carts with Event ID' as table_name, COUNT(*) as count FROM job_cart WHERE event_id IS NOT NULL;
SELECT 'Bookings' as table_name, COUNT(*) as count FROM booking;
SELECT 'Event Services' as table_name, COUNT(*) as count FROM event_service;
SELECT 'Quotations' as table_name, COUNT(*) as count FROM quotation;

-- Step 10: Show sample relationships
SELECT 
    'Sample Booking Data' as data_type,
    b.booking_id,
    c.client_name || ' ' || c.client_surname as client_name,
    e.event_type,
    e.event_date,
    b.booking_status,
    b.booking_min_price,
    b.booking_max_price
FROM booking b
JOIN client c ON b.client_id = c.client_id
JOIN event e ON b.event_id = e.event_id
ORDER BY e.event_date DESC
LIMIT 10;

SELECT 
    'Sample Job Cart Data' as data_type,
    jc.job_cart_id,
    c.client_name || ' ' || c.client_surname as client_name,
    s.service_name,
    e.event_type,
    e.event_date,
    jc.job_cart_status
FROM job_cart jc
JOIN client c ON jc.client_id = c.client_id
JOIN service s ON jc.service_id = s.service_id
JOIN event e ON jc.event_id = e.event_id
ORDER BY jc.created_at DESC
LIMIT 10;

SELECT 
    'Sample Quotation Data' as data_type,
    q.quotation_id,
    sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
    s.service_name,
    e.event_type,
    q.quotation_price,
    q.quotation_status
FROM quotation q
JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
JOIN service s ON jc.service_id = s.service_id
JOIN event e ON q.event_id = e.event_id
ORDER BY q.created_at DESC
LIMIT 10;

