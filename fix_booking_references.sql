-- Fix booking table references to ensure client_id and service_provider_id point to existing records
-- This script will clean up any invalid references and create proper test data

-- Step 1: Check current booking data and identify invalid references
DO $$
DECLARE
    invalid_client_count INTEGER;
    invalid_event_count INTEGER;
    total_bookings INTEGER;
BEGIN
    -- Count total bookings
    SELECT COUNT(*) INTO total_bookings FROM booking;
    RAISE NOTICE 'Total bookings in database: %', total_bookings;
    
    -- Count bookings with invalid client_id references
    SELECT COUNT(*) INTO invalid_client_count 
    FROM booking b 
    LEFT JOIN client c ON b.client_id = c.client_id 
    WHERE c.client_id IS NULL;
    RAISE NOTICE 'Bookings with invalid client_id: %', invalid_client_count;
    
    -- Count bookings with invalid event_id references
    SELECT COUNT(*) INTO invalid_event_count 
    FROM booking b 
    LEFT JOIN event e ON b.event_id = e.event_id 
    WHERE e.event_id IS NULL;
    RAISE NOTICE 'Bookings with invalid event_id: %', invalid_event_count;
END $$;

-- Step 2: Get existing valid client and event IDs
DO $$
DECLARE
    valid_client_id UUID;
    valid_event_id UUID;
    booking_record RECORD;
BEGIN
    -- Get a valid client ID
    SELECT client_id INTO valid_client_id FROM client LIMIT 1;
    
    -- Get a valid event ID
    SELECT event_id INTO valid_event_id FROM event LIMIT 1;
    
    RAISE NOTICE 'Using client_id: %', valid_client_id;
    RAISE NOTICE 'Using event_id: %', valid_event_id;
    
    -- Update bookings with invalid client_id references
    UPDATE booking 
    SET client_id = valid_client_id 
    WHERE client_id NOT IN (SELECT client_id FROM client);
    
    -- Update bookings with invalid event_id references
    UPDATE booking 
    SET event_id = valid_event_id 
    WHERE event_id NOT IN (SELECT event_id FROM event);
    
    RAISE NOTICE 'Updated invalid references';
END $$;

-- Step 3: Create proper test bookings with valid references
DO $$
DECLARE
    client_record RECORD;
    event_record RECORD;
    service_provider_record RECORD;
    booking_id_var UUID;
    quotation_id_var UUID;
    job_cart_id_var UUID;
BEGIN
    -- Get valid client
    SELECT client_id, client_name, client_surname INTO client_record FROM client LIMIT 1;
    
    -- Get valid event
    SELECT event_id, event_type, event_date, event_location INTO event_record FROM event LIMIT 1;
    
    -- Get valid service provider
    SELECT service_provider_id, service_provider_name, service_provider_surname, service_provider_service_type 
    INTO service_provider_record FROM service_provider LIMIT 1;
    
    RAISE NOTICE 'Creating test booking for client: % %', client_record.client_name, client_record.client_surname;
    RAISE NOTICE 'Event: % on %', event_record.event_type, event_record.event_date;
    RAISE NOTICE 'Service Provider: % % (%%)', service_provider_record.service_provider_name, service_provider_record.service_provider_surname, service_provider_record.service_provider_service_type;
    
    -- Create booking
    INSERT INTO booking (
        booking_id,
        booking_date,
        booking_start_time,
        booking_end_time,
        booking_status,
        booking_total_price,
        booking_min_price,
        booking_max_price,
        booking_special_request,
        client_id,
        event_id
    ) VALUES (
        gen_random_uuid(),
        event_record.event_date,
        '10:00:00',
        '18:00:00',
        'confirmed',
        2500.00,
        2000.00,
        3000.00,
        'Please ensure all equipment is set up 1 hour before the event',
        client_record.client_id,
        event_record.event_id
    ) RETURNING booking_id INTO booking_id_var;
    
    RAISE NOTICE 'Created booking: %', booking_id_var;
    
    -- Create job cart for this booking
    INSERT INTO job_cart (
        job_cart_id,
        service_id,
        client_id,
        event_id,
        job_cart_status
    ) VALUES (
        gen_random_uuid(),
        (SELECT service_id FROM service WHERE service_type = service_provider_record.service_provider_service_type LIMIT 1),
        client_record.client_id,
        event_record.event_id,
        'accepted'
    ) RETURNING job_cart_id INTO job_cart_id_var;
    
    RAISE NOTICE 'Created job cart: %', job_cart_id_var;
    
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
        'Professional ' || service_provider_record.service_provider_service_type || ' services for your special event. Includes setup, execution, and cleanup.',
        '/quotations/quotation_' || job_cart_id_var || '.pdf',
        'Quotation_' || job_cart_id_var || '.pdf',
        CURRENT_DATE,
        CURRENT_TIME,
        'accepted',
        event_record.event_id
    ) RETURNING quotation_id INTO quotation_id_var;
    
    RAISE NOTICE 'Created quotation: %', quotation_id_var;
    
    -- Create notification for service provider
    INSERT INTO notification (
        notification_id,
        notification_type,
        notification_title,
        notification_message,
        notification_date,
        notification_time,
        notification_status,
        user_type,
        user_id,
        booking_id
    ) VALUES (
        gen_random_uuid(),
        'booking_confirmed',
        'New Booking Confirmed',
        'Your quotation has been accepted for ' || event_record.event_type || ' on ' || event_record.event_date,
        CURRENT_DATE,
        CURRENT_TIME,
        'unread',
        'service_provider',
        service_provider_record.service_provider_id,
        booking_id_var
    );
    
    RAISE NOTICE 'Created notification for service provider';
    
END $$;

-- Step 4: Verify all references are valid
DO $$
DECLARE
    valid_bookings INTEGER;
    total_bookings INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_bookings FROM booking;
    
    SELECT COUNT(*) INTO valid_bookings 
    FROM booking b
    JOIN client c ON b.client_id = c.client_id
    JOIN event e ON b.event_id = e.event_id;
    
    RAISE NOTICE 'Total bookings: %', total_bookings;
    RAISE NOTICE 'Valid bookings (with proper references): %', valid_bookings;
    
    IF valid_bookings = total_bookings THEN
        RAISE NOTICE 'SUCCESS: All booking references are valid!';
    ELSE
        RAISE NOTICE 'WARNING: Some booking references are still invalid';
    END IF;
END $$;

-- Step 5: Show sample data
SELECT 
    b.booking_id,
    b.booking_status,
    b.booking_total_price,
    c.client_name || ' ' || c.client_surname as client_name,
    e.event_type,
    e.event_date,
    e.event_location,
    sp.service_provider_name || ' ' || sp.service_provider_surname as service_provider_name,
    q.quotation_price
FROM booking b
JOIN client c ON b.client_id = c.client_id
JOIN event e ON b.event_id = e.event_id
LEFT JOIN quotation q ON b.booking_id = q.booking_id
LEFT JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
ORDER BY b.created_at DESC
LIMIT 5;





