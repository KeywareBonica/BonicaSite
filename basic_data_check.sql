-- Basic data existence check
SELECT 'Checking bookings...' as status;
SELECT COUNT(*) as booking_count FROM booking;

SELECT 'Checking events...' as status;  
SELECT COUNT(*) as event_count FROM event;

SELECT 'Checking clients...' as status;
SELECT COUNT(*) as client_count FROM client;

SELECT 'Checking service providers...' as status;
SELECT COUNT(*) as service_provider_count FROM service_provider;
