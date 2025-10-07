-- Generate Real Quotations and Comprehensive Booking Data
-- This script creates actual quotation files and populates the database with realistic data

-- Step 1: Create quotations directory structure (this will be handled by the application)
-- For now, we'll create the database entries with proper file paths

-- Step 2: Clear existing test data to start fresh
DELETE FROM quotation WHERE quotation_file_path LIKE '/quotations/test_%';
DELETE FROM job_cart WHERE job_cart_status = 'test';
DELETE FROM booking WHERE booking_status = 'test';

-- Step 3: Create events only if none exist
DO $$
DECLARE
    existing_events INTEGER;
BEGIN
    SELECT COUNT(*) INTO existing_events FROM event;
    
    IF existing_events = 0 THEN
        RAISE NOTICE 'No existing events found. Creating sample events...';
        
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
        
        RAISE NOTICE 'Created sample events';
    ELSE
        RAISE NOTICE 'Found % existing events. Skipping event creation.', existing_events;
    END IF;
END $$;

-- Step 4: Create clients only if none exist
DO $$
DECLARE
    existing_clients INTEGER;
BEGIN
    SELECT COUNT(*) INTO existing_clients FROM client;
    
    IF existing_clients = 0 THEN
        RAISE NOTICE 'No existing clients found. Creating sample clients...';
        
        INSERT INTO client (client_id, client_name, client_surname, client_password, client_contact, client_email, client_city, client_province, client_town, client_street_name, client_house_number, client_postal_code, client_preferred_notification)
        VALUES 
            (gen_random_uuid(), 'Jennifer', 'Taylor', '$2a$10$hashedpassword9', '0901234567', 'jennifer.taylor@email.com', 'Johannesburg', 'Gauteng', 'Sandton', 'Rivonia Road', '456', '2196', 'email'),
            (gen_random_uuid(), 'Robert', 'Miller', '$2a$10$hashedpassword10', '0912345678', 'robert.miller@email.com', 'Cape Town', 'Western Cape', 'Cape Town', 'Kloof Street', '789', '8001', 'sms'),
            (gen_random_uuid(), 'Amanda', 'Garcia', '$2a$10$hashedpassword11', '0923456789', 'amanda.garcia@email.com', 'Durban', 'KwaZulu-Natal', 'Durban', 'Florida Road', '321', '4001', 'email'),
            (gen_random_uuid(), 'Christopher', 'Lee', '$2a$10$hashedpassword12', '0934567890', 'christopher.lee@email.com', 'Pretoria', 'Gauteng', 'Pretoria', 'Church Square', '654', '0002', 'email'),
            (gen_random_uuid(), 'Michelle', 'Rodriguez', '$2a$10$hashedpassword13', '0945678901', 'michelle.rodriguez@email.com', 'Port Elizabeth', 'Eastern Cape', 'Port Elizabeth', 'Main Road', '987', '6001', 'sms')
        ON CONFLICT (client_email) DO NOTHING;
        
        RAISE NOTICE 'Created sample clients';
    ELSE
        RAISE NOTICE 'Found % existing clients. Skipping client creation.', existing_clients;
    END IF;
END $$;

-- Step 5: Update existing service providers with operating data (if they don't have it)
UPDATE service_provider 
SET 
    service_provider_operating_days = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
    service_provider_operating_times = '{"start_time": "08:00", "end_time": "18:00", "break_start": "12:00", "break_end": "13:00", "weekend_rates": true}'::jsonb,
    service_provider_caption = 'Professional ' || service_provider_service_type || ' Services',
    service_provider_description = 'Experienced ' || service_provider_service_type || ' professional providing quality services for your special events.'
WHERE service_provider_operating_days IS NULL OR service_provider_operating_times IS NULL;

-- Step 6: Create job carts only for existing data (avoid duplicates)
DO $$
DECLARE
    client_record RECORD;
    event_record RECORD;
    service_record RECORD;
    job_cart_counter INTEGER := 0;
    event_counter INTEGER := 0;
    existing_job_carts INTEGER;
BEGIN
    -- Check if we already have job carts
    SELECT COUNT(*) INTO existing_job_carts FROM job_cart;
    
    IF existing_job_carts = 0 THEN
        -- Only create job carts if none exist
        RAISE NOTICE 'No existing job carts found. Creating sample job carts...';
        
        -- Create job carts for each client and event combination
        FOR client_record IN SELECT client_id FROM client LIMIT 5 LOOP  -- Limit to 5 clients
            event_counter := 0;
            
            -- Each client gets 1-2 events
            FOR event_record IN 
                SELECT event_id, event_type, event_date, event_location 
                FROM event 
                ORDER BY RANDOM() 
                LIMIT (1 + RANDOM() * 2)::INTEGER
            LOOP
                event_counter := event_counter + 1;
                
                -- Create job carts for 1-2 services per event
                FOR service_record IN 
                    SELECT service_id, service_name, service_type 
                    FROM service 
                    ORDER BY RANDOM() 
                    LIMIT (1 + RANDOM() * 2)::INTEGER
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
    ELSE
        RAISE NOTICE 'Found % existing job carts. Skipping job cart creation.', existing_job_carts;
    END IF;
END $$;

-- Step 7: Create comprehensive bookings
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

-- Step 8: Create quotations only for existing job carts (avoid duplicates)
DO $$
DECLARE
    job_cart_record RECORD;
    service_provider_record RECORD;
    booking_record RECORD;
    quotation_counter INTEGER := 0;
    quotation_id_var UUID;
    file_name TEXT;
    file_path TEXT;
    existing_quotations INTEGER;
BEGIN
    -- Check if we already have quotations
    SELECT COUNT(*) INTO existing_quotations FROM quotation;
    
    IF existing_quotations = 0 THEN
        -- Only create quotations if none exist
        RAISE NOTICE 'No existing quotations found. Creating sample quotations...';
        
        -- Create quotations for existing job carts
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
                e.event_date,
                c.client_name,
                c.client_surname
            FROM job_cart jc
            JOIN service s ON jc.service_id = s.service_id
            JOIN event e ON jc.event_id = e.event_id
            JOIN client c ON jc.client_id = c.client_id
            WHERE jc.job_cart_status IN ('pending', 'available', 'confirmed')
            LIMIT 10  -- Limit to 10 job carts to avoid too many quotations
        LOOP
        -- Get 2-4 existing service providers for this service type
        FOR service_provider_record IN 
            SELECT 
                sp.service_provider_id,
                sp.service_provider_name,
                sp.service_provider_surname,
                sp.service_provider_base_rate,
                sp.service_provider_rating,
                sp.service_provider_service_type
            FROM service_provider sp
            WHERE sp.service_provider_service_type ILIKE '%' || job_cart_record.service_type || '%'
            AND sp.service_provider_verification = true  -- Only use verified providers
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
            
            -- Generate realistic file names and paths
            file_name := LOWER(REPLACE(service_provider_record.service_provider_name, ' ', '_')) || '_' || 
                        LOWER(REPLACE(job_cart_record.service_name, ' ', '_')) || '_' ||
                        TO_CHAR(job_cart_record.event_date, 'YYYY_MM_DD') || '_quote.pdf';
            file_path := '/quotations/' || file_name;
            
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
                ' on ' || job_cart_record.event_date::TEXT || ' at ' || 
                (SELECT event_location FROM event WHERE event_id = job_cart_record.event_id) || '. ' ||
                'Client: ' || job_cart_record.client_name || ' ' || job_cart_record.client_surname || '. ' ||
                CASE 
                    WHEN RANDOM() > 0.8 THEN 'Premium package includes extended coverage, professional equipment, and post-event editing.'
                    WHEN RANDOM() > 0.6 THEN 'Standard package with professional service and basic equipment included.'
                    WHEN RANDOM() > 0.4 THEN 'Essential package covering all basic requirements for your event.'
                    ELSE 'Customized package tailored to your specific needs and budget.'
                END || ' ' ||
                CASE 
                    WHEN RANDOM() > 0.7 THEN 'Additional services available upon request.'
                    WHEN RANDOM() > 0.4 THEN 'Setup and breakdown included in quoted price.'
                    ELSE 'All necessary materials and equipment provided.'
                END,
                file_path,
                file_name,
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
            RETURNING quotation_id INTO quotation_id_var
            ON CONFLICT (quotation_id) DO NOTHING;
        END LOOP;
    END LOOP;
    
        RAISE NOTICE 'Created % quotations with realistic file paths', quotation_counter;
    ELSE
        RAISE NOTICE 'Found % existing quotations. Skipping quotation creation.', existing_quotations;
    END IF;
END $$;

-- Step 9: Create event_service relationships
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

-- Step 10: Final verification and statistics
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
SELECT 'Quotations with File Paths' as table_name, COUNT(*) as count FROM quotation WHERE quotation_file_path IS NOT NULL;

-- Step 11: Show sample relationships with file paths
SELECT 
    'Sample Quotation Data with File Paths' as data_type,
    q.quotation_id,
    sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
    s.service_name,
    e.event_type,
    e.event_date,
    q.quotation_price,
    q.quotation_status,
    q.quotation_file_path,
    q.quotation_file_name
FROM quotation q
JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
JOIN service s ON jc.service_id = s.service_id
JOIN event e ON q.event_id = e.event_id
ORDER BY q.created_at DESC
LIMIT 15;
