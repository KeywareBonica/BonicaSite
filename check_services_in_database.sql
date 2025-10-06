-- Check what services exist in the database
-- Run this to see what services are available

SELECT 
    service_id,
    service_name,
    service_description
FROM service 
ORDER BY service_name;

-- Check if we have the services we need
SELECT 
    service_id,
    service_name
FROM service 
WHERE service_name IN (
    'Photography',
    'Catering', 
    'DJ',
    'Decoration',
    'Venue',
    'Florist',
    'Makeup Artist',
    'MC',
    'Security',
    'Sound System',
    'Stage Design',
    'Photo Booth',
    'Party Favors / Gift Bags'
)
ORDER BY service_name;
