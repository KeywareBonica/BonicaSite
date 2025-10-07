-- Fix Service Provider Operating Days and Times
-- This script updates existing service providers with proper operating data

-- Step 1: Check current service provider data
SELECT 
    'Current Service Providers' as status,
    COUNT(*) as count,
    COUNT(CASE WHEN service_provider_operating_days IS NULL THEN 1 END) as null_operating_days,
    COUNT(CASE WHEN service_provider_operating_times IS NULL THEN 1 END) as null_operating_times
FROM service_provider;

-- Step 2: Update existing service providers with operating days and times
UPDATE service_provider 
SET 
    service_provider_operating_days = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
    service_provider_operating_times = '{"start_time": "08:00", "end_time": "18:00", "break_start": "12:00", "break_end": "13:00"}'::jsonb
WHERE service_provider_operating_days IS NULL 
   OR service_provider_operating_times IS NULL;

-- Step 3: Create more realistic operating schedules for different service types
DO $$
DECLARE
    provider_record RECORD;
    operating_days TEXT[];
    operating_times JSONB;
BEGIN
    FOR provider_record IN 
        SELECT service_provider_id, service_provider_service_type 
        FROM service_provider 
        WHERE service_provider_service_type IS NOT NULL
    LOOP
        -- Set operating days based on service type
        CASE provider_record.service_provider_service_type
            WHEN 'Photography', 'Videography' THEN
                operating_days := ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                operating_times := '{"start_time": "06:00", "end_time": "22:00", "break_start": "12:00", "break_end": "13:00", "weekend_rates": true}'::jsonb;
            
            WHEN 'DJ Services', 'Entertainment' THEN
                operating_days := ARRAY['Friday', 'Saturday', 'Sunday'];
                operating_times := '{"start_time": "18:00", "end_time": "02:00", "break_start": "21:00", "break_end": "21:30", "weekend_rates": true}'::jsonb;
            
            WHEN 'Catering' THEN
                operating_days := ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                operating_times := '{"start_time": "05:00", "end_time": "23:00", "break_start": "14:00", "break_end": "16:00", "prep_time": "2 hours"}'::jsonb;
            
            WHEN 'Makeup Artist', 'Hair Styling' THEN
                operating_days := ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                operating_times := '{"start_time": "07:00", "end_time": "19:00", "break_start": "12:00", "break_end": "13:00", "appointment_duration": "60 minutes"}'::jsonb;
            
            WHEN 'Event Planning' THEN
                operating_days := ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
                operating_times := '{"start_time": "09:00", "end_time": "17:00", "break_start": "12:00", "break_end": "13:00", "consultation_hours": "flexible"}'::jsonb;
            
            WHEN 'Decoration' THEN
                operating_days := ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                operating_times := '{"start_time": "08:00", "end_time": "18:00", "break_start": "12:00", "break_end": "13:00", "setup_time": "2-4 hours"}'::jsonb;
            
            ELSE
                operating_days := ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
                operating_times := '{"start_time": "09:00", "end_time": "17:00", "break_start": "12:00", "break_end": "13:00"}'::jsonb;
        END CASE;
        
        -- Update the service provider
        UPDATE service_provider 
        SET 
            service_provider_operating_days = operating_days,
            service_provider_operating_times = operating_times
        WHERE service_provider_id = provider_record.service_provider_id;
    END LOOP;
END $$;

-- Step 4: Create sample service providers with proper operating data
INSERT INTO service_provider (
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_password,
    service_provider_contactno,
    service_provider_email,
    service_provider_location,
    service_provider_service_type,
    service_provider_base_rate,
    service_provider_overtime_rate,
    service_provider_rating,
    service_provider_verification,
    service_provider_operating_days,
    service_provider_operating_times,
    service_provider_caption,
    service_provider_description
) VALUES 
    (
        gen_random_uuid(),
        'John',
        'Photographer',
        '$2a$10$hashedpassword1',
        '0821234567',
        'john.photo@email.com',
        'Johannesburg',
        'Photography',
        2500.00,
        350.00,
        4.8,
        true,
        ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
        '{"start_time": "06:00", "end_time": "22:00", "break_start": "12:00", "break_end": "13:00", "weekend_rates": true, "equipment_included": true}'::jsonb,
        'Capturing Your Perfect Moments',
        'Professional wedding and event photographer with 10+ years experience. Specializing in candid moments and artistic compositions.'
    ),
    (
        gen_random_uuid(),
        'Maria',
        'Videographer',
        '$2a$10$hashedpassword2',
        '0832345678',
        'maria.video@email.com',
        'Cape Town',
        'Videography',
        3000.00,
        400.00,
        4.9,
        true,
        ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
        '{"start_time": "06:00", "end_time": "22:00", "break_start": "12:00", "break_end": "13:00", "weekend_rates": true, "editing_included": true}'::jsonb,
        'Your Story, Beautifully Told',
        'Award-winning videographer creating cinematic wedding films and corporate videos. Full editing and delivery included.'
    ),
    (
        gen_random_uuid(),
        'DJ',
        'Mike',
        '$2a$10$hashedpassword3',
        '0843456789',
        'dj.mike@email.com',
        'Durban',
        'DJ Services',
        1500.00,
        200.00,
        4.7,
        true,
        ARRAY['Friday', 'Saturday', 'Sunday'],
        '{"start_time": "18:00", "end_time": "02:00", "break_start": "21:00", "break_end": "21:30", "weekend_rates": true, "sound_system_included": true}'::jsonb,
        'Music That Moves You',
        'Professional DJ with state-of-the-art sound system. Specializing in weddings, parties, and corporate events.'
    ),
    (
        gen_random_uuid(),
        'Chef',
        'Anna',
        '$2a$10$hashedpassword4',
        '0854567890',
        'chef.anna@email.com',
        'Pretoria',
        'Catering',
        2000.00,
        300.00,
        4.6,
        true,
        ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
        '{"start_time": "05:00", "end_time": "23:00", "break_start": "14:00", "break_end": "16:00", "prep_time": "2 hours", "menu_consultation": true}'::jsonb,
        'Culinary Excellence for Every Occasion',
        'Professional catering services with custom menus. Specializing in weddings, corporate events, and private parties.'
    ),
    (
        gen_random_uuid(),
        'Sophie',
        'Decorator',
        '$2a$10$hashedpassword5',
        '0865678901',
        'decor.sophie@email.com',
        'Johannesburg',
        'Decoration',
        1800.00,
        250.00,
        4.5,
        true,
        ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
        '{"start_time": "08:00", "end_time": "18:00", "break_start": "12:00", "break_end": "13:00", "setup_time": "2-4 hours", "design_consultation": true}'::jsonb,
        'Transforming Spaces, Creating Magic',
        'Creative event decorator specializing in floral arrangements, lighting, and venue transformation.'
    ),
    (
        gen_random_uuid(),
        'Lisa',
        'Makeup',
        '$2a$10$hashedpassword6',
        '0876789012',
        'makeup.lisa@email.com',
        'Cape Town',
        'Makeup Artist',
        800.00,
        100.00,
        4.9,
        true,
        ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
        '{"start_time": "07:00", "end_time": "19:00", "break_start": "12:00", "break_end": "13:00", "appointment_duration": "60 minutes", "trial_sessions": true}'::jsonb,
        'Enhancing Your Natural Beauty',
        'Professional makeup artist specializing in bridal and special event makeup. Trial sessions available.'
    ),
    (
        gen_random_uuid(),
        'Sarah',
        'Hair',
        '$2a$10$hashedpassword7',
        '0887890123',
        'hair.sarah@email.com',
        'Durban',
        'Hair Styling',
        600.00,
        80.00,
        4.8,
        true,
        ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
        '{"start_time": "07:00", "end_time": "19:00", "break_start": "12:00", "break_end": "13:00", "appointment_duration": "90 minutes", "trial_sessions": true}'::jsonb,
        'Styling Your Perfect Look',
        'Professional hair stylist with expertise in bridal and special event styling. Trial sessions and consultations available.'
    ),
    (
        gen_random_uuid(),
        'David',
        'Planner',
        '$2a$10$hashedpassword8',
        '0898901234',
        'planner.david@email.com',
        'Johannesburg',
        'Event Planning',
        3500.00,
        500.00,
        4.7,
        true,
        ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
        '{"start_time": "09:00", "end_time": "17:00", "break_start": "12:00", "break_end": "13:00", "consultation_hours": "flexible", "full_service": true}'::jsonb,
        'Making Your Vision Reality',
        'Full-service event planning and coordination. From concept to execution, we handle every detail of your special day.'
    )
ON CONFLICT (service_provider_email) DO NOTHING;

-- Step 5: Verify the updates
SELECT 
    'Service Providers with Operating Days' as status,
    COUNT(*) as count
FROM service_provider 
WHERE service_provider_operating_days IS NOT NULL;

SELECT 
    'Service Providers with Operating Times' as status,
    COUNT(*) as count
FROM service_provider 
WHERE service_provider_operating_times IS NOT NULL;

-- Step 6: Show sample data
SELECT 
    service_provider_name || ' ' || service_provider_surname as provider_name,
    service_provider_service_type,
    service_provider_operating_days,
    service_provider_operating_times,
    service_provider_base_rate,
    service_provider_rating
FROM service_provider
WHERE service_provider_operating_days IS NOT NULL
ORDER BY service_provider_rating DESC
LIMIT 10;

