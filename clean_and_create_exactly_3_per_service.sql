-- ===============================================
-- CLEAN DATABASE AND CREATE EXACTLY 3 QUOTATIONS PER SERVICE
-- ===============================================

-- Step 1: Check current count
SELECT 'Current quotation count:' AS info, COUNT(*) AS count FROM quotation;

-- Step 2: Clean up all existing data
DELETE FROM quotation;
DELETE FROM job_cart;
DELETE FROM service_provider;

-- Step 3: Verify cleanup
SELECT 'After cleanup - quotation count:' AS info, COUNT(*) AS count FROM quotation;
SELECT 'After cleanup - job_cart count:' AS info, COUNT(*) AS count FROM job_cart;
SELECT 'After cleanup - service_provider count:' AS info, COUNT(*) AS count FROM service_provider;

-- Step 4: Ensure we have basic required data
INSERT INTO client (
    client_id, client_name, client_surname, client_password, 
    client_contact, client_email, client_city
)
SELECT 
    'c1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'John', 'Doe', 
    '$2a$10$xyz123encryptedpassword', 
    '082 555 1234', 
    'john.doe@example.com',
    'Johannesburg'
WHERE NOT EXISTS (SELECT 1 FROM client LIMIT 1);

INSERT INTO event (
    event_id, event_type, event_date, event_start_time, event_location
)
SELECT
    'e1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'Wedding', '2025-10-10', '14:00:00', 'Sandton Convention Centre'
WHERE NOT EXISTS (SELECT 1 FROM event LIMIT 1);

-- Step 5: Create job carts for ALL services
WITH existing_data AS (
    SELECT 
        (SELECT client_id FROM client LIMIT 1) as client_id,
        (SELECT event_id FROM event LIMIT 1) as event_id
)
INSERT INTO job_cart (
    job_cart_id,
    event_id,
    client_id,
    service_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
)
SELECT
    gen_random_uuid(),
    ed.event_id,
    ed.client_id,
    s.service_id,
    s.service_name,
    s.service_description,
    '2025-10-10',
    CASE 
        WHEN s.service_name = 'Hair Styling & Makeup' THEN '09:00:00'::TIME
        WHEN s.service_name = 'Photography' THEN '10:00:00'::TIME
        WHEN s.service_name = 'Videography' THEN '11:00:00'::TIME
        WHEN s.service_name = 'Catering' THEN '12:00:00'::TIME
        WHEN s.service_name = 'Decoration' THEN '13:00:00'::TIME
        WHEN s.service_name = 'DJ Services' THEN '14:00:00'::TIME
        WHEN s.service_name = 'Venue' THEN '15:00:00'::TIME
        WHEN s.service_name = 'Security' THEN '16:00:00'::TIME
        WHEN s.service_name = 'Event Planning' THEN '17:00:00'::TIME
        WHEN s.service_name = 'Florist' THEN '18:00:00'::TIME
        WHEN s.service_name = 'MC' THEN '18:30:00'::TIME
        WHEN s.service_name = 'Makeup & Hair' THEN '09:30:00'::TIME
        WHEN s.service_name = 'Makeup Artist' THEN '10:30:00'::TIME
        WHEN s.service_name = 'Sound System' THEN '11:30:00'::TIME
        WHEN s.service_name = 'Stage Design' THEN '12:30:00'::TIME
        WHEN s.service_name = 'Photo Booth' THEN '13:30:00'::TIME
        WHEN s.service_name = 'Hair Styling' THEN '14:30:00'::TIME
        WHEN s.service_name = 'Lighting' THEN '15:30:00'::TIME
        WHEN s.service_name = 'Musician' THEN '16:30:00'::TIME
        WHEN s.service_name = 'Caterer' THEN '17:30:00'::TIME
        WHEN s.service_name = 'DJ' THEN '18:00:00'::TIME
        WHEN s.service_name = 'Decorator' THEN '19:00:00'::TIME
        WHEN s.service_name = 'Flowers' THEN '19:30:00'::TIME
        WHEN s.service_name = 'Music' THEN '20:00:00'::TIME
        WHEN s.service_name = 'Photographer' THEN '20:30:00'::TIME
        WHEN s.service_name = 'Hair Stylist' THEN '21:00:00'::TIME
        ELSE '09:00:00'::TIME
    END,
    'pending',
    NOW()
FROM service s
CROSS JOIN existing_data ed
WHERE s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
);

-- Step 6: Add EXACTLY 3 service providers per service (78 total)
INSERT INTO service_provider (
    service_provider_id,
    service_id,
    service_provider_name,
    service_provider_surname,
    service_provider_password,
    service_provider_contactno,
    service_provider_email,
    service_provider_location,
    service_provider_rating,
    service_provider_service_type,
    service_provider_verification,
    created_at
)
-- Hair Styling & Makeup - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Nomsa', 'Mthembu', 'password123', '082 123 4567', 'nomsa.mthembu.hair1@email.com', 'Sandton', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling & Makeup'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Thandi', 'Nkosi', 'password123', '083 234 5678', 'thandi.nkosi.hair2@email.com', 'Rosebank', 4.6, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling & Makeup'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Zanele', 'Mthembu', 'password123', '084 345 6789', 'zanele.mthembu.hair3@email.com', 'Soweto', 4.7, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling & Makeup'

UNION ALL
-- Photography - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Sipho', 'Mthembu', 'password123', '085 456 7890', 'sipho.mthembu.photo1@email.com', 'Soweto', 4.9, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photography'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Lerato', 'Molefe', 'password123', '086 567 8901', 'lerato.molefe.photo2@email.com', 'Johannesburg', 4.7, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photography'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Mandla', 'Dlamini', 'password123', '087 678 9012', 'mandla.dlamini.photo3@email.com', 'Sandton', 4.8, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photography'

UNION ALL
-- Videography - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Zanele', 'Khumalo', 'password123', '088 789 0123', 'zanele.khumalo.video1@email.com', 'Rosebank', 4.5, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Videography'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Bongani', 'Mthembu', 'password123', '089 890 1234', 'bongani.mthembu.video2@email.com', 'Soweto', 4.9, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Videography'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Nomsa', 'Zulu', 'password123', '090 901 2345', 'nomsa.zulu.video3@email.com', 'Johannesburg', 4.6, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Videography'

UNION ALL
-- Catering - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Thabo', 'Molefe', 'password123', '091 012 3456', 'thabo.molefe.catering1@email.com', 'Sandton', 4.7, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Catering'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Precious', 'Nkosi', 'password123', '092 123 4567', 'precious.nkosi.catering2@email.com', 'Rosebank', 4.8, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Catering'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Grace', 'Van Zyl', 'password123', '093 234 5678', 'grace.vanzyl.catering3@email.com', 'Sandton', 4.9, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Catering'

UNION ALL
-- Decoration - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Samuel', 'Van Heerden', 'password123', '094 345 6789', 'samuel.vanheerden.decoration1@email.com', 'Rosebank', 4.7, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decoration'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Johan', 'Pretorius', 'password123', '095 456 7890', 'johan.pretorius.decoration2@email.com', 'Soweto', 4.6, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decoration'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Pieter', 'Botha', 'password123', '096 567 8901', 'pieter.botha.decoration3@email.com', 'Johannesburg', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decoration'

UNION ALL
-- DJ Services - 3 providers
SELECT gen_random_uuid(), s.service_id, 'DJ', 'Khaya', 'password123', '097 678 9012', 'dj.khaya.djservices1@email.com', 'Soweto', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ Services'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'DJ', 'Sbu', 'password123', '098 789 0123', 'dj.sbu.djservices2@email.com', 'Johannesburg', 4.5, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ Services'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'DJ', 'Tebogo', 'password123', '099 890 1234', 'dj.tebogo.djservices3@email.com', 'Sandton', 4.7, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ Services'

UNION ALL
-- Venue - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Sarah', 'Johnson', 'password123', '010 901 2345', 'sarah.johnson.venue1@email.com', 'Sandton', 4.9, 'Venue', true, NOW()
FROM service s WHERE s.service_name = 'Venue'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Michael', 'Smith', 'password123', '011 012 3456', 'michael.smith.venue2@email.com', 'Rosebank', 4.7, 'Venue', true, NOW()
FROM service s WHERE s.service_name = 'Venue'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Emma', 'Wilson', 'password123', '012 123 4567', 'emma.wilson.venue3@email.com', 'Soweto', 4.8, 'Venue', true, NOW()
FROM service s WHERE s.service_name = 'Venue'

UNION ALL
-- Security - 3 providers
SELECT gen_random_uuid(), s.service_id, 'David', 'Brown', 'password123', '013 234 5678', 'david.brown.security1@email.com', 'Johannesburg', 4.6, 'Security', true, NOW()
FROM service s WHERE s.service_name = 'Security'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'MC', 'Tebogo', 'password123', '014 345 6789', 'mc.tebogo.security2@email.com', 'Sandton', 4.9, 'Security', true, NOW()
FROM service s WHERE s.service_name = 'Security'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'MC', 'Lebo', 'password123', '015 456 7890', 'mc.lebo.security3@email.com', 'Rosebank', 4.7, 'Security', true, NOW()
FROM service s WHERE s.service_name = 'Security'

UNION ALL
-- Event Planning - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Amanda', 'Davis', 'password123', '016 567 8901', 'amanda.davis.eventplanning1@email.com', 'Soweto', 4.8, 'Planning', true, NOW()
FROM service s WHERE s.service_name = 'Event Planning'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Lisa', 'Anderson', 'password123', '017 678 9012', 'lisa.anderson.eventplanning2@email.com', 'Johannesburg', 4.6, 'Planning', true, NOW()
FROM service s WHERE s.service_name = 'Event Planning'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Jennifer', 'Taylor', 'password123', '018 789 0123', 'jennifer.taylor.eventplanning3@email.com', 'Sandton', 4.7, 'Planning', true, NOW()
FROM service s WHERE s.service_name = 'Event Planning'

UNION ALL
-- Florist - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Michelle', 'White', 'password123', '019 890 1234', 'michelle.white.florist1@email.com', 'Rosebank', 4.9, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Florist'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Robert', 'Jones', 'password123', '020 901 2345', 'robert.jones.florist2@email.com', 'Soweto', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Florist'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'William', 'Garcia', 'password123', '021 012 3456', 'william.garcia.florist3@email.com', 'Johannesburg', 4.5, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Florist'

UNION ALL
-- MC - 3 providers
SELECT gen_random_uuid(), s.service_id, 'James', 'Miller', 'password123', '022 123 4567', 'james.miller.mc1@email.com', 'Sandton', 4.7, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'MC'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Christopher', 'Martinez', 'password123', '023 234 5678', 'christopher.martinez.mc2@email.com', 'Rosebank', 4.8, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'MC'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Daniel', 'Rodriguez', 'password123', '024 345 6789', 'daniel.rodriguez.mc3@email.com', 'Soweto', 4.6, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'MC'

UNION ALL
-- Makeup & Hair - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Matthew', 'Lee', 'password123', '025 456 7890', 'matthew.lee.makeup1@email.com', 'Johannesburg', 4.9, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup & Hair'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Anthony', 'Perez', 'password123', '026 567 8901', 'anthony.perez.makeup2@email.com', 'Sandton', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup & Hair'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Mark', 'Thompson', 'password123', '027 678 9012', 'mark.thompson.makeup3@email.com', 'Rosebank', 4.7, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup & Hair'

UNION ALL
-- Makeup Artist - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Donald', 'Wilson', 'password123', '028 789 0123', 'donald.wilson.makeupartist1@email.com', 'Soweto', 4.6, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup Artist'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Steven', 'Anderson', 'password123', '029 890 1234', 'steven.anderson.makeupartist2@email.com', 'Johannesburg', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup Artist'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Paul', 'Thomas', 'password123', '030 901 2345', 'paul.thomas.makeupartist3@email.com', 'Sandton', 4.9, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Makeup Artist'

UNION ALL
-- Sound System - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Andrew', 'Jackson', 'password123', '031 012 3456', 'andrew.jackson.soundsystem1@email.com', 'Rosebank', 4.7, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Sound System'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Joshua', 'White', 'password123', '032 123 4567', 'joshua.white.soundsystem2@email.com', 'Soweto', 4.8, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Sound System'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Kenneth', 'Harris', 'password123', '033 234 5678', 'kenneth.harris.soundsystem3@email.com', 'Johannesburg', 4.6, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Sound System'

UNION ALL
-- Stage Design - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Kevin', 'Martin', 'password123', '034 345 6789', 'kevin.martin.stagedesign1@email.com', 'Sandton', 4.9, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Stage Design'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Brian', 'Garcia', 'password123', '035 456 7890', 'brian.garcia.stagedesign2@email.com', 'Rosebank', 4.5, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Stage Design'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'George', 'Martinez', 'password123', '036 567 8901', 'george.martinez.stagedesign3@email.com', 'Soweto', 4.7, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Stage Design'

UNION ALL
-- Photo Booth - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Timothy', 'Robinson', 'password123', '037 678 9012', 'timothy.robinson.photobooth1@email.com', 'Johannesburg', 4.8, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Photo Booth'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Ronald', 'Clark', 'password123', '038 789 0123', 'ronald.clark.photobooth2@email.com', 'Sandton', 4.6, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Photo Booth'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Jason', 'Rodriguez', 'password123', '039 890 1234', 'jason.rodriguez.photobooth3@email.com', 'Rosebank', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Photo Booth'

UNION ALL
-- Hair Styling - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Ryan', 'Lewis', 'password123', '040 901 2345', 'ryan.lewis.hairstyling1@email.com', 'Soweto', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Jacob', 'Lee', 'password123', '041 012 3456', 'jacob.lee.hairstyling2@email.com', 'Johannesburg', 4.7, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Gary', 'Walker', 'password123', '042 123 4567', 'gary.walker.hairstyling3@email.com', 'Sandton', 4.9, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Styling'

UNION ALL
-- Lighting - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Nicholas', 'Hall', 'password123', '043 234 5678', 'nicholas.hall.lighting1@email.com', 'Rosebank', 4.6, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Lighting'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Eric', 'Allen', 'password123', '044 345 6789', 'eric.allen.lighting2@email.com', 'Soweto', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Lighting'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Jonathan', 'Young', 'password123', '045 456 7890', 'jonathan.young.lighting3@email.com', 'Johannesburg', 4.7, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Lighting'

UNION ALL
-- Musician - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Brandon', 'King', 'password123', '046 567 8901', 'brandon.king.musician1@email.com', 'Sandton', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Musician'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Justin', 'Wright', 'password123', '047 678 9012', 'justin.wright.musician2@email.com', 'Rosebank', 4.7, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Musician'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Samuel', 'Lopez', 'password123', '048 789 0123', 'samuel.lopez.musician3@email.com', 'Soweto', 4.8, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Musician'

UNION ALL
-- Caterer - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Benjamin', 'Hill', 'password123', '049 890 1234', 'benjamin.hill.caterer1@email.com', 'Johannesburg', 4.8, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Caterer'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Christian', 'Scott', 'password123', '050 901 2345', 'christian.scott.caterer2@email.com', 'Sandton', 4.6, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Caterer'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Aaron', 'Green', 'password123', '051 012 3456', 'aaron.green.caterer3@email.com', 'Rosebank', 4.9, 'Food & Beverage', true, NOW()
FROM service s WHERE s.service_name = 'Caterer'

UNION ALL
-- DJ - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Logan', 'Adams', 'password123', '052 123 4567', 'logan.adams.dj1@email.com', 'Soweto', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Caleb', 'Baker', 'password123', '053 234 5678', 'caleb.baker.dj2@email.com', 'Johannesburg', 4.5, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Ryan', 'Gonzalez', 'password123', '054 345 6789', 'ryan.gonzalez.dj3@email.com', 'Sandton', 4.7, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'DJ'

UNION ALL
-- Decorator - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Nathan', 'Nelson', 'password123', '055 456 7890', 'nathan.nelson.decorator1@email.com', 'Rosebank', 4.7, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decorator'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Isaac', 'Carter', 'password123', '056 567 8901', 'isaac.carter.decorator2@email.com', 'Soweto', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decorator'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Luke', 'Mitchell', 'password123', '057 678 9012', 'luke.mitchell.decorator3@email.com', 'Johannesburg', 4.6, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Decorator'

UNION ALL
-- Flowers - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Jack', 'Perez', 'password123', '058 789 0123', 'jack.perez.flowers1@email.com', 'Sandton', 4.6, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Flowers'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Hunter', 'Roberts', 'password123', '059 890 1234', 'hunter.roberts.flowers2@email.com', 'Rosebank', 4.9, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Flowers'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Owen', 'Turner', 'password123', '060 901 2345', 'owen.turner.flowers3@email.com', 'Soweto', 4.8, 'Design', true, NOW()
FROM service s WHERE s.service_name = 'Flowers'

UNION ALL
-- Music - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Connor', 'Phillips', 'password123', '061 012 3456', 'connor.phillips.music1@email.com', 'Johannesburg', 4.8, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Music'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Cameron', 'Campbell', 'password123', '062 123 4567', 'cameron.campbell.music2@email.com', 'Sandton', 4.7, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Music'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Jeremy', 'Parker', 'password123', '063 234 5678', 'jeremy.parker.music3@email.com', 'Rosebank', 4.9, 'Entertainment', true, NOW()
FROM service s WHERE s.service_name = 'Music'

UNION ALL
-- Photographer - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Adrian', 'Evans', 'password123', '064 345 6789', 'adrian.evans.photographer1@email.com', 'Soweto', 4.9, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photographer'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Kyle', 'Edwards', 'password123', '065 456 7890', 'kyle.edwards.photographer2@email.com', 'Johannesburg', 4.6, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photographer'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Jordan', 'Collins', 'password123', '066 567 8901', 'jordan.collins.photographer3@email.com', 'Sandton', 4.8, 'Media', true, NOW()
FROM service s WHERE s.service_name = 'Photographer'

UNION ALL
-- Hair Stylist - 3 providers
SELECT gen_random_uuid(), s.service_id, 'Austin', 'Stewart', 'password123', '067 678 9012', 'austin.stewart.hairstylist1@email.com', 'Rosebank', 4.8, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Stylist'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Ethan', 'Sanchez', 'password123', '068 789 0123', 'ethan.sanchez.hairstylist2@email.com', 'Soweto', 4.7, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Stylist'
UNION ALL SELECT gen_random_uuid(), s.service_id, 'Noah', 'Morris', 'password123', '069 890 1234', 'noah.morris.hairstylist3@email.com', 'Johannesburg', 4.9, 'Beauty', true, NOW()
FROM service s WHERE s.service_name = 'Hair Stylist'

ON CONFLICT (service_provider_id) DO NOTHING;

-- Step 7: Create EXACTLY 3 quotations per service (78 total)
-- Create 1st quotation for each service
INSERT INTO quotation (
    quotation_id,
    job_cart_id,
    service_provider_id,
    service_id,
    quotation_price,
    quotation_details,
    quotation_status,
    quotation_submission_date,
    quotation_submission_time,
    quotation_file_path,
    quotation_file_name,
    created_at
)
SELECT
    gen_random_uuid(),
    jc.job_cart_id,
    sp.service_provider_id,
    jc.service_id,
    ROUND(
        (CASE 
            WHEN s.service_name = 'Hair Styling & Makeup' THEN 2500.00
            WHEN s.service_name = 'Photography' THEN 3500.00
            WHEN s.service_name = 'Videography' THEN 4500.00
            WHEN s.service_name = 'Catering' THEN 8000.00
            WHEN s.service_name = 'Decoration' THEN 3000.00
            WHEN s.service_name = 'DJ Services' THEN 2000.00
            WHEN s.service_name = 'Venue' THEN 12000.00
            WHEN s.service_name = 'Security' THEN 1500.00
            WHEN s.service_name = 'Event Planning' THEN 5000.00
            WHEN s.service_name = 'Florist' THEN 1800.00
            WHEN s.service_name = 'MC' THEN 1800.00
            WHEN s.service_name = 'Makeup & Hair' THEN 2500.00
            WHEN s.service_name = 'Makeup Artist' THEN 2500.00
            WHEN s.service_name = 'Sound System' THEN 2000.00
            WHEN s.service_name = 'Stage Design' THEN 3000.00
            WHEN s.service_name = 'Photo Booth' THEN 1000.00
            WHEN s.service_name = 'Hair Styling' THEN 2500.00
            WHEN s.service_name = 'Lighting' THEN 1500.00
            WHEN s.service_name = 'Musician' THEN 2000.00
            WHEN s.service_name = 'Caterer' THEN 8000.00
            WHEN s.service_name = 'DJ' THEN 2000.00
            WHEN s.service_name = 'Decorator' THEN 3000.00
            WHEN s.service_name = 'Flowers' THEN 1500.00
            WHEN s.service_name = 'Music' THEN 2000.00
            WHEN s.service_name = 'Photographer' THEN 3500.00
            WHEN s.service_name = 'Hair Stylist' THEN 2500.00
            ELSE 2000.00
        END) * (1 + (RANDOM() * 0.2))
    )::NUMERIC(10,2) AS quotation_price,
    'Professional ' || s.service_name || ' services for your special event.',
    'confirmed',
    '2025-10-10',
    '09:30:00'::TIME,
    'quotations/quotation_' || SUBSTRING(jc.job_cart_id::text, 1, 8) || '.pdf' AS quotation_file_path,
    'quotation_' || SUBSTRING(jc.job_cart_id::text, 1, 8) || '.pdf' AS quotation_file_name,
    NOW()
FROM job_cart jc
JOIN service s ON jc.service_id = s.service_id
JOIN service_provider sp ON sp.service_id = s.service_id
WHERE jc.job_cart_created_date = '2025-10-10'
AND jc.job_cart_status = 'pending'
ON CONFLICT (quotation_id) DO NOTHING;

-- Create 2nd quotation for each service
INSERT INTO quotation (
    quotation_id,
    job_cart_id,
    service_provider_id,
    service_id,
    quotation_price,
    quotation_details,
    quotation_status,
    quotation_submission_date,
    quotation_submission_time,
    quotation_file_path,
    quotation_file_name,
    created_at
)
SELECT
    gen_random_uuid(),
    jc.job_cart_id,
    sp2.service_provider_id,
    jc.service_id,
    ROUND(
        (CASE 
            WHEN s.service_name = 'Hair Styling & Makeup' THEN 2500.00
            WHEN s.service_name = 'Photography' THEN 3500.00
            WHEN s.service_name = 'Videography' THEN 4500.00
            WHEN s.service_name = 'Catering' THEN 8000.00
            WHEN s.service_name = 'Decoration' THEN 3000.00
            WHEN s.service_name = 'DJ Services' THEN 2000.00
            WHEN s.service_name = 'Venue' THEN 12000.00
            WHEN s.service_name = 'Security' THEN 1500.00
            WHEN s.service_name = 'Event Planning' THEN 5000.00
            WHEN s.service_name = 'Florist' THEN 1800.00
            WHEN s.service_name = 'MC' THEN 1800.00
            WHEN s.service_name = 'Makeup & Hair' THEN 2500.00
            WHEN s.service_name = 'Makeup Artist' THEN 2500.00
            WHEN s.service_name = 'Sound System' THEN 2000.00
            WHEN s.service_name = 'Stage Design' THEN 3000.00
            WHEN s.service_name = 'Photo Booth' THEN 1000.00
            WHEN s.service_name = 'Hair Styling' THEN 2500.00
            WHEN s.service_name = 'Lighting' THEN 1500.00
            WHEN s.service_name = 'Musician' THEN 2000.00
            WHEN s.service_name = 'Caterer' THEN 8000.00
            WHEN s.service_name = 'DJ' THEN 2000.00
            WHEN s.service_name = 'Decorator' THEN 3000.00
            WHEN s.service_name = 'Flowers' THEN 1500.00
            WHEN s.service_name = 'Music' THEN 2000.00
            WHEN s.service_name = 'Photographer' THEN 3500.00
            WHEN s.service_name = 'Hair Stylist' THEN 2500.00
            ELSE 2000.00
        END) * (1 + (RANDOM() * 0.2))
    )::NUMERIC(10,2) AS quotation_price,
    'Alternative ' || s.service_name || ' services with competitive pricing.',
    'confirmed',
    '2025-10-10',
    '10:30:00'::TIME,
    'quotations/alt_' || SUBSTRING(jc.job_cart_id::text, 1, 8) || '.pdf' AS quotation_file_path,
    'alt_' || SUBSTRING(jc.job_cart_id::text, 1, 8) || '.pdf' AS quotation_file_name,
    NOW()
FROM job_cart jc
JOIN service s ON jc.service_id = s.service_id
JOIN service_provider sp ON sp.service_id = s.service_id
JOIN service_provider sp2 ON sp2.service_id = s.service_id AND sp2.service_provider_id != sp.service_provider_id
WHERE jc.job_cart_created_date = '2025-10-10'
AND jc.job_cart_status = 'pending'
ON CONFLICT (quotation_id) DO NOTHING;

-- Create 3rd quotation for each service
INSERT INTO quotation (
    quotation_id,
    job_cart_id,
    service_provider_id,
    service_id,
    quotation_price,
    quotation_details,
    quotation_status,
    quotation_submission_date,
    quotation_submission_time,
    quotation_file_path,
    quotation_file_name,
    created_at
)
SELECT
    gen_random_uuid(),
    jc.job_cart_id,
    sp3.service_provider_id,
    jc.service_id,
    ROUND(
        (CASE 
            WHEN s.service_name = 'Hair Styling & Makeup' THEN 2500.00
            WHEN s.service_name = 'Photography' THEN 3500.00
            WHEN s.service_name = 'Videography' THEN 4500.00
            WHEN s.service_name = 'Catering' THEN 8000.00
            WHEN s.service_name = 'Decoration' THEN 3000.00
            WHEN s.service_name = 'DJ Services' THEN 2000.00
            WHEN s.service_name = 'Venue' THEN 12000.00
            WHEN s.service_name = 'Security' THEN 1500.00
            WHEN s.service_name = 'Event Planning' THEN 5000.00
            WHEN s.service_name = 'Florist' THEN 1800.00
            WHEN s.service_name = 'MC' THEN 1800.00
            WHEN s.service_name = 'Makeup & Hair' THEN 2500.00
            WHEN s.service_name = 'Makeup Artist' THEN 2500.00
            WHEN s.service_name = 'Sound System' THEN 2000.00
            WHEN s.service_name = 'Stage Design' THEN 3000.00
            WHEN s.service_name = 'Photo Booth' THEN 1000.00
            WHEN s.service_name = 'Hair Styling' THEN 2500.00
            WHEN s.service_name = 'Lighting' THEN 1500.00
            WHEN s.service_name = 'Musician' THEN 2000.00
            WHEN s.service_name = 'Caterer' THEN 8000.00
            WHEN s.service_name = 'DJ' THEN 2000.00
            WHEN s.service_name = 'Decorator' THEN 3000.00
            WHEN s.service_name = 'Flowers' THEN 1500.00
            WHEN s.service_name = 'Music' THEN 2000.00
            WHEN s.service_name = 'Photographer' THEN 3500.00
            WHEN s.service_name = 'Hair Stylist' THEN 2500.00
            ELSE 2000.00
        END) * (0.8 + (RANDOM() * 0.3))
    )::NUMERIC(10,2) AS quotation_price,
    'Budget-friendly ' || s.service_name || ' package with quality service.',
    'confirmed',
    '2025-10-10',
    '11:30:00'::TIME,
    'quotations/budget_' || SUBSTRING(jc.job_cart_id::text, 1, 8) || '.pdf' AS quotation_file_path,
    'budget_' || SUBSTRING(jc.job_cart_id::text, 1, 8) || '.pdf' AS quotation_file_name,
    NOW()
FROM job_cart jc
JOIN service s ON jc.service_id = s.service_id
JOIN service_provider sp ON sp.service_id = s.service_id
JOIN service_provider sp2 ON sp2.service_id = s.service_id AND sp2.service_provider_id != sp.service_provider_id
JOIN service_provider sp3 ON sp3.service_id = s.service_id AND sp3.service_provider_id != sp.service_provider_id AND sp3.service_provider_id != sp2.service_provider_id
WHERE jc.job_cart_created_date = '2025-10-10'
AND jc.job_cart_status = 'pending'
ON CONFLICT (quotation_id) DO NOTHING;

-- Step 8: Final verification - Show EXACTLY 3 quotations per service
SELECT 
    '=== EXACTLY 3 QUOTATIONS PER SERVICE ===' AS info,
    s.service_name,
    COUNT(q.quotation_id) AS quotation_count,
    CASE 
        WHEN COUNT(q.quotation_id) = 3 THEN '✅ Perfect (3 quotations)'
        WHEN COUNT(q.quotation_id) > 3 THEN '⚠️ More than 3'
        WHEN COUNT(q.quotation_id) < 3 THEN '❌ Less than 3'
        ELSE '❌ No quotations'
    END AS status
FROM service s
LEFT JOIN quotation q ON s.service_id = q.service_id 
    AND q.quotation_submission_date = '2025-10-10'
    AND q.quotation_status = 'confirmed'
WHERE s.service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
)
GROUP BY s.service_name
ORDER BY s.service_name;

-- Step 9: Summary statistics
SELECT 
    '=== FINAL SUMMARY ===' AS info,
    'Total Services' AS type,
    COUNT(*) AS count
FROM service 
WHERE service_name IN (
    'Hair Styling & Makeup', 'Photography', 'Videography', 'Catering', 'Decoration',
    'DJ Services', 'Venue', 'Security', 'Event Planning', 'Florist', 'MC',
    'Makeup & Hair', 'Makeup Artist', 'Sound System', 'Stage Design', 'Photo Booth',
    'Hair Styling', 'Lighting', 'Musician', 'Caterer', 'DJ',
    'Decorator', 'Flowers', 'Music', 'Photographer', 'Hair Stylist'
)

UNION ALL

SELECT 
    '=== FINAL SUMMARY ===' AS info,
    'Total Job Carts Created' AS type,
    COUNT(*) AS count
FROM job_cart 
WHERE job_cart_created_date = '2025-10-10'

UNION ALL

SELECT 
    '=== FINAL SUMMARY ===' AS info,
    'Total Service Providers Added' AS type,
    COUNT(*) AS count
FROM service_provider

UNION ALL

SELECT 
    '=== FINAL SUMMARY ===' AS info,
    'Total Quotations Created' AS type,
    COUNT(*) AS count
FROM quotation 
WHERE quotation_submission_date = '2025-10-10';
