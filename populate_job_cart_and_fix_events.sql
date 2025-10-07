-- Populate Job Cart Table and Fix Event ID Links
-- This script ensures all job carts have proper event_id and creates missing events

-- Step 1: First, let's check what data we currently have
SELECT 'Current Job Carts' as table_name, COUNT(*) as count FROM job_cart;
SELECT 'Current Events' as table_name, COUNT(*) as count FROM event;
SELECT 'Current Clients' as table_name, COUNT(*) as count FROM client;
SELECT 'Current Services' as table_name, COUNT(*) as count FROM service;

-- Step 2: Create sample events if they don't exist
INSERT INTO event (event_id, event_type, event_date, event_start_time, event_end_time, event_location)
VALUES 
    (gen_random_uuid(), 'Wedding', '2024-12-15', '14:00:00', '23:00:00', 'Sandton Convention Centre, Johannesburg'),
    (gen_random_uuid(), 'Birthday Party', '2024-12-20', '18:00:00', '02:00:00', 'Cape Town International Convention Centre'),
    (gen_random_uuid(), 'Corporate Event', '2024-12-25', '09:00:00', '17:00:00', 'Midrand Conference Centre, Johannesburg'),
    (gen_random_uuid(), 'Anniversary', '2024-12-30', '19:00:00', '01:00:00', 'Pretoria Country Club'),
    (gen_random_uuid(), 'Graduation Party', '2025-01-05', '16:00:00', '22:00:00', 'Durban Exhibition Centre'),
    (gen_random_uuid(), 'Conference', '2025-01-10', '08:00:00', '18:00:00', 'Cape Town International Convention Centre'),
    (gen_random_uuid(), 'Product Launch', '2025-01-15', '19:00:00', '23:00:00', 'Sandton City, Johannesburg'),
    (gen_random_uuid(), 'Charity Gala', '2025-01-20', '18:30:00', '01:00:00', 'Hyatt Regency, Cape Town'),
    (gen_random_uuid(), 'Team Building', '2025-01-25', '09:00:00', '16:00:00', 'Sun City Resort, North West'),
    (gen_random_uuid(), 'New Year Party', '2025-01-01', '20:00:00', '04:00:00', 'V&A Waterfront, Cape Town')
ON CONFLICT (event_id) DO NOTHING;

-- Step 3: Create sample clients if they don't exist
INSERT INTO client (client_id, client_name, client_surname, client_password, client_contact, client_email, client_city, client_province, client_town, client_street_name, client_house_number, client_postal_code, client_preferred_notification)
VALUES 
    (gen_random_uuid(), 'Sarah', 'Johnson', '$2a$10$hashedpassword1', '0821234567', 'sarah.johnson@email.com', 'Johannesburg', 'Gauteng', 'Sandton', 'Rivonia Road', '123', '2196', 'email'),
    (gen_random_uuid(), 'Michael', 'Brown', '$2a$10$hashedpassword2', '0832345678', 'michael.brown@email.com', 'Cape Town', 'Western Cape', 'Cape Town', 'Long Street', '456', '8001', 'sms'),
    (gen_random_uuid(), 'Emma', 'Wilson', '$2a$10$hashedpassword3', '0843456789', 'emma.wilson@email.com', 'Durban', 'KwaZulu-Natal', 'Durban', 'Florida Road', '789', '4001', 'email'),
    (gen_random_uuid(), 'David', 'Smith', '$2a$10$hashedpassword4', '0854567890', 'david.smith@email.com', 'Pretoria', 'Gauteng', 'Pretoria', 'Church Square', '321', '0002', 'email'),
    (gen_random_uuid(), 'Lisa', 'Davis', '$2a$10$hashedpassword5', '0865678901', 'lisa.davis@email.com', 'Port Elizabeth', 'Eastern Cape', 'Port Elizabeth', 'Main Road', '654', '6001', 'sms'),
    (gen_random_uuid(), 'James', 'Wilson', '$2a$10$hashedpassword6', '0876789012', 'james.wilson@email.com', 'Bloemfontein', 'Free State', 'Bloemfontein', 'President Brand Street', '987', '9301', 'email'),
    (gen_random_uuid(), 'Anna', 'Martinez', '$2a$10$hashedpassword7', '0887890123', 'anna.martinez@email.com', 'Polokwane', 'Limpopo', 'Polokwane', 'Thabo Mbeki Street', '147', '0700', 'sms'),
    (gen_random_uuid(), 'Peter', 'Anderson', '$2a$10$hashedpassword8', '0898901234', 'peter.anderson@email.com', 'Nelspruit', 'Mpumalanga', 'Nelspruit', 'Samora Machel Drive', '258', '1200', 'email')
ON CONFLICT (client_email) DO NOTHING;

-- Step 4: Create sample services if they don't exist
INSERT INTO service (service_id, service_name, service_type, service_description)
VALUES 
    (gen_random_uuid(), 'Photography', 'photography', 'Professional event photography services'),
    (gen_random_uuid(), 'Videography', 'videography', 'Professional event videography services'),
    (gen_random_uuid(), 'DJ Services', 'entertainment', 'Professional DJ and music services'),
    (gen_random_uuid(), 'Catering', 'catering', 'Professional catering and food services'),
    (gen_random_uuid(), 'Decoration', 'decoration', 'Event decoration and floral arrangements'),
    (gen_random_uuid(), 'Makeup Artist', 'beauty', 'Professional makeup and beauty services'),
    (gen_random_uuid(), 'Hair Styling', 'beauty', 'Professional hair styling services'),
    (gen_random_uuid(), 'Event Planning', 'planning', 'Complete event planning and coordination'),
    (gen_random_uuid(), 'Lighting', 'technical', 'Professional lighting and sound services'),
    (gen_random_uuid(), 'Security', 'security', 'Event security and crowd management'),
    (gen_random_uuid(), 'Transportation', 'logistics', 'Guest transportation and logistics'),
    (gen_random_uuid(), 'Photobooth', 'entertainment', 'Interactive photobooth services')
ON CONFLICT (service_id) DO NOTHING;

-- Step 5: Create job carts with proper event_id links
DO $$
DECLARE
    client_record RECORD;
    event_record RECORD;
    service_record RECORD;
    job_cart_id_var UUID;
    event_counter INTEGER := 0;
    service_counter INTEGER := 0;
BEGIN
    -- Create job carts for each client and event combination
    FOR client_record IN SELECT client_id FROM client LIMIT 5 LOOP
        FOR event_record IN SELECT event_id, event_type, event_date FROM event LIMIT 3 LOOP
            event_counter := event_counter + 1;
            
            -- Create job carts for different services for this event
            FOR service_record IN SELECT service_id, service_name, service_type FROM service LIMIT 4 LOOP
                service_counter := service_counter + 1;
                
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
                        WHEN RANDOM() > 0.7 THEN 'confirmed'
                        WHEN RANDOM() > 0.4 THEN 'pending'
                        ELSE 'available'
                    END,
                    event_record.event_date - INTERVAL '30 days',
                    (CURRENT_TIME + (RANDOM() * INTERVAL '8 hours'))
                )
                ON CONFLICT (job_cart_id) DO NOTHING;
            END LOOP;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Created job carts for % events and % services', event_counter, service_counter;
END $$;

-- Step 6: Update existing job carts that might have NULL event_id
UPDATE job_cart 
SET event_id = (
    SELECT event_id 
    FROM event 
    ORDER BY RANDOM() 
    LIMIT 1
)
WHERE event_id IS NULL;

-- Step 7: Create bookings for the events
DO $$
DECLARE
    event_record RECORD;
    client_record RECORD;
    booking_id_var UUID;
BEGIN
    -- Create bookings for each event
    FOR event_record IN SELECT event_id, event_type, event_date, event_location FROM event LOOP
        -- Get a random client for this booking
        SELECT client_id INTO client_record FROM client ORDER BY RANDOM() LIMIT 1;
        
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
                WHEN RANDOM() > 0.6 THEN 'confirmed'
                WHEN RANDOM() > 0.3 THEN 'pending'
                ELSE 'draft'
            END,
            (1000 + RANDOM() * 2000)::NUMERIC(10,2),
            (3000 + RANDOM() * 5000)::NUMERIC(10,2),
            event_record.event_location,
            CASE 
                WHEN RANDOM() > 0.7 THEN 'Special dietary requirements needed'
                WHEN RANDOM() > 0.4 THEN 'Outdoor event - weather backup plan required'
                ELSE NULL
            END
        )
        ON CONFLICT (booking_id) DO NOTHING;
    END LOOP;
END $$;

-- Step 8: Create event_service relationships
DO $$
DECLARE
    event_record RECORD;
    service_record RECORD;
BEGIN
    -- Link events with their services
    FOR event_record IN SELECT event_id, event_type FROM event LOOP
        -- Add 2-4 services per event
        FOR service_record IN 
            SELECT service_id, service_name 
            FROM service 
            ORDER BY RANDOM() 
            LIMIT (2 + RANDOM() * 3)::INTEGER
        LOOP
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
                    WHEN RANDOM() > 0.6 THEN 'confirmed'
                    WHEN RANDOM() > 0.3 THEN 'pending'
                    ELSE 'available'
                END,
                'Service for ' || event_record.event_type || ' - ' || service_record.service_name
            )
            ON CONFLICT (event_service_id) DO NOTHING;
        END LOOP;
    END LOOP;
END $$;

-- Step 9: Verify the data
SELECT 'Job Carts Created' as status, COUNT(*) as count FROM job_cart;
SELECT 'Job Carts with Event ID' as status, COUNT(*) as count FROM job_cart WHERE event_id IS NOT NULL;
SELECT 'Events Created' as status, COUNT(*) as count FROM event;
SELECT 'Bookings Created' as status, COUNT(*) as count FROM booking;
SELECT 'Event Services Created' as status, COUNT(*) as count FROM event_service;

-- Show sample data with relationships
SELECT 
    'Job Cart Sample' as data_type,
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
