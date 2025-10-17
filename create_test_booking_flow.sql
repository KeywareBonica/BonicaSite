-- create_test_booking_flow.sql
-- Create test data for the complete booking flow

-- =====================================================
-- 1. Check existing clients or create test client
-- =====================================================

-- First, let's see what clients exist
SELECT 'Existing clients:' as info;
SELECT client_id, client_name, client_surname, client_email FROM public.client LIMIT 5;

-- Create test client with proper UUID
INSERT INTO public.client (
    client_name,
    client_surname,
    client_password,
    client_contact,
    client_email,
    client_city,
    client_town,
    client_street_name,
    client_house_number,
    client_postal_code,
    client_preferred_notification,
    client_province
) VALUES (
    'John',
    'Smith',
    'hashed_password_123',
    '0123456789',
    'john.smith@test.com',
    'Johannesburg',
    'Sandton',
    'Main Street',
    '123',
    '2196',
    'email',
    'Gauteng'
) ON CONFLICT (client_email) DO NOTHING;

-- Get the test client ID
SELECT client_id INTO TEMP TABLE test_client_id FROM public.client WHERE client_email = 'john.smith@test.com';

-- =====================================================
-- 2. Create test event
-- =====================================================
INSERT INTO public.event (
    event_type,
    event_date,
    event_start_time,
    event_end_time,
    event_location
) VALUES (
    'Wedding',
    '2025-02-15',
    '10:00:00',
    '18:00:00',
    'Johannesburg Convention Centre'
) ON CONFLICT DO NOTHING;

-- Get the test event ID
SELECT event_id INTO TEMP TABLE test_event_id FROM public.event WHERE event_type = 'Wedding' AND event_date = '2025-02-15' ORDER BY created_at DESC LIMIT 1;

-- =====================================================
-- 3. Create test services
-- =====================================================
INSERT INTO public.service (
    service_id,
    service_name,
    service_type,
    service_description
) VALUES 
    ('service-catering-123'::uuid, 'Catering', 'Food & Beverage', 'Professional catering services'),
    ('service-photography-123'::uuid, 'Photography', 'Media & Entertainment', 'Professional photography services'),
    ('service-decoration-123'::uuid, 'Decoration', 'Design & Styling', 'Event decoration and styling')
ON CONFLICT (service_id) DO NOTHING;

-- =====================================================
-- 4. Create test service providers
-- =====================================================
INSERT INTO public.service_provider (
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_password,
    service_provider_contactno,
    service_provider_email,
    service_provider_location,
    service_provider_operating_days,
    service_provider_base_rate,
    service_provider_overtime_rate,
    service_provider_caption,
    service_provider_rating,
    service_provider_description,
    service_provider_service_type,
    service_provider_verification,
    service_id,
    service_provider_operating_times
) VALUES 
    (
        'sp-catering-123'::uuid,
        'Sarah',
        'Johnson',
        'hashed_password_123',
        '0112345678',
        'sarah.johnson@catering.com',
        'Johannesburg',
        ARRAY['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'],
        1500.00,
        200.00,
        'Professional Catering Services',
        4.8,
        'We provide excellent catering services for all events',
        'Catering',
        true,
        'service-catering-123'::uuid,
        '{"Monday": {"start": "08:00", "end": "18:00"}, "Tuesday": {"start": "08:00", "end": "18:00"}, "Wednesday": {"start": "08:00", "end": "18:00"}, "Thursday": {"start": "08:00", "end": "18:00"}, "Friday": {"start": "08:00", "end": "18:00"}, "Saturday": {"start": "08:00", "end": "18:00"}, "Sunday": {"start": "08:00", "end": "18:00"}}'::jsonb
    ),
    (
        'sp-photography-123'::uuid,
        'Mike',
        'Davis',
        'hashed_password_123',
        '0112345679',
        'mike.davis@photography.com',
        'Johannesburg',
        ARRAY['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'],
        2000.00,
        300.00,
        'Professional Photography Services',
        4.9,
        'We capture your special moments beautifully',
        'Photography',
        true,
        'service-photography-123'::uuid,
        '{"Monday": {"start": "07:00", "end": "19:00"}, "Tuesday": {"start": "07:00", "end": "19:00"}, "Wednesday": {"start": "07:00", "end": "19:00"}, "Thursday": {"start": "07:00", "end": "19:00"}, "Friday": {"start": "07:00", "end": "19:00"}, "Saturday": {"start": "07:00", "end": "19:00"}, "Sunday": {"start": "07:00", "end": "19:00"}}'::jsonb
    ),
    (
        'sp-decoration-123'::uuid,
        'Emma',
        'Wilson',
        'hashed_password_123',
        '0112345680',
        'emma.wilson@decoration.com',
        'Johannesburg',
        ARRAY['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'],
        1200.00,
        150.00,
        'Beautiful Event Decorations',
        4.7,
        'We create stunning decorations for your events',
        'Decoration',
        true,
        'service-decoration-123'::uuid,
        '{"Monday": {"start": "09:00", "end": "17:00"}, "Tuesday": {"start": "09:00", "end": "17:00"}, "Wednesday": {"start": "09:00", "end": "17:00"}, "Thursday": {"start": "09:00", "end": "17:00"}, "Friday": {"start": "09:00", "end": "17:00"}, "Saturday": {"start": "09:00", "end": "17:00"}, "Sunday": {"start": "09:00", "end": "17:00"}}'::jsonb
    )
ON CONFLICT (service_provider_email) DO NOTHING;

-- =====================================================
-- 5. Create test job cart items
-- =====================================================
INSERT INTO public.job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_status,
    service_id,
    client_id,
    job_cart_min_price,
    job_cart_max_price
) VALUES 
    (
        'job-cart-catering-123'::uuid,
        'test-event-123'::uuid,
        'Catering Service',
        'Catering for 100 guests at wedding reception',
        'pending',
        'service-catering-123'::uuid,
        'test-client-123'::uuid,
        1000.00,
        3000.00
    ),
    (
        'job-cart-photography-123'::uuid,
        'test-event-123'::uuid,
        'Photography Service',
        'Full day wedding photography coverage',
        'pending',
        'service-photography-123'::uuid,
        'test-client-123'::uuid,
        1500.00,
        4000.00
    ),
    (
        'job-cart-decoration-123'::uuid,
        'test-event-123'::uuid,
        'Decoration Service',
        'Wedding reception decoration and styling',
        'pending',
        'service-decoration-123'::uuid,
        'test-client-123'::uuid,
        800.00,
        2000.00
    )
ON CONFLICT (job_cart_id) DO NOTHING;

-- =====================================================
-- 6. Create test quotations
-- =====================================================
INSERT INTO public.quotation (
    quotation_id,
    service_provider_id,
    job_cart_id,
    quotation_price,
    quotation_details,
    quotation_status,
    service_id,
    event_id
) VALUES 
    (
        'quote-catering-1'::uuid,
        'sp-catering-123'::uuid,
        'job-cart-catering-123'::uuid,
        2500.00,
        'Catering for 100 guests including appetizers, main course, and dessert',
        'pending',
        'service-catering-123'::uuid,
        'test-event-123'::uuid
    ),
    (
        'quote-catering-2'::uuid,
        'sp-catering-123'::uuid,
        'job-cart-catering-123'::uuid,
        2200.00,
        'Premium catering package with vegetarian options',
        'pending',
        'service-catering-123'::uuid,
        'test-event-123'::uuid
    ),
    (
        'quote-photography-1'::uuid,
        'sp-photography-123'::uuid,
        'job-cart-photography-123'::uuid,
        3500.00,
        'Full day photography with 2 photographers and edited photos',
        'pending',
        'service-photography-123'::uuid,
        'test-event-123'::uuid
    ),
    (
        'quote-decoration-1'::uuid,
        'sp-decoration-123'::uuid,
        'job-cart-decoration-123'::uuid,
        1500.00,
        'Complete decoration package with flowers and lighting',
        'pending',
        'service-decoration-123'::uuid,
        'test-event-123'::uuid
    )
ON CONFLICT (quotation_id) DO NOTHING;

-- =====================================================
-- 7. Show created test data
-- =====================================================
SELECT 'Test data created successfully!' as status;

SELECT 
    'Client:' as type,
    client_name || ' ' || client_surname as name,
    client_email as email
FROM public.client 
WHERE client_id = 'test-client-123'::uuid;

SELECT 
    'Event:' as type,
    event_type as name,
    event_date::text as date,
    event_location as location
FROM public.event 
WHERE event_id = 'test-event-123'::uuid;

SELECT 
    'Service Provider:' as type,
    service_provider_name || ' ' || service_provider_surname as name,
    service_provider_service_type as service_type
FROM public.service_provider 
WHERE service_provider_id IN ('sp-catering-123', 'sp-photography-123', 'sp-decoration-123')::uuid;

SELECT 
    'Quotations Available:' as type,
    COUNT(*) as count
FROM public.quotation 
WHERE quotation_status = 'pending';

-- =====================================================
-- 8. Instructions for testing
-- =====================================================
SELECT '
🧪 TESTING INSTRUCTIONS:

1. Run this SQL script in Supabase SQL Editor
2. Go to your booking system and:
   - Login as: john.smith@test.com
   - Select services for the test event
   - View quotations (should see 4 quotations)
   - Accept quotations and proceed to payment
   - Upload proof of payment
3. Check admin dashboard for payment verification

📋 Test Client Details:
- Email: john.smith@test.com
- Name: John Smith
- Event: Wedding on 2025-02-15

🎯 Expected Flow:
- 4 quotations should be available
- Can select 1 quotation per service
- Total should be around R7,200 (3 services)
- Payment upload should create payment records
- Admin can verify payments

' as instructions;
