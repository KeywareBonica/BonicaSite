-- =====================================================
-- FIX NULL OPERATING TIMES AND DAYS IN DATABASE
-- =====================================================
-- This script updates existing service providers who have NULL values
-- for operating_times and operating_days fields

-- First, let's see what we're working with
SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_operating_days,
    service_provider_operating_times,
    service_provider_service_type
FROM service_provider 
WHERE service_provider_operating_days IS NULL 
   OR service_provider_operating_times IS NULL;

-- =====================================================
-- UPDATE OPERATING DAYS AND TIMES FOR EXISTING PROVIDERS
-- =====================================================

-- Update service providers with NULL operating days to have default working days
UPDATE service_provider 
SET service_provider_operating_days = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
WHERE service_provider_operating_days IS NULL;

-- Update service providers with NULL operating times to have default business hours
UPDATE service_provider 
SET service_provider_operating_times = '{"start": "08:00", "end": "18:00"}'::jsonb
WHERE service_provider_operating_times IS NULL;

-- =====================================================
-- VERIFY THE UPDATES
-- =====================================================

-- Check that all service providers now have operating data
SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_operating_days,
    service_provider_operating_times,
    service_provider_service_type
FROM service_provider 
ORDER BY service_provider_name, service_provider_surname;

-- Count how many were updated
SELECT 
    COUNT(*) as total_providers,
    COUNT(service_provider_operating_days) as providers_with_days,
    COUNT(service_provider_operating_times) as providers_with_times
FROM service_provider;

-- =====================================================
-- ALTERNATIVE: SET SERVICE-SPECIFIC OPERATING HOURS
-- =====================================================

-- If you want different operating hours based on service type, uncomment below:

/*
-- DJ Services - Evening hours
UPDATE service_provider 
SET service_provider_operating_times = '{"start": "18:00", "end": "02:00"}'::jsonb,
    service_provider_operating_days = ARRAY['Friday', 'Saturday', 'Sunday']
WHERE service_provider_service_type ILIKE '%dj%' 
   OR service_provider_service_type ILIKE '%music%';

-- Photography - Flexible hours
UPDATE service_provider 
SET service_provider_operating_times = '{"start": "06:00", "end": "20:00"}'::jsonb,
    service_provider_operating_days = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
WHERE service_provider_service_type ILIKE '%photo%' 
   OR service_provider_service_type ILIKE '%camera%';

-- Catering - Morning to afternoon
UPDATE service_provider 
SET service_provider_operating_times = '{"start": "07:00", "end": "16:00"}'::jsonb,
    service_provider_operating_days = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
WHERE service_provider_service_type ILIKE '%cater%' 
   OR service_provider_service_type ILIKE '%food%';

-- Makeup/Hair - Standard business hours
UPDATE service_provider 
SET service_provider_operating_times = '{"start": "09:00", "end": "17:00"}'::jsonb,
    service_provider_operating_days = ARRAY['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
WHERE service_provider_service_type ILIKE '%makeup%' 
   OR service_provider_service_type ILIKE '%hair%'
   OR service_provider_service_type ILIKE '%beauty%';
*/

-- =====================================================
-- FINAL VERIFICATION
-- =====================================================

-- Show final results
SELECT 
    'SUCCESS: All service providers now have operating data' as status,
    COUNT(*) as total_providers,
    COUNT(CASE WHEN service_provider_operating_days IS NOT NULL THEN 1 END) as providers_with_days,
    COUNT(CASE WHEN service_provider_operating_times IS NOT NULL THEN 1 END) as providers_with_times
FROM service_provider;
