-- Show all table counts in one result
SELECT 
    'bookings' as table_name, 
    COUNT(*) as record_count 
FROM booking
UNION ALL
SELECT 
    'events' as table_name, 
    COUNT(*) as record_count 
FROM event
UNION ALL
SELECT 
    'clients' as table_name, 
    COUNT(*) as record_count 
FROM client
UNION ALL
SELECT 
    'service_providers' as table_name, 
    COUNT(*) as record_count 
FROM service_provider;
