-- Create basic services in the database
-- Run this in your Supabase SQL editor

-- Insert basic services if they don't exist
-- Note: Using the correct service table schema (service_id, service_name, service_type, service_description)
INSERT INTO service (service_id, service_name, service_type, service_description)
VALUES 
    (gen_random_uuid(), 'Makeup Artist', 'Makeup Artist', 'Professional makeup services for events'),
    (gen_random_uuid(), 'Photographer', 'Photographer', 'Professional photography services'),
    (gen_random_uuid(), 'Caterer', 'Caterer', 'Food and beverage services'),
    (gen_random_uuid(), 'DJ', 'DJ', 'Music and entertainment services'),
    (gen_random_uuid(), 'Decorator', 'Decorator', 'Event decoration and styling'),
    (gen_random_uuid(), 'Florist', 'Florist', 'Flower arrangements and bouquets'),
    (gen_random_uuid(), 'Musician', 'Musician', 'Live music performances'),
    (gen_random_uuid(), 'Hair Stylist', 'Hair Styling', 'Professional hair styling services'),
    (gen_random_uuid(), 'Photography', 'Photography', 'Professional photography'),
    (gen_random_uuid(), 'Catering', 'Catering', 'Food and beverage'),
    (gen_random_uuid(), 'Decoration', 'Decoration', 'Event decoration'),
    (gen_random_uuid(), 'Flowers', 'Flowers', 'Flower arrangements'),
    (gen_random_uuid(), 'Music', 'Music', 'Live music')
ON CONFLICT (service_name) DO NOTHING;

-- Verify services were created
SELECT service_id, service_name, service_type FROM service ORDER BY service_name;
