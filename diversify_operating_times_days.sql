-- =====================================================
-- DIVERSIFY OPERATING TIMES AND DAYS FOR EXISTING PROVIDERS
-- =====================================================
-- This script updates existing service providers to have varied and realistic
-- operating schedules instead of the same default values

-- First, let's see current state
SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_operating_days,
    service_provider_operating_times,
    service_provider_service_type
FROM service_provider 
ORDER BY service_provider_name, service_provider_surname;

-- =====================================================
-- DIVERSIFY BY SERVICE TYPE AND PROVIDER
-- =====================================================

-- DJ Services - Weekend and Evening Focus
UPDATE service_provider 
SET service_provider_operating_days = ARRAY['Friday', 'Saturday', 'Sunday'],
    service_provider_operating_times = '{"start": "18:00", "end": "02:00"}'::jsonb
WHERE service_provider_service_type ILIKE '%dj%' 
   OR service_provider_service_type ILIKE '%music%'
   OR service_provider_service_type ILIKE '%sound%';

-- Photography - Flexible Weekend and Weekday Schedule
UPDATE service_provider 
SET service_provider_operating_days = ARRAY['Monday', 'Wednesday', 'Friday', 'Saturday', 'Sunday'],
    service_provider_operating_times = '{"start": "07:00", "end": "19:00"}'::jsonb
WHERE service_provider_service_type ILIKE '%photo%' 
   OR service_provider_service_type ILIKE '%camera%'
   OR service_provider_service_type ILIKE '%photography%';

-- Catering - Weekday Business Focus
UPDATE service_provider 
SET service_provider_operating_days = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
    service_provider_operating_times = '{"start": "06:00", "end": "15:00"}'::jsonb
WHERE service_provider_service_type ILIKE '%cater%' 
   OR service_provider_service_type ILIKE '%food%'
   OR service_provider_service_type ILIKE '%cooking%';

-- Makeup/Hair - Weekend Wedding Focus
UPDATE service_provider 
SET service_provider_operating_days = ARRAY['Thursday', 'Friday', 'Saturday', 'Sunday'],
    service_provider_operating_times = '{"start": "08:00", "end": "17:00"}'::jsonb
WHERE service_provider_service_type ILIKE '%makeup%' 
   OR service_provider_service_type ILIKE '%hair%'
   OR service_provider_service_type ILIKE '%beauty%';

-- Event Planning - Full Week Coverage
UPDATE service_provider 
SET service_provider_operating_days = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
    service_provider_operating_times = '{"start": "09:00", "end": "18:00"}'::jsonb
WHERE service_provider_service_type ILIKE '%event%' 
   OR service_provider_service_type ILIKE '%planning%'
   OR service_provider_service_type ILIKE '%coordinat%';

-- Decor/Flowers - Weekend and Weekday Mix
UPDATE service_provider 
SET service_provider_operating_days = ARRAY['Tuesday', 'Thursday', 'Saturday', 'Sunday'],
    service_provider_operating_times = '{"start": "08:30", "end": "16:30"}'::jsonb
WHERE service_provider_service_type ILIKE '%decor%' 
   OR service_provider_service_type ILIKE '%flower%'
   OR service_provider_service_type ILIKE '%floral%';

-- Videography - Flexible Schedule
UPDATE service_provider 
SET service_provider_operating_days = ARRAY['Monday', 'Wednesday', 'Friday', 'Saturday', 'Sunday'],
    service_provider_operating_times = '{"start": "09:00", "end": "20:00"}'::jsonb
WHERE service_provider_service_type ILIKE '%video%' 
   OR service_provider_service_type ILIKE '%film%'
   OR service_provider_service_type ILIKE '%cinematography%';

-- =====================================================
-- ADDITIONAL DIVERSIFICATION FOR REMAINING PROVIDERS
-- =====================================================

-- For any remaining providers with default values, give them varied schedules
-- Group 1: Early morning providers (first 3)
UPDATE service_provider 
SET service_provider_operating_days = ARRAY['Monday', 'Wednesday', 'Friday', 'Saturday'],
    service_provider_operating_times = '{"start": "06:00", "end": "14:00"}'::jsonb
WHERE service_provider_id IN (
    SELECT service_provider_id 
    FROM service_provider 
    WHERE service_provider_operating_days = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
      AND service_provider_operating_times = '{"start": "08:00", "end": "18:00"}'::jsonb
    ORDER BY service_provider_id
    LIMIT 3
);

-- Group 2: Late evening providers (next 3)
UPDATE service_provider 
SET service_provider_operating_days = ARRAY['Tuesday', 'Thursday', 'Saturday', 'Sunday'],
    service_provider_operating_times = '{"start": "14:00", "end": "22:00"}'::jsonb
WHERE service_provider_id IN (
    SELECT service_provider_id 
    FROM service_provider 
    WHERE service_provider_operating_days = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
      AND service_provider_operating_times = '{"start": "08:00", "end": "18:00"}'::jsonb
    ORDER BY service_provider_id
    OFFSET 3 LIMIT 3
);

-- Group 3: Weekend-only providers (next 2)
UPDATE service_provider 
SET service_provider_operating_days = ARRAY['Friday', 'Saturday', 'Sunday'],
    service_provider_operating_times = '{"start": "10:00", "end": "19:00"}'::jsonb
WHERE service_provider_id IN (
    SELECT service_provider_id 
    FROM service_provider 
    WHERE service_provider_operating_days = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
      AND service_provider_operating_times = '{"start": "08:00", "end": "18:00"}'::jsonb
    ORDER BY service_provider_id
    OFFSET 6 LIMIT 2
);

-- Group 4: Weekday-only providers (next 2)
UPDATE service_provider 
SET service_provider_operating_days = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
    service_provider_operating_times = '{"start": "07:30", "end": "16:30"}'::jsonb
WHERE service_provider_id IN (
    SELECT service_provider_id 
    FROM service_provider 
    WHERE service_provider_operating_days = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
      AND service_provider_operating_times = '{"start": "08:00", "end": "18:00"}'::jsonb
    ORDER BY service_provider_id
    OFFSET 8 LIMIT 2
);

-- Group 5: Flexible providers (remaining)
UPDATE service_provider 
SET service_provider_operating_days = ARRAY['Monday', 'Wednesday', 'Friday', 'Saturday'],
    service_provider_operating_times = '{"start": "11:00", "end": "20:00"}'::jsonb
WHERE service_provider_operating_days = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  AND service_provider_operating_times = '{"start": "08:00", "end": "18:00"}'::jsonb;

-- =====================================================
-- VERIFY DIVERSIFICATION RESULTS
-- =====================================================

-- Show diversified operating schedules
SELECT 
    service_provider_name,
    service_provider_surname,
    service_provider_service_type,
    service_provider_operating_days,
    service_provider_operating_times
FROM service_provider 
ORDER BY service_provider_service_type, service_provider_name;

-- Count different operating day combinations
SELECT 
    service_provider_operating_days,
    COUNT(*) as provider_count
FROM service_provider 
GROUP BY service_provider_operating_days
ORDER BY provider_count DESC;

-- Count different operating time combinations
SELECT 
    service_provider_operating_times,
    COUNT(*) as provider_count
FROM service_provider 
GROUP BY service_provider_operating_times
ORDER BY provider_count DESC;

-- Summary statistics
SELECT 
    'DIVERSIFICATION COMPLETE' as status,
    COUNT(*) as total_providers,
    COUNT(DISTINCT service_provider_operating_days) as unique_day_combinations,
    COUNT(DISTINCT service_provider_operating_times) as unique_time_combinations
FROM service_provider;
