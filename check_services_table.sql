-- Check what services exist in the service table
-- Run this to see the actual service data

SELECT 
    service_id,
    service_name,
    service_description
FROM service 
ORDER BY service_name;

-- Also check if there are any services with names that match our string IDs
SELECT 
    service_id,
    service_name,
    service_description
FROM service 
WHERE service_name ILIKE '%photo%' 
   OR service_name ILIKE '%catering%'
   OR service_name ILIKE '%dj%'
   OR service_name ILIKE '%decoration%'
   OR service_name ILIKE '%venue%'
   OR service_name ILIKE '%florist%'
   OR service_name ILIKE '%makeup%'
   OR service_name ILIKE '%mc%'
   OR service_name ILIKE '%security%'
   OR service_name ILIKE '%sound%'
   OR service_name ILIKE '%stage%'
ORDER BY service_name;
