-- Populate Quotation Table with Realistic Data
-- This script creates sample quotations linked to existing job carts, service providers, and events

-- First, let's check what data we have in the related tables
-- (These are just for reference - we'll use the actual IDs from the database)

-- Step 1: Insert sample services if they don't exist
INSERT INTO service (service_id, service_name, service_type, service_description) 
VALUES 
    (gen_random_uuid(), 'Photography', 'photography', 'Professional event photography services'),
    (gen_random_uuid(), 'Videography', 'videography', 'Professional event videography services'),
    (gen_random_uuid(), 'DJ Services', 'entertainment', 'Professional DJ and music services'),
    (gen_random_uuid(), 'Catering', 'catering', 'Professional catering and food services'),
    (gen_random_uuid(), 'Decoration', 'decoration', 'Event decoration and floral arrangements'),
    (gen_random_uuid(), 'Makeup Artist', 'beauty', 'Professional makeup and beauty services'),
    (gen_random_uuid(), 'Hair Styling', 'beauty', 'Professional hair styling services'),
    (gen_random_uuid(), 'Event Planning', 'planning', 'Complete event planning and coordination')
ON CONFLICT (service_id) DO NOTHING;

-- Step 2: Insert sample clients if they don't exist
INSERT INTO client (client_id, client_name, client_surname, client_password, client_contact, client_email, client_city, client_province)
VALUES 
    (gen_random_uuid(), 'Sarah', 'Johnson', '$2a$10$hashedpassword1', '0821234567', 'sarah.johnson@email.com', 'Johannesburg', 'Gauteng'),
    (gen_random_uuid(), 'Michael', 'Brown', '$2a$10$hashedpassword2', '0832345678', 'michael.brown@email.com', 'Cape Town', 'Western Cape'),
    (gen_random_uuid(), 'Emma', 'Wilson', '$2a$10$hashedpassword3', '0843456789', 'emma.wilson@email.com', 'Durban', 'KwaZulu-Natal'),
    (gen_random_uuid(), 'David', 'Smith', '$2a$10$hashedpassword4', '0854567890', 'david.smith@email.com', 'Pretoria', 'Gauteng'),
    (gen_random_uuid(), 'Lisa', 'Davis', '$2a$10$hashedpassword5', '0865678901', 'lisa.davis@email.com', 'Port Elizabeth', 'Eastern Cape')
ON CONFLICT (client_email) DO NOTHING;

-- Step 3: Insert sample events
INSERT INTO event (event_id, event_type, event_date, event_start_time, event_end_time, event_location)
VALUES 
    (gen_random_uuid(), 'Wedding', '2024-12-15', '14:00:00', '23:00:00', 'Sandton Convention Centre, Johannesburg'),
    (gen_random_uuid(), 'Birthday Party', '2024-12-20', '18:00:00', '02:00:00', 'Cape Town International Convention Centre'),
    (gen_random_uuid(), 'Corporate Event', '2024-12-25', '09:00:00', '17:00:00', 'Midrand Conference Centre, Johannesburg'),
    (gen_random_uuid(), 'Anniversary', '2024-12-30', '19:00:00', '01:00:00', 'Pretoria Country Club'),
    (gen_random_uuid(), 'Graduation Party', '2025-01-05', '16:00:00', '22:00:00', 'Durban Exhibition Centre')
ON CONFLICT (event_id) DO NOTHING;

-- Step 4: Insert sample service providers
INSERT INTO service_provider (service_provider_id, service_provider_name, service_provider_surname, service_provider_password, service_provider_contactno, service_provider_email, service_provider_location, service_provider_service_type, service_provider_base_rate, service_provider_rating, service_provider_verification)
VALUES 
    (gen_random_uuid(), 'John', 'Photographer', '$2a$10$hashedpassword6', '0871234567', 'john.photo@email.com', 'Johannesburg', 'Photography', 2500.00, 4.8, true),
    (gen_random_uuid(), 'Maria', 'Videographer', '$2a$10$hashedpassword7', '0882345678', 'maria.video@email.com', 'Cape Town', 'Videography', 3000.00, 4.9, true),
    (gen_random_uuid(), 'DJ', 'Mike', '$2a$10$hashedpassword8', '0893456789', 'dj.mike@email.com', 'Durban', 'DJ Services', 1500.00, 4.7, true),
    (gen_random_uuid(), 'Chef', 'Anna', '$2a$10$hashedpassword9', '0804567890', 'chef.anna@email.com', 'Pretoria', 'Catering', 2000.00, 4.6, true),
    (gen_random_uuid(), 'Decorator', 'Sophie', '$2a$10$hashedpassword10', '0815678901', 'decor.sophie@email.com', 'Johannesburg', 'Decoration', 1800.00, 4.5, true),
    (gen_random_uuid(), 'Makeup', 'Artist', '$2a$10$hashedpassword11', '0826789012', 'makeup.artist@email.com', 'Cape Town', 'Makeup Artist', 800.00, 4.9, true),
    (gen_random_uuid(), 'Hair', 'Stylist', '$2a$10$hashedpassword12', '0837890123', 'hair.stylist@email.com', 'Durban', 'Hair Styling', 600.00, 4.8, true),
    (gen_random_uuid(), 'Event', 'Planner', '$2a$10$hashedpassword13', '0848901234', 'event.planner@email.com', 'Johannesburg', 'Event Planning', 3500.00, 4.7, true)
ON CONFLICT (service_provider_email) DO NOTHING;

-- Step 5: Create job carts and bookings with valid references
DO $$
DECLARE
    client_record RECORD;
    event_record RECORD;
    service_record RECORD;
    service_provider_record RECORD;
    job_cart_id_var UUID;
    booking_id_var UUID;
    quotation_id_var UUID;
BEGIN
    -- Get valid client
    SELECT client_id, client_name, client_surname INTO client_record FROM client LIMIT 1;
    
    -- Get valid event
    SELECT event_id, event_date, event_type, event_location INTO event_record FROM event LIMIT 1;
    
    -- Get valid service provider
    SELECT service_provider_id, service_provider_name, service_provider_surname, service_provider_service_type 
    INTO service_provider_record FROM service_provider LIMIT 1;
    
    RAISE NOTICE 'Creating bookings with valid references...';
    RAISE NOTICE 'Client: % %', client_record.client_name, client_record.client_surname;
    RAISE NOTICE 'Event: % on %', event_record.event_type, event_record.event_date;
    RAISE NOTICE 'Service Provider: % %', service_provider_record.service_provider_name, service_provider_record.service_provider_surname;
    
    -- Create job carts for different services
    FOR service_record IN SELECT service_id, service_name, service_type FROM service LIMIT 3 LOOP
        -- Insert job cart
        INSERT INTO job_cart (job_cart_id, client_id, service_id, event_id, job_cart_status)
        VALUES (gen_random_uuid(), client_record.client_id, service_record.service_id, event_record.event_id, 'accepted')
        RETURNING job_cart_id INTO job_cart_id_var;
        
        -- Create booking for this job cart
        INSERT INTO booking (
            booking_id, 
            client_id, 
            event_id, 
            booking_date, 
            booking_start_time,
            booking_end_time,
            booking_status, 
            booking_min_price, 
            booking_max_price,
            booking_total_price,
            booking_special_request
        ) VALUES (
            gen_random_uuid(), 
            client_record.client_id, 
            event_record.event_id, 
            event_record.event_date,
            '10:00:00',
            '18:00:00',
            'confirmed', 
            2000.00, 
            3000.00,
            2500.00,
            'Please ensure all equipment is set up 1 hour before the event'
        ) RETURNING booking_id INTO booking_id_var;
        
        -- Create quotation for this booking
        INSERT INTO quotation (
            quotation_id,
            service_provider_id,
            job_cart_id,
            booking_id,
            quotation_price,
            quotation_details,
            quotation_file_path,
            quotation_file_name,
            quotation_submission_date,
            quotation_submission_time,
            quotation_status,
            event_id
        ) VALUES (
            gen_random_uuid(),
            service_provider_record.service_provider_id,
            job_cart_id_var,
            booking_id_var,
            2500.00,
            'Professional ' || service_record.service_type || ' services for your special event.',
            '/quotations/quotation_' || job_cart_id_var || '.pdf',
            'Quotation_' || job_cart_id_var || '.pdf',
            CURRENT_DATE,
            CURRENT_TIME,
            'accepted',
            event_record.event_id
        ) RETURNING quotation_id INTO quotation_id_var;
        
        RAISE NOTICE 'Created booking % with job cart % and quotation %', booking_id_var, job_cart_id_var, quotation_id_var;
    END LOOP;
    
    RAISE NOTICE 'Successfully created bookings with valid references!';
END $$;

-- Step 6: Insert sample quotations
-- This will create quotations from different service providers for the job carts
DO $$
DECLARE
    job_cart_record RECORD;
    service_provider_record RECORD;
    quotation_id_var UUID;
    random_price NUMERIC;
    quotation_details_text TEXT;
BEGIN
    -- For each job cart, create quotations from relevant service providers
    FOR job_cart_record IN 
        SELECT jc.job_cart_id, jc.service_id, s.service_name, s.service_type, e.event_type, e.event_date
        FROM job_cart jc
        JOIN service s ON jc.service_id = s.service_id
        JOIN event e ON jc.event_id = e.event_id
        LIMIT 10
    LOOP
        -- Find service providers that match this service type
        FOR service_provider_record IN 
            SELECT service_provider_id, service_provider_name, service_provider_surname, service_provider_base_rate
            FROM service_provider 
            WHERE service_provider_service_type ILIKE '%' || job_cart_record.service_type || '%'
            OR service_provider_service_type ILIKE '%' || job_cart_record.service_name || '%'
            LIMIT 3
        LOOP
            -- Generate random price based on base rate
            random_price := service_provider_record.service_provider_base_rate + (RANDOM() * 1000);
            
            -- Generate quotation details
            quotation_details_text := 'Professional ' || job_cart_record.service_name || ' services for ' || job_cart_record.event_type || 
                                    ' on ' || job_cart_record.event_date || '. Includes full service delivery, setup, and breakdown. ' ||
                                    'Experienced team with ' || service_provider_record.service_provider_name || ' ' || service_provider_record.service_provider_surname || '.';
            
            -- Insert quotation
            INSERT INTO quotation (
                quotation_id,
                service_provider_id,
                job_cart_id,
                quotation_price,
                quotation_details,
                quotation_status,
                event_id,
                quotation_file_name,
                quotation_file_path
            )
            VALUES (
                gen_random_uuid(),
                service_provider_record.service_provider_id,
                job_cart_record.job_cart_id,
                random_price,
                quotation_details_text,
                CASE WHEN RANDOM() > 0.7 THEN 'accepted' ELSE 'pending' END,
                (SELECT event_id FROM job_cart WHERE job_cart_id = job_cart_record.job_cart_id),
                'quotation_' || job_cart_record.job_cart_id || '_' || service_provider_record.service_provider_id || '.pdf',
                '/quotations/quotation_' || job_cart_record.job_cart_id || '_' || service_provider_record.service_provider_id || '.pdf'
            );
        END LOOP;
    END LOOP;
END $$;

-- Step 7: Create some additional quotations for variety
-- Add quotations from different service providers for the same services
DO $$
DECLARE
    job_cart_record RECORD;
    service_provider_record RECORD;
    random_price NUMERIC;
    quotation_details_text TEXT;
BEGIN
    -- Get a few job carts and add more quotations
    FOR job_cart_record IN 
        SELECT jc.job_cart_id, jc.service_id, s.service_name, s.service_type, e.event_type, e.event_date, e.event_id
        FROM job_cart jc
        JOIN service s ON jc.service_id = s.service_id
        JOIN event e ON jc.event_id = e.event_id
        LIMIT 5
    LOOP
        -- Add quotations from service providers with different service types but relevant skills
        FOR service_provider_record IN 
            SELECT service_provider_id, service_provider_name, service_provider_surname, service_provider_base_rate, service_provider_service_type
            FROM service_provider 
            WHERE service_provider_id NOT IN (
                SELECT DISTINCT service_provider_id 
                FROM quotation 
                WHERE job_cart_id = job_cart_record.job_cart_id
            )
            LIMIT 2
        LOOP
            -- Generate competitive pricing
            random_price := service_provider_record.service_provider_base_rate + (RANDOM() * 500 - 250);
            
            -- Generate quotation details
            quotation_details_text := 'Alternative ' || service_provider_record.service_provider_service_type || 
                                    ' services for ' || job_cart_record.event_type || 
                                    ' on ' || job_cart_record.event_date || '. ' ||
                                    'Specialized in ' || service_provider_record.service_provider_service_type || 
                                    ' with competitive pricing and excellent service quality.';
            
            -- Insert quotation
            INSERT INTO quotation (
                quotation_id,
                service_provider_id,
                job_cart_id,
                quotation_price,
                quotation_details,
                quotation_status,
                event_id,
                quotation_file_name,
                quotation_file_path
            )
            VALUES (
                gen_random_uuid(),
                service_provider_record.service_provider_id,
                job_cart_record.job_cart_id,
                random_price,
                quotation_details_text,
                'pending',
                job_cart_record.event_id,
                'quotation_' || job_cart_record.job_cart_id || '_' || service_provider_record.service_provider_id || '_alt.pdf',
                '/quotations/quotation_' || job_cart_record.job_cart_id || '_' || service_provider_record.service_provider_id || '_alt.pdf'
            );
        END LOOP;
    END LOOP;
END $$;

-- Step 8: Update some quotations to have different statuses for realism
UPDATE quotation 
SET quotation_status = 'accepted'
WHERE quotation_id IN (
    SELECT quotation_id 
    FROM quotation 
    WHERE quotation_status = 'pending' 
    ORDER BY RANDOM() 
    LIMIT 3
);

UPDATE quotation 
SET quotation_status = 'rejected'
WHERE quotation_id IN (
    SELECT quotation_id 
    FROM quotation 
    WHERE quotation_status = 'pending' 
    ORDER BY RANDOM() 
    LIMIT 2
);

-- Step 9: Add some quotations with booking_id links
UPDATE quotation 
SET booking_id = (
    SELECT b.booking_id 
    FROM booking b 
    JOIN job_cart jc ON b.event_id = jc.event_id 
    WHERE jc.job_cart_id = quotation.job_cart_id 
    LIMIT 1
)
WHERE booking_id IS NULL;

-- Step 10: Verify the data
SELECT 
    'Quotations Created' as status,
    COUNT(*) as count
FROM quotation;

SELECT 
    'Job Carts with Quotations' as status,
    COUNT(DISTINCT job_cart_id) as count
FROM quotation;

SELECT 
    'Service Providers with Quotations' as status,
    COUNT(DISTINCT service_provider_id) as count
FROM quotation;

-- Show sample data
SELECT 
    q.quotation_id,
    sp.service_provider_name || ' ' || sp.service_provider_surname as provider_name,
    s.service_name,
    e.event_type,
    q.quotation_price,
    q.quotation_status,
    q.created_at
FROM quotation q
JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
JOIN service s ON jc.service_id = s.service_id
JOIN event e ON jc.event_id = e.event_id
ORDER BY q.created_at DESC
LIMIT 10;
