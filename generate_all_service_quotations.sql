-- Generate quotations for all 30 services
-- Dates: October 10-12, 2025
-- At least 3 quotations per service

-- First, ensure we have service providers for each service type
-- Insert service providers if they don't exist
INSERT INTO service_provider (
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_password,
    service_provider_contact,
    service_provider_email,
    service_provider_location,
    service_provider_base_rate,
    service_provider_overtime_rate,
    service_provider_rating,
    service_provider_verification,
    service_id
) VALUES 
-- Beauty Services Providers
(gen_random_uuid(), 'Sarah', 'Johnson', '$2a$10$hashedpassword1', '0821234567', 'sarah.johnson@beauty.com', 'Johannesburg', 250.00, 50.00, 4.8, true, (SELECT service_id FROM service WHERE service_name = 'Hair Styling & Makeup' LIMIT 1)),
(gen_random_uuid(), 'Emma', 'Wilson', '$2a$10$hashedpassword2', '0832345678', 'emma.wilson@beauty.com', 'Cape Town', 300.00, 60.00, 4.9, true, (SELECT service_id FROM service WHERE service_name = 'Makeup & Hair' LIMIT 1)),
(gen_random_uuid(), 'Lisa', 'Davis', '$2a$10$hashedpassword3', '0843456789', 'lisa.davis@beauty.com', 'Durban', 200.00, 40.00, 4.7, true, (SELECT service_id FROM service WHERE service_name = 'Makeup Artist' LIMIT 1)),
(gen_random_uuid(), 'Anna', 'Martinez', '$2a$10$hashedpassword4', '0854567890', 'anna.martinez@beauty.com', 'Pretoria', 280.00, 55.00, 4.6, true, (SELECT service_id FROM service WHERE service_name = 'Hair Styling' LIMIT 1)),
(gen_random_uuid(), 'Maria', 'Garcia', '$2a$10$hashedpassword5', '0865678901', 'maria.garcia@beauty.com', 'Port Elizabeth', 220.00, 45.00, 4.8, true, (SELECT service_id FROM service WHERE service_name = 'Hair Stylist' LIMIT 1)),
(gen_random_uuid(), 'Jennifer', 'Brown', '$2a$10$hashedpassword6', '0876789012', 'jennifer.brown@beauty.com', 'Bloemfontein', 350.00, 70.00, 4.9, true, (SELECT service_id FROM service WHERE service_name = 'Photographer' LIMIT 1)),

-- Media Services Providers
(gen_random_uuid(), 'David', 'Smith', '$2a$10$hashedpassword7', '0887890123', 'david.smith@media.com', 'Johannesburg', 800.00, 150.00, 4.8, true, (SELECT service_id FROM service WHERE service_name = 'Photography' LIMIT 1)),
(gen_random_uuid(), 'Michael', 'Johnson', '$2a$10$hashedpassword8', '0898901234', 'michael.johnson@media.com', 'Cape Town', 1200.00, 200.00, 4.9, true, (SELECT service_id FROM service WHERE service_name = 'Videography' LIMIT 1)),

-- Entertainment Services Providers
(gen_random_uuid(), 'James', 'Wilson', '$2a$10$hashedpassword9', '0909012345', 'james.wilson@entertainment.com', 'Durban', 400.00, 80.00, 4.7, true, (SELECT service_id FROM service WHERE service_name = 'DJ Services' LIMIT 1)),
(gen_random_uuid(), 'Robert', 'Anderson', '$2a$10$hashedpassword10', '0910123456', 'robert.anderson@entertainment.com', 'Pretoria', 350.00, 70.00, 4.8, true, (SELECT service_id FROM service WHERE service_name = 'MC' LIMIT 1)),
(gen_random_uuid(), 'William', 'Taylor', '$2a$10$hashedpassword11', '0921234567', 'william.taylor@entertainment.com', 'Port Elizabeth', 300.00, 60.00, 4.6, true, (SELECT service_id FROM service WHERE service_name = 'Photo Booth' LIMIT 1)),
(gen_random_uuid(), 'Richard', 'Thomas', '$2a$10$hashedpassword12', '0932345678', 'richard.thomas@entertainment.com', 'Bloemfontein', 500.00, 100.00, 4.9, true, (SELECT service_id FROM service WHERE service_name = 'Musician' LIMIT 1)),
(gen_random_uuid(), 'Charles', 'Jackson', '$2a$10$hashedpassword13', '0943456789', 'charles.jackson@entertainment.com', 'Polokwane', 380.00, 75.00, 4.7, true, (SELECT service_id FROM service WHERE service_name = 'DJ' LIMIT 1)),
(gen_random_uuid(), 'Thomas', 'White', '$2a$10$hashedpassword14', '0954567890', 'thomas.white@entertainment.com', 'Nelspruit', 450.00, 90.00, 4.8, true, (SELECT service_id FROM service WHERE service_name = 'Music' LIMIT 1)),

-- Food & Beverage Services Providers
(gen_random_uuid(), 'Christopher', 'Harris', '$2a$10$hashedpassword15', '0965678901', 'christopher.harris@catering.com', 'Johannesburg', 150.00, 30.00, 4.8, true, (SELECT service_id FROM service WHERE service_name = 'Catering' LIMIT 1)),
(gen_random_uuid(), 'Daniel', 'Martin', '$2a$10$hashedpassword16', '0976789012', 'daniel.martin@catering.com', 'Cape Town', 180.00, 35.00, 4.9, true, (SELECT service_id FROM service WHERE service_name = 'Caterer' LIMIT 1)),

-- Design Services Providers
(gen_random_uuid(), 'Matthew', 'Thompson', '$2a$10$hashedpassword17', '0987890123', 'matthew.thompson@design.com', 'Durban', 200.00, 40.00, 4.7, true, (SELECT service_id FROM service WHERE service_name = 'Decoration' LIMIT 1)),
(gen_random_uuid(), 'Anthony', 'Garcia', '$2a$10$hashedpassword18', '0998901234', 'anthony.garcia@design.com', 'Pretoria', 120.00, 25.00, 4.8, true, (SELECT service_id FROM service WHERE service_name = 'Florist' LIMIT 1)),
(gen_random_uuid(), 'Mark', 'Martinez', '$2a$10$hashedpassword19', '1009012345', 'mark.martinez@design.com', 'Port Elizabeth', 400.00, 80.00, 4.9, true, (SELECT service_id FROM service WHERE service_name = 'Stage Design' LIMIT 1)),
(gen_random_uuid(), 'Donald', 'Robinson', '$2a$10$hashedpassword20', '1010123456', 'donald.robinson@design.com', 'Bloemfontein', 180.00, 35.00, 4.6, true, (SELECT service_id FROM service WHERE service_name = 'Decorator' LIMIT 1)),
(gen_random_uuid(), 'Steven', 'Clark', '$2a$10$hashedpassword21', '1021234567', 'steven.clark@design.com', 'Polokwane', 100.00, 20.00, 4.7, true, (SELECT service_id FROM service WHERE service_name = 'Flowers' LIMIT 1)),

-- Technical Services Providers
(gen_random_uuid(), 'Paul', 'Rodriguez', '$2a$10$hashedpassword22', '1032345678', 'paul.rodriguez@technical.com', 'Nelspruit', 300.00, 60.00, 4.8, true, (SELECT service_id FROM service WHERE service_name = 'Sound System' LIMIT 1)),
(gen_random_uuid(), 'Andrew', 'Lewis', '$2a$10$hashedpassword23', '1043456789', 'andrew.lewis@technical.com', 'Johannesburg', 250.00, 50.00, 4.9, true, (SELECT service_id FROM service WHERE service_name = 'Lighting' LIMIT 1)),

-- Venue Services Providers
(gen_random_uuid(), 'Joshua', 'Lee', '$2a$10$hashedpassword24', '1054567890', 'joshua.lee@venue.com', 'Cape Town', 500.00, 100.00, 4.8, true, (SELECT service_id FROM service WHERE service_name = 'Venue' LIMIT 1)),

-- Security Services Providers
(gen_random_uuid(), 'Kenneth', 'Walker', '$2a$10$hashedpassword25', '1065678901', 'kenneth.walker@security.com', 'Durban', 80.00, 15.00, 4.7, true, (SELECT service_id FROM service WHERE service_name = 'Security' LIMIT 1)),

-- Planning Services Providers
(gen_random_uuid(), 'Kevin', 'Hall', '$2a$10$hashedpassword26', '1076789012', 'kevin.hall@planning.com', 'Pretoria', 200.00, 40.00, 4.9, true, (SELECT service_id FROM service WHERE service_name = 'Event Planning' LIMIT 1))

ON CONFLICT (service_provider_email) DO NOTHING;

-- Create job carts for each service
WITH job_carts AS (
    INSERT INTO job_cart (
        job_cart_id,
        client_id,
        service_id,
        event_id,
        job_cart_item,
        job_cart_details,
        job_cart_status,
        job_cart_created_date,
        job_cart_created_time
    ) VALUES 
    -- Beauty Services Job Carts
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Hair Styling & Makeup' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Hair Styling & Makeup', 'Professional hair styling and makeup services for special event', 'accepted', '2025-10-10', '09:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Hair Styling & Makeup' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Hair Styling & Makeup', 'Bridal hair styling and makeup package', 'accepted', '2025-10-11', '10:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Hair Styling & Makeup' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Hair Styling & Makeup', 'Party hair styling and makeup for 5 people', 'accepted', '2025-10-12', '11:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Makeup & Hair' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Makeup & Hair', 'Complete makeup and hair styling service', 'accepted', '2025-10-10', '08:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Makeup & Hair' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Makeup & Hair', 'Wedding makeup and hair styling package', 'accepted', '2025-10-11', '09:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Makeup & Hair' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Makeup & Hair', 'Evening event makeup and hair styling', 'accepted', '2025-10-12', '10:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Makeup Artist' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Makeup Artist', 'Professional makeup artist services', 'accepted', '2025-10-10', '07:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Makeup Artist' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Makeup Artist', 'Bridal makeup artist services', 'accepted', '2025-10-11', '08:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Makeup Artist' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Makeup Artist', 'Party makeup for 8 people', 'accepted', '2025-10-12', '09:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Hair Styling' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Hair Styling', 'Professional hair styling services', 'accepted', '2025-10-10', '06:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Hair Styling' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Hair Styling', 'Wedding hair styling package', 'accepted', '2025-10-11', '07:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Hair Styling' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Hair Styling', 'Event hair styling for 6 people', 'accepted', '2025-10-12', '08:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Hair Stylist' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Hair Stylist', 'Professional hair stylist services', 'accepted', '2025-10-10', '05:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Hair Stylist' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Hair Stylist', 'Bridal hair stylist services', 'accepted', '2025-10-11', '06:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Hair Stylist' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Hair Stylist', 'Party hair styling for 4 people', 'accepted', '2025-10-12', '07:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Photographer' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Photographer', 'Professional photography services', 'accepted', '2025-10-10', '14:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Photographer' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Photographer', 'Wedding photography package', 'accepted', '2025-10-11', '15:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Photographer' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Photographer', 'Event photography for 6 hours', 'accepted', '2025-10-12', '16:00:00'),
    
    -- Media Services Job Carts
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Photography' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Photography', 'Professional event photography', 'accepted', '2025-10-10', '13:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Photography' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Photography', 'Wedding photography with editing', 'accepted', '2025-10-11', '14:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Photography' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Photography', 'Corporate event photography', 'accepted', '2025-10-12', '15:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Videography' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Videography', 'Professional event videography', 'accepted', '2025-10-10', '12:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Videography' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Videography', 'Wedding videography with highlights', 'accepted', '2025-10-11', '13:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Videography' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Videography', 'Corporate event videography', 'accepted', '2025-10-12', '14:00:00'),
    
    -- Entertainment Services Job Carts
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'DJ Services' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'DJ Services', 'Professional DJ services with sound system', 'accepted', '2025-10-10', '18:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'DJ Services' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'DJ Services', 'Wedding DJ with music library', 'accepted', '2025-10-11', '19:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'DJ Services' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'DJ Services', 'Party DJ with lighting effects', 'accepted', '2025-10-12', '20:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'MC' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'MC', 'Professional MC services', 'accepted', '2025-10-10', '17:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'MC' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'MC', 'Wedding MC with ceremony coordination', 'accepted', '2025-10-11', '18:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'MC' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'MC', 'Corporate event MC services', 'accepted', '2025-10-12', '19:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Photo Booth' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Photo Booth', 'Photo booth rental with props', 'accepted', '2025-10-10', '16:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Photo Booth' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Photo Booth', 'Wedding photo booth with instant printing', 'accepted', '2025-10-11', '17:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Photo Booth' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Photo Booth', 'Party photo booth with digital gallery', 'accepted', '2025-10-12', '18:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Musician' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Musician', 'Live music performance', 'accepted', '2025-10-10', '15:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Musician' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Musician', 'Wedding ceremony music', 'accepted', '2025-10-11', '16:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Musician' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Musician', 'Corporate event live music', 'accepted', '2025-10-12', '17:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'DJ' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'DJ', 'Professional DJ services', 'accepted', '2025-10-10', '14:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'DJ' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'DJ', 'Wedding DJ with sound system', 'accepted', '2025-10-11', '15:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'DJ' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'DJ', 'Party DJ with music library', 'accepted', '2025-10-12', '16:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Music' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Music', 'Live music entertainment', 'accepted', '2025-10-10', '13:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Music' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Music', 'Wedding music performance', 'accepted', '2025-10-11', '14:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Music' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Music', 'Corporate event music', 'accepted', '2025-10-12', '15:00:00'),
    
    -- Food & Beverage Services Job Carts
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Catering' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Catering', 'Professional catering for 50 guests', 'accepted', '2025-10-10', '11:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Catering' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Catering', 'Wedding catering with 3-course meal', 'accepted', '2025-10-11', '12:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Catering' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Catering', 'Corporate event catering for 100 guests', 'accepted', '2025-10-12', '13:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Caterer' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Caterer', 'Food and beverage services', 'accepted', '2025-10-10', '10:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Caterer' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Caterer', 'Wedding caterer with full service', 'accepted', '2025-10-11', '11:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Caterer' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Caterer', 'Party catering with beverages', 'accepted', '2025-10-12', '12:00:00'),
    
    -- Design Services Job Carts
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Decoration' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Decoration', 'Event decoration and floral arrangements', 'accepted', '2025-10-10', '09:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Decoration' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Decoration', 'Wedding decoration with centerpieces', 'accepted', '2025-10-11', '10:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Decoration' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Decoration', 'Corporate event decoration', 'accepted', '2025-10-12', '11:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Florist' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Florist', 'Beautiful floral arrangements', 'accepted', '2025-10-10', '08:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Florist' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Florist', 'Wedding florist with bridal bouquet', 'accepted', '2025-10-11', '09:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Florist' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Florist', 'Event florist with centerpieces', 'accepted', '2025-10-12', '10:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Stage Design' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Stage Design', 'Custom stage design and setup', 'accepted', '2025-10-10', '07:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Stage Design' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Stage Design', 'Wedding stage design with backdrop', 'accepted', '2025-10-11', '08:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Stage Design' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Stage Design', 'Corporate event stage design', 'accepted', '2025-10-12', '09:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Decorator' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Decorator', 'Event decoration and styling', 'accepted', '2025-10-10', '06:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Decorator' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Decorator', 'Wedding decorator with theme', 'accepted', '2025-10-11', '07:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Decorator' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Decorator', 'Party decoration services', 'accepted', '2025-10-12', '08:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Flowers' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Flowers', 'Flower arrangements for event', 'accepted', '2025-10-10', '05:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Flowers' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Flowers', 'Wedding flower arrangements', 'accepted', '2025-10-11', '06:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Flowers' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Flowers', 'Event flower centerpieces', 'accepted', '2025-10-12', '07:00:00'),
    
    -- Technical Services Job Carts
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Sound System' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Sound System', 'Premium sound system rental', 'accepted', '2025-10-10', '04:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Sound System' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Sound System', 'Wedding sound system with microphones', 'accepted', '2025-10-11', '05:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Sound System' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Sound System', 'Corporate event sound system', 'accepted', '2025-10-12', '06:00:00'),
    
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Lighting' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Lighting', 'Professional lighting services', 'accepted', '2025-10-10', '03:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Lighting' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Lighting', 'Wedding lighting with effects', 'accepted', '2025-10-11', '04:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Lighting' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Lighting', 'Corporate event lighting', 'accepted', '2025-10-12', '05:00:00'),
    
    -- Venue Services Job Carts
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Venue' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Venue', 'Premium venue rental', 'accepted', '2025-10-10', '02:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Venue' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Venue', 'Wedding venue with amenities', 'accepted', '2025-10-11', '03:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Venue' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Venue', 'Corporate event venue rental', 'accepted', '2025-10-12', '04:00:00'),
    
    -- Security Services Job Carts
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Security' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Security', 'Event security services', 'accepted', '2025-10-10', '01:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Security' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Security', 'Wedding security with crowd management', 'accepted', '2025-10-11', '02:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Security' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Security', 'Corporate event security', 'accepted', '2025-10-12', '03:00:00'),
    
    -- Planning Services Job Carts
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Event Planning' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Event Planning', 'Complete event planning services', 'accepted', '2025-10-10', '00:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Event Planning' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Event Planning', 'Wedding planning and coordination', 'accepted', '2025-10-11', '01:00:00'),
    (gen_random_uuid(), (SELECT client_id FROM client LIMIT 1), (SELECT service_id FROM service WHERE service_name = 'Event Planning' LIMIT 1), (SELECT event_id FROM event LIMIT 1), 'Event Planning', 'Corporate event planning', 'accepted', '2025-10-12', '02:00:00')
    
    RETURNING job_cart_id, service_id, job_cart_item
),
-- Generate quotations for all job carts (limited to 3 per service)
quotations AS (
    INSERT INTO quotation (
        quotation_id,
        service_provider_id,
        job_cart_id,
        quotation_price,
        quotation_details,
        quotation_file_path,
        quotation_file_name,
        quotation_submission_date,
        quotation_submission_time,
        quotation_status
    )
    SELECT 
        gen_random_uuid() as quotation_id,
        sp.service_provider_id,
        jc.job_cart_id,
        CASE 
            -- Beauty Services Pricing
            WHEN jc.job_cart_item = 'Hair Styling & Makeup' THEN 1800.00 + ((RANDOM() * 400) - 200) -- R1,600-R2,200
            WHEN jc.job_cart_item = 'Makeup & Hair' THEN 2200.00 + ((RANDOM() * 600) - 300) -- R1,900-R2,500
            WHEN jc.job_cart_item = 'Makeup Artist' THEN 1200.00 + ((RANDOM() * 400) - 200) -- R1,000-R1,400
            WHEN jc.job_cart_item = 'Hair Styling' THEN 1000.00 + ((RANDOM() * 300) - 150) -- R850-R1,150
            WHEN jc.job_cart_item = 'Hair Stylist' THEN 1100.00 + ((RANDOM() * 300) - 150) -- R950-R1,250
            WHEN jc.job_cart_item = 'Photographer' THEN 3500.00 + ((RANDOM() * 1000) - 500) -- R3,000-R4,000
            
            -- Media Services Pricing
            WHEN jc.job_cart_item = 'Photography' THEN 4500.00 + ((RANDOM() * 1500) - 750) -- R3,750-R5,250
            WHEN jc.job_cart_item = 'Videography' THEN 6500.00 + ((RANDOM() * 2000) - 1000) -- R5,500-R7,500
            
            -- Entertainment Services Pricing
            WHEN jc.job_cart_item = 'DJ Services' THEN 1800.00 + ((RANDOM() * 600) - 300) -- R1,500-R2,100
            WHEN jc.job_cart_item = 'MC' THEN 1200.00 + ((RANDOM() * 400) - 200) -- R1,000-R1,400
            WHEN jc.job_cart_item = 'Photo Booth' THEN 1500.00 + ((RANDOM() * 500) - 250) -- R1,250-R1,750
            WHEN jc.job_cart_item = 'Musician' THEN 2200.00 + ((RANDOM() * 600) - 300) -- R1,900-R2,500
            WHEN jc.job_cart_item = 'DJ' THEN 1600.00 + ((RANDOM() * 500) - 250) -- R1,350-R1,850
            WHEN jc.job_cart_item = 'Music' THEN 2000.00 + ((RANDOM() * 600) - 300) -- R1,700-R2,300
            
            -- Food & Beverage Services Pricing
            WHEN jc.job_cart_item = 'Catering' THEN 2500.00 + ((RANDOM() * 1000) - 500) -- R2,000-R3,000
            WHEN jc.job_cart_item = 'Caterer' THEN 2200.00 + ((RANDOM() * 800) - 400) -- R1,800-R2,600
            
            -- Design Services Pricing
            WHEN jc.job_cart_item = 'Decoration' THEN 1800.00 + ((RANDOM() * 600) - 300) -- R1,500-R2,100
            WHEN jc.job_cart_item = 'Florist' THEN 800.00 + ((RANDOM() * 400) - 200) -- R600-R1,000
            WHEN jc.job_cart_item = 'Stage Design' THEN 3500.00 + ((RANDOM() * 1000) - 500) -- R3,000-R4,000
            WHEN jc.job_cart_item = 'Decorator' THEN 1500.00 + ((RANDOM() * 500) - 250) -- R1,250-R1,750
            WHEN jc.job_cart_item = 'Flowers' THEN 600.00 + ((RANDOM() * 300) - 150) -- R450-R750
            
            -- Technical Services Pricing
            WHEN jc.job_cart_item = 'Sound System' THEN 1200.00 + ((RANDOM() * 400) - 200) -- R1,000-R1,400
            WHEN jc.job_cart_item = 'Lighting' THEN 1000.00 + ((RANDOM() * 400) - 200) -- R800-R1,200
            
            -- Venue Services Pricing
            WHEN jc.job_cart_item = 'Venue' THEN 4500.00 + ((RANDOM() * 2000) - 1000) -- R3,500-R5,500
            
            -- Security Services Pricing
            WHEN jc.job_cart_item = 'Security' THEN 600.00 + ((RANDOM() * 200) - 100) -- R500-R700
            
            -- Planning Services Pricing
            WHEN jc.job_cart_item = 'Event Planning' THEN 3500.00 + ((RANDOM() * 1500) - 750) -- R2,750-R4,250
            
            ELSE 2000.00 + ((RANDOM() * 1000) - 500) -- Default range
        END as quotation_price,
        CASE 
            -- Beauty Services Details
            WHEN jc.job_cart_item = 'Hair Styling & Makeup' THEN 'Professional hair styling and makeup services for ' || (2 + (RANDOM() * 3))::int || ' people, including trial session, premium cosmetics, and touch-ups throughout the event.'
            WHEN jc.job_cart_item = 'Makeup & Hair' THEN 'Complete makeup and hair styling package for ' || (1 + (RANDOM() * 2))::int || ' people, including bridal/party makeup, hair styling, and professional consultation.'
            WHEN jc.job_cart_item = 'Makeup Artist' THEN 'Professional makeup artist services for ' || (1 + (RANDOM() * 2))::int || ' people, including trial session, touch-ups, and premium cosmetics.'
            WHEN jc.job_cart_item = 'Hair Styling' THEN 'Professional hair styling services for ' || (1 + (RANDOM() * 2))::int || ' people, including consultation, styling, and finishing products.'
            WHEN jc.job_cart_item = 'Hair Stylist' THEN 'Expert hair stylist services for ' || (1 + (RANDOM() * 2))::int || ' people, including styling, hair accessories, and professional consultation.'
            WHEN jc.job_cart_item = 'Photographer' THEN 'Professional photography services with ' || (4 + (RANDOM() * 4))::int || ' hours of coverage, ' || (200 + (RANDOM() * 200))::int || '+ edited photos, and online gallery delivery.'
            
            -- Media Services Details
            WHEN jc.job_cart_item = 'Photography' THEN 'Professional event photography with ' || (6 + (RANDOM() * 4))::int || ' hours of shooting, ' || (300 + (RANDOM() * 200))::int || '+ edited photos, and online gallery delivery.'
            WHEN jc.job_cart_item = 'Videography' THEN 'Professional videography with ' || (8 + (RANDOM() * 4))::int || ' hours of coverage, cinematic editing, highlight reel, and full event video.'
            
            -- Entertainment Services Details
            WHEN jc.job_cart_item = 'DJ Services' THEN 'Professional DJ services with ' || (4 + (RANDOM() * 4))::int || ' hours of music, premium sound system, lighting effects, and extensive music library.'
            WHEN jc.job_cart_item = 'MC' THEN 'Professional MC services for ' || (4 + (RANDOM() * 4))::int || ' hours, including ceremony coordination, announcements, and entertainment.'
            WHEN jc.job_cart_item = 'Photo Booth' THEN 'Fun photo booth rental with props, instant printing, digital gallery, and ' || (3 + (RANDOM() * 2))::int || ' hours of service.'
            WHEN jc.job_cart_item = 'Musician' THEN 'Live music performance for ' || (3 + (RANDOM() * 2))::int || ' hours, including setup, sound check, and professional equipment.'
            WHEN jc.job_cart_item = 'DJ' THEN 'Professional DJ services with ' || (4 + (RANDOM() * 4))::int || ' hours of music, sound system, and music library.'
            WHEN jc.job_cart_item = 'Music' THEN 'Live music entertainment for ' || (3 + (RANDOM() * 2))::int || ' hours, including performance and professional setup.'
            
            -- Food & Beverage Services Details
            WHEN jc.job_cart_item = 'Catering' THEN 'Delicious catering for ' || (40 + (RANDOM() * 40))::int || ' guests, including ' || (2 + (RANDOM() * 3))::int || ' course meal, beverages, and professional service staff.'
            WHEN jc.job_cart_item = 'Caterer' THEN 'Food and beverage services for ' || (30 + (RANDOM() * 30))::int || ' guests, including meal preparation, service, and cleanup.'
            
            -- Design Services Details
            WHEN jc.job_cart_item = 'Decoration' THEN 'Beautiful event decoration including floral arrangements, lighting, table settings, and venue transformation for ' || (50 + (RANDOM() * 50))::int || ' guests.'
            WHEN jc.job_cart_item = 'Florist' THEN 'Beautiful floral arrangements including bridal bouquet, centerpieces, ceremony flowers, and venue decorations.'
            WHEN jc.job_cart_item = 'Stage Design' THEN 'Custom stage design and setup including backdrop, lighting, props, and technical equipment for ' || (50 + (RANDOM() * 50))::int || ' guests.'
            WHEN jc.job_cart_item = 'Decorator' THEN 'Event decoration and styling services including theme design, setup, and venue transformation.'
            WHEN jc.job_cart_item = 'Flowers' THEN 'Flower arrangements for event including centerpieces, bouquets, and venue decorations.'
            
            -- Technical Services Details
            WHEN jc.job_cart_item = 'Sound System' THEN 'Premium sound system rental including speakers, microphones, mixing board, and technical support for ' || (4 + (RANDOM() * 4))::int || ' hours.'
            WHEN jc.job_cart_item = 'Lighting' THEN 'Professional lighting services including setup, effects, and technical support for ' || (4 + (RANDOM() * 4))::int || ' hours.'
            
            -- Venue Services Details
            WHEN jc.job_cart_item = 'Venue' THEN 'Premium venue rental for ' || (50 + (RANDOM() * 100))::int || ' guests, including setup, cleanup, and basic amenities.'
            
            -- Security Services Details
            WHEN jc.job_cart_item = 'Security' THEN 'Professional security services with ' || (2 + (RANDOM() * 2))::int || ' security personnel for ' || (6 + (RANDOM() * 4))::int || ' hours of coverage.'
            
            -- Planning Services Details
            WHEN jc.job_cart_item = 'Event Planning' THEN 'Complete event planning and coordination including vendor management, timeline creation, and day-of coordination.'
            
            ELSE 'Professional ' || jc.job_cart_item || ' services for your special event. Includes full coverage, setup, and professional delivery.'
        END as quotation_details,
        NULL as quotation_file_path, -- Will be generated by PDF generator
        jc.job_cart_item || ' Quote - ' || sp.service_provider_name || ' ' || sp.service_provider_surname || '.pdf' as quotation_file_name,
        CASE 
            WHEN jc.job_cart_item LIKE '%Hair%' OR jc.job_cart_item LIKE '%Makeup%' THEN '2025-10-10'
            WHEN jc.job_cart_item LIKE '%Photography%' OR jc.job_cart_item LIKE '%Videography%' THEN '2025-10-11'
            WHEN jc.job_cart_item LIKE '%DJ%' OR jc.job_cart_item LIKE '%Music%' OR jc.job_cart_item LIKE '%MC%' THEN '2025-10-12'
            WHEN jc.job_cart_item LIKE '%Catering%' OR jc.job_cart_item LIKE '%Caterer%' THEN '2025-10-10'
            WHEN jc.job_cart_item LIKE '%Decoration%' OR jc.job_cart_item LIKE '%Florist%' OR jc.job_cart_item LIKE '%Flowers%' THEN '2025-10-11'
            WHEN jc.job_cart_item LIKE '%Stage%' OR jc.job_cart_item LIKE '%Decorator%' THEN '2025-10-12'
            WHEN jc.job_cart_item LIKE '%Sound%' OR jc.job_cart_item LIKE '%Lighting%' THEN '2025-10-10'
            WHEN jc.job_cart_item LIKE '%Venue%' THEN '2025-10-11'
            WHEN jc.job_cart_item LIKE '%Security%' THEN '2025-10-12'
            WHEN jc.job_cart_item LIKE '%Planning%' THEN '2025-10-10'
            ELSE '2025-10-10'
        END as quotation_submission_date,
        CASE 
            WHEN jc.job_cart_item LIKE '%Hair%' OR jc.job_cart_item LIKE '%Makeup%' THEN '09:00:00'
            WHEN jc.job_cart_item LIKE '%Photography%' OR jc.job_cart_item LIKE '%Videography%' THEN '10:00:00'
            WHEN jc.job_cart_item LIKE '%DJ%' OR jc.job_cart_item LIKE '%Music%' OR jc.job_cart_item LIKE '%MC%' THEN '11:00:00'
            WHEN jc.job_cart_item LIKE '%Catering%' OR jc.job_cart_item LIKE '%Caterer%' THEN '12:00:00'
            WHEN jc.job_cart_item LIKE '%Decoration%' OR jc.job_cart_item LIKE '%Florist%' OR jc.job_cart_item LIKE '%Flowers%' THEN '13:00:00'
            WHEN jc.job_cart_item LIKE '%Stage%' OR jc.job_cart_item LIKE '%Decorator%' THEN '14:00:00'
            WHEN jc.job_cart_item LIKE '%Sound%' OR jc.job_cart_item LIKE '%Lighting%' THEN '15:00:00'
            WHEN jc.job_cart_item LIKE '%Venue%' THEN '16:00:00'
            WHEN jc.job_cart_item LIKE '%Security%' THEN '17:00:00'
            WHEN jc.job_cart_item LIKE '%Planning%' THEN '18:00:00'
            ELSE '09:00:00'
        END as quotation_submission_time,
        'confirmed' as quotation_status
    FROM job_carts jc
    CROSS JOIN service_provider sp
    WHERE sp.service_id = jc.service_id
    AND sp.service_provider_location IS NOT NULL
    -- Limit to 3 quotations per service using ROW_NUMBER()
    AND (
        SELECT COUNT(*) 
        FROM quotation q2 
        JOIN job_cart jc2 ON q2.job_cart_id = jc2.job_cart_id 
        WHERE jc2.service_id = jc.service_id 
        AND q2.service_provider_id = sp.service_provider_id
    ) < 3
    RETURNING quotation_id, job_cart_id, quotation_price, quotation_file_path, quotation_file_name
)
SELECT 
    'Quotations Generated' as status,
    COUNT(*) as total_quotations,
    COUNT(DISTINCT jc.job_cart_item) as unique_services
FROM quotations q
JOIN job_carts jc ON q.job_cart_id = jc.job_cart_id;

-- Verify the quotations were created
SELECT 
    s.service_name,
    COUNT(q.quotation_id) as quotation_count,
    MIN(q.quotation_price) as min_price,
    MAX(q.quotation_price) as max_price,
    AVG(q.quotation_price)::numeric(10,2) as avg_price
FROM quotation q
JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
JOIN service s ON jc.service_id = s.service_id
WHERE q.quotation_submission_date BETWEEN '2025-10-10' AND '2025-10-12'
GROUP BY s.service_name
ORDER BY s.service_name;

-- Create a function to filter quotations by location and price range
CREATE OR REPLACE FUNCTION get_filtered_quotations(
    p_event_location TEXT,
    p_min_price NUMERIC DEFAULT 0,
    p_max_price NUMERIC DEFAULT 999999,
    p_service_ids UUID[] DEFAULT NULL
)
RETURNS TABLE (
    quotation_id UUID,
    service_provider_id UUID,
    service_provider_name TEXT,
    service_provider_location TEXT,
    quotation_price NUMERIC,
    quotation_details TEXT,
    quotation_file_path TEXT,
    quotation_file_name TEXT,
    service_name TEXT,
    service_type TEXT,
    quotation_submission_date DATE,
    quotation_submission_time TIME
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        q.quotation_id,
        q.service_provider_id,
        sp.service_provider_name || ' ' || sp.service_provider_surname as service_provider_name,
        sp.service_provider_location,
        q.quotation_price,
        q.quotation_details,
        q.quotation_file_path,
        q.quotation_file_name,
        s.service_name,
        s.service_type,
        q.quotation_submission_date,
        q.quotation_submission_time
    FROM quotation q
    JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
    JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
    JOIN service s ON jc.service_id = s.service_id
    JOIN event e ON jc.event_id = e.event_id
    WHERE 
        -- Location filtering (case-insensitive partial match)
        LOWER(sp.service_provider_location) LIKE LOWER('%' || p_event_location || '%')
        OR LOWER(e.event_location) LIKE LOWER('%' || p_event_location || '%')
        -- Price range filtering
        AND q.quotation_price >= p_min_price
        AND q.quotation_price <= p_max_price
        -- Service filtering (if provided)
        AND (p_service_ids IS NULL OR s.service_id = ANY(p_service_ids))
        -- Only confirmed quotations
        AND q.quotation_status = 'confirmed'
        -- Recent quotations (within the specified date range)
        AND q.quotation_submission_date BETWEEN '2025-10-10' AND '2025-10-12'
    ORDER BY 
        s.service_name,
        q.quotation_price ASC
    LIMIT 3; -- Maximum 3 quotations per service
END;
$$ LANGUAGE plpgsql;

-- Create a view for easy quotation filtering
CREATE OR REPLACE VIEW quotation_with_location AS
SELECT 
    q.quotation_id,
    q.service_provider_id,
    sp.service_provider_name || ' ' || sp.service_provider_surname as service_provider_name,
    sp.service_provider_location,
    sp.service_provider_rating,
    q.quotation_price,
    q.quotation_details,
    q.quotation_file_path,
    q.quotation_file_name,
    q.quotation_submission_date,
    q.quotation_submission_time,
    q.quotation_status,
    s.service_name,
    s.service_type,
    s.service_description,
    e.event_location,
    e.event_date,
    e.event_type,
    c.client_name || ' ' || c.client_surname as client_name,
    c.client_city as client_location
FROM quotation q
JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
JOIN service s ON jc.service_id = s.service_id
JOIN event e ON jc.event_id = e.event_id
JOIN client c ON jc.client_id = c.client_id;

-- Example usage queries for testing the filtering system:

-- 1. Get quotations for Johannesburg events with price range R1000-R3000
-- SELECT * FROM get_filtered_quotations('Johannesburg', 1000, 3000);

-- 2. Get quotations for Cape Town events with any price
-- SELECT * FROM get_filtered_quotations('Cape Town', 0, 999999);

-- 3. Get quotations for specific services in Durban with price range R500-R2000
-- SELECT * FROM get_filtered_quotations('Durban', 500, 2000, ARRAY[
--     (SELECT service_id FROM service WHERE service_name = 'Photography'),
--     (SELECT service_id FROM service WHERE service_name = 'Catering')
-- ]);

-- 4. View all quotations with location information
-- SELECT 
--     service_name,
--     service_provider_name,
--     service_provider_location,
--     quotation_price,
--     event_location,
--     quotation_file_name
-- FROM quotation_with_location 
-- WHERE quotation_submission_date BETWEEN '2025-10-10' AND '2025-10-12'
-- ORDER BY service_name, quotation_price;

-- Grant permissions for the function and view
GRANT EXECUTE ON FUNCTION get_filtered_quotations TO authenticated;
GRANT SELECT ON quotation_with_location TO authenticated;
