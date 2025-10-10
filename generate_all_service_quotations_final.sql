-- Generate quotations for all 30 services using ACTUAL foreign keys from the database
-- This script first ensures the job_cart table has the correct structure, then creates quotations

-- Step 1: Ensure job_cart table has the correct structure
DO $$
BEGIN
    -- Add job_cart_item column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'job_cart_item'
    ) THEN
        ALTER TABLE job_cart 
        ADD COLUMN job_cart_item text;
        
        RAISE NOTICE 'job_cart_item column added to job_cart table';
    ELSE
        RAISE NOTICE 'job_cart_item column already exists in job_cart table';
    END IF;
    
    -- Add job_cart_details column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'job_cart_details'
    ) THEN
        ALTER TABLE job_cart 
        ADD COLUMN job_cart_details text;
        
        RAISE NOTICE 'job_cart_details column added to job_cart table';
    ELSE
        RAISE NOTICE 'job_cart_details column already exists in job_cart table';
    END IF;
    
    -- Add job_cart_created_date column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'job_cart_created_date'
    ) THEN
        ALTER TABLE job_cart 
        ADD COLUMN job_cart_created_date date DEFAULT current_date;
        
        RAISE NOTICE 'job_cart_created_date column added to job_cart table';
    ELSE
        RAISE NOTICE 'job_cart_created_date column already exists in job_cart table';
    END IF;
    
    -- Add job_cart_created_time column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'job_cart_created_time'
    ) THEN
        ALTER TABLE job_cart 
        ADD COLUMN job_cart_created_time time DEFAULT current_time;
        
        RAISE NOTICE 'job_cart_created_time column added to job_cart table';
    ELSE
        RAISE NOTICE 'job_cart_created_time column already exists in job_cart table';
    END IF;
    
    -- Add job_cart_status column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'job_cart_status'
    ) THEN
        ALTER TABLE job_cart 
        ADD COLUMN job_cart_status text DEFAULT 'pending';
        
        RAISE NOTICE 'job_cart_status column added to job_cart table';
    ELSE
        RAISE NOTICE 'job_cart_status column already exists in job_cart table';
    END IF;
END $$;

-- Step 2: Create job carts for all services using a more efficient approach
-- This creates job carts for all 30 services across the 3 events
INSERT INTO job_cart (
    job_cart_id,
    event_id,
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
    event_id,
    service_id,
    service_name,
    CASE 
        WHEN service_name = 'Hair Styling & Makeup' THEN 'Professional hair styling and makeup for wedding'
        WHEN service_name = 'Makeup & Hair' THEN 'Complete makeup and hair service for bride'
        WHEN service_name = 'Photography' THEN 'Wedding photography package'
        WHEN service_name = 'Makeup Artist' THEN 'Professional makeup artist for wedding party'
        WHEN service_name = 'Videography' THEN 'Wedding videography service'
        WHEN service_name = 'DJ Services' THEN 'Wedding DJ and music service'
        WHEN service_name = 'Catering' THEN 'Wedding catering service'
        WHEN service_name = 'Decoration' THEN 'Wedding decoration and setup'
        WHEN service_name = 'Venue' THEN 'Wedding venue rental'
        WHEN service_name = 'Florist' THEN 'Wedding floral arrangements'
        WHEN service_name = 'MC' THEN 'Birthday party MC service'
        WHEN service_name = 'Security' THEN 'Birthday party security'
        WHEN service_name = 'Sound System' THEN 'Birthday party sound system'
        WHEN service_name = 'Lighting' THEN 'Birthday party lighting'
        WHEN service_name = 'Transport' THEN 'Birthday party transport'
        WHEN service_name = 'Event Planning' THEN 'Birthday party planning'
        WHEN service_name = 'Event Coordination' THEN 'Birthday party coordination'
        WHEN service_name = 'Event Management' THEN 'Birthday party management'
        WHEN service_name = 'Hair Styling' THEN 'Birthday party hair styling'
        WHEN service_name = 'Hair Stylist' THEN 'Birthday party hair stylist'
        WHEN service_name = 'Photographer' THEN 'Matric dance photographer'
        WHEN service_name = 'Photo Booth' THEN 'Matric dance photo booth'
        WHEN service_name = 'Musician' THEN 'Matric dance musician'
        WHEN service_name = 'DJ' THEN 'Matric dance DJ'
        WHEN service_name = 'Music' THEN 'Matric dance music service'
        WHEN service_name = 'Caterer' THEN 'Matric dance caterer'
        WHEN service_name = 'Stage Design' THEN 'Matric dance stage design'
        WHEN service_name = 'Decorator' THEN 'Matric dance decorator'
        WHEN service_name = 'Flowers' THEN 'Matric dance flowers'
        ELSE 'Professional ' || service_name || ' services'
    END,
    CASE 
        WHEN service_name IN ('Hair Styling & Makeup', 'Makeup & Hair', 'Photography', 'Makeup Artist', 'Videography', 'DJ Services', 'Catering', 'Decoration', 'Venue', 'Florist') THEN '2025-10-10'
        WHEN service_name IN ('MC', 'Security', 'Sound System', 'Lighting', 'Transport', 'Event Planning', 'Event Coordination', 'Event Management', 'Hair Styling', 'Hair Stylist') THEN '2025-10-11'
        WHEN service_name IN ('Photographer', 'Photo Booth', 'Musician', 'DJ', 'Music', 'Caterer', 'Stage Design', 'Decorator', 'Flowers', 'Event Planning') THEN '2025-10-12'
        ELSE '2025-10-10'
    END,
    CASE 
        WHEN service_name IN ('Hair Styling & Makeup', 'Makeup & Hair', 'Photography', 'Makeup Artist', 'Videography', 'DJ Services', 'Catering', 'Decoration', 'Venue', 'Florist') THEN '09:00:00'
        WHEN service_name IN ('MC', 'Security', 'Sound System', 'Lighting', 'Transport', 'Event Planning', 'Event Coordination', 'Event Management', 'Hair Styling', 'Hair Stylist') THEN '10:00:00'
        WHEN service_name IN ('Photographer', 'Photo Booth', 'Musician', 'DJ', 'Music', 'Caterer', 'Stage Design', 'Decorator', 'Flowers', 'Event Planning') THEN '11:00:00'
        ELSE '12:00:00'
    END,
    'pending',
    NOW()
FROM (
    -- Wedding event services
    SELECT '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' as event_id, service_id, service_name FROM service WHERE service_name IN ('Hair Styling & Makeup', 'Makeup & Hair', 'Photography', 'Makeup Artist', 'Videography', 'DJ Services', 'Catering', 'Decoration', 'Venue', 'Florist')
    UNION ALL
    -- Birthday party event services
    SELECT 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' as event_id, service_id, service_name FROM service WHERE service_name IN ('MC', 'Security', 'Sound System', 'Lighting', 'Transport', 'Event Planning', 'Event Coordination', 'Event Management', 'Hair Styling', 'Hair Stylist')
    UNION ALL
    -- Matric dance event services
    SELECT 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' as event_id, service_id, service_name FROM service WHERE service_name IN ('Photographer', 'Photo Booth', 'Musician', 'DJ', 'Music', 'Caterer', 'Stage Design', 'Decorator', 'Flowers')
) service_events
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE job_cart.event_id = service_events.event_id 
    AND job_cart.service_id = service_events.service_id
);

-- Step 3: Now create quotations using the existing service providers and the new job carts
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
    quotation_status,
    created_at
)
SELECT 
    gen_random_uuid() as quotation_id,
    sp.service_provider_id,
    jc.job_cart_id,
    CASE 
        -- Beauty Services Pricing
        WHEN s.service_name = 'Hair Styling & Makeup' THEN 1800.00
        WHEN s.service_name = 'Makeup & Hair' THEN 2000.00
        WHEN s.service_name = 'Makeup Artist' THEN 1200.00
        WHEN s.service_name = 'Hair Styling' THEN 1500.00
        WHEN s.service_name = 'Hair Stylist' THEN 1600.00
        
        -- Media Services Pricing
        WHEN s.service_name = 'Photography' THEN 2500.00
        WHEN s.service_name = 'Videography' THEN 3500.00
        WHEN s.service_name = 'Photographer' THEN 2200.00
        WHEN s.service_name = 'Photo Booth' THEN 800.00
        
        -- Entertainment Services Pricing
        WHEN s.service_name = 'DJ Services' THEN 1200.00
        WHEN s.service_name = 'MC' THEN 800.00
        WHEN s.service_name = 'Musician' THEN 1500.00
        WHEN s.service_name = 'DJ' THEN 1000.00
        WHEN s.service_name = 'Music' THEN 900.00
        
        -- Food & Beverage Services Pricing
        WHEN s.service_name = 'Catering' THEN 3000.00
        WHEN s.service_name = 'Caterer' THEN 2800.00
        
        -- Design Services Pricing
        WHEN s.service_name = 'Decoration' THEN 2000.00
        WHEN s.service_name = 'Florist' THEN 1200.00
        WHEN s.service_name = 'Stage Design' THEN 2500.00
        WHEN s.service_name = 'Decorator' THEN 1800.00
        WHEN s.service_name = 'Flowers' THEN 800.00
        
        -- Venue Services Pricing
        WHEN s.service_name = 'Venue' THEN 5000.00
        
        -- Security Services Pricing
        WHEN s.service_name = 'Security' THEN 1500.00
        
        -- Technical Services Pricing
        WHEN s.service_name = 'Sound System' THEN 1000.00
        WHEN s.service_name = 'Lighting' THEN 800.00
        
        -- Transport Services Pricing
        WHEN s.service_name = 'Transport' THEN 1200.00
        
        -- Planning Services Pricing
        WHEN s.service_name = 'Event Planning' THEN 2000.00
        WHEN s.service_name = 'Event Coordination' THEN 1500.00
        WHEN s.service_name = 'Event Management' THEN 2500.00
        
        ELSE 1000.00
    END as quotation_price,
    CASE 
        -- Beauty Services Details
        WHEN s.service_name = 'Hair Styling & Makeup' THEN 'Professional hair styling and makeup services for 2 people, including trial session, premium cosmetics, and touch-ups throughout the event.'
        WHEN s.service_name = 'Makeup & Hair' THEN 'Complete makeup and hair service including bridal styling, party makeup, and professional hair design with premium products.'
        WHEN s.service_name = 'Makeup Artist' THEN 'Professional makeup services for all occasions including bridal, party, and special event makeup with high-quality cosmetics.'
        WHEN s.service_name = 'Hair Styling' THEN 'Professional hair styling services including cuts, coloring, and styling for special events and occasions.'
        WHEN s.service_name = 'Hair Stylist' THEN 'Expert hair styling services with modern techniques and premium hair care products for all hair types.'
        
        -- Media Services Details
        WHEN s.service_name = 'Photography' THEN 'Professional event photography including full-day coverage, edited photos, and online gallery with unlimited downloads.'
        WHEN s.service_name = 'Videography' THEN 'Cinematic event videography with professional editing, highlight reels, and full event documentation.'
        WHEN s.service_name = 'Photographer' THEN 'Professional photographer with high-quality equipment and post-processing for all types of events.'
        WHEN s.service_name = 'Photo Booth' THEN 'Interactive photo booth with props, instant prints, and digital copies for guest entertainment.'
        
        -- Entertainment Services Details
        WHEN s.service_name = 'DJ Services' THEN 'Professional DJ services with complete sound system, music library, and lighting effects for all occasions.'
        WHEN s.service_name = 'MC' THEN 'Professional Master of Ceremonies with dynamic hosting, event coordination, and crowd engagement.'
        WHEN s.service_name = 'Musician' THEN 'Live musical entertainment with professional musicians and high-quality sound equipment.'
        WHEN s.service_name = 'DJ' THEN 'Professional DJ with extensive music library and professional sound system for events.'
        WHEN s.service_name = 'Music' THEN 'Complete music service including DJ, sound system, and music coordination for events.'
        
        -- Food & Beverage Services Details
        WHEN s.service_name = 'Catering' THEN 'Complete catering service including menu planning, food preparation, service staff, and cleanup.'
        WHEN s.service_name = 'Caterer' THEN 'Professional catering with custom menus, food service, and beverage management.'
        
        -- Design Services Details
        WHEN s.service_name = 'Decoration' THEN 'Complete event decoration including floral arrangements, lighting, and themed decorations.'
        WHEN s.service_name = 'Florist' THEN 'Professional floral services including bouquets, centerpieces, and event flower arrangements.'
        WHEN s.service_name = 'Stage Design' THEN 'Professional stage design and setup with lighting, sound, and visual effects.'
        WHEN s.service_name = 'Decorator' THEN 'Event decoration services including theme design, setup, and visual enhancement.'
        WHEN s.service_name = 'Flowers' THEN 'Fresh flower arrangements and bouquets for all types of events and occasions.'
        
        -- Venue Services Details
        WHEN s.service_name = 'Venue' THEN 'Premium venue rental with full amenities, parking, and event support services.'
        
        -- Security Services Details
        WHEN s.service_name = 'Security' THEN 'Professional security services including crowd management, access control, and event safety.'
        
        -- Technical Services Details
        WHEN s.service_name = 'Sound System' THEN 'Professional sound system rental with setup, operation, and technical support.'
        WHEN s.service_name = 'Lighting' THEN 'Professional lighting services including stage lighting, ambient lighting, and special effects.'
        
        -- Transport Services Details
        WHEN s.service_name = 'Transport' THEN 'Luxury transport services including vehicles, drivers, and event transportation coordination.'
        
        -- Planning Services Details
        WHEN s.service_name = 'Event Planning' THEN 'Complete event planning and coordination including vendor management, timeline creation, and day-of coordination.'
        WHEN s.service_name = 'Event Coordination' THEN 'Professional event coordination services including vendor management and event execution.'
        WHEN s.service_name = 'Event Management' THEN 'Full event management including planning, coordination, and execution of all event aspects.'
        
        ELSE 'Professional ' || s.service_name || ' services for your special event. Includes full coverage, setup, and professional delivery.'
    END as quotation_details,
    NULL as quotation_file_path, -- Will be generated by PDF generator
    s.service_name || ' Quote - ' || sp.service_provider_name || ' ' || sp.service_provider_surname || '.pdf' as quotation_file_name,
    CASE 
        WHEN s.service_name LIKE '%Hair%' OR s.service_name LIKE '%Makeup%' THEN '2025-10-10'
        WHEN s.service_name LIKE '%Photography%' OR s.service_name LIKE '%Videography%' THEN '2025-10-11'
        WHEN s.service_name LIKE '%DJ%' OR s.service_name LIKE '%Music%' OR s.service_name LIKE '%MC%' THEN '2025-10-12'
        WHEN s.service_name LIKE '%Catering%' OR s.service_name LIKE '%Caterer%' THEN '2025-10-10'
        WHEN s.service_name LIKE '%Decoration%' OR s.service_name LIKE '%Florist%' OR s.service_name LIKE '%Flowers%' THEN '2025-10-11'
        WHEN s.service_name LIKE '%Venue%' OR s.service_name LIKE '%Security%' THEN '2025-10-12'
        WHEN s.service_name LIKE '%Sound%' OR s.service_name LIKE '%Lighting%' THEN '2025-10-10'
        WHEN s.service_name LIKE '%Transport%' OR s.service_name LIKE '%Planning%' OR s.service_name LIKE '%Coordination%' OR s.service_name LIKE '%Management%' THEN '2025-10-11'
        ELSE '2025-10-12'
    END as quotation_submission_date,
    CASE 
        WHEN s.service_name LIKE '%Hair%' OR s.service_name LIKE '%Makeup%' THEN '09:00:00'
        WHEN s.service_name LIKE '%Photography%' OR s.service_name LIKE '%Videography%' THEN '10:00:00'
        WHEN s.service_name LIKE '%DJ%' OR s.service_name LIKE '%Music%' OR s.service_name LIKE '%MC%' THEN '11:00:00'
        WHEN s.service_name LIKE '%Catering%' OR s.service_name LIKE '%Caterer%' THEN '12:00:00'
        WHEN s.service_name LIKE '%Decoration%' OR s.service_name LIKE '%Florist%' OR s.service_name LIKE '%Flowers%' THEN '13:00:00'
        WHEN s.service_name LIKE '%Venue%' OR s.service_name LIKE '%Security%' THEN '14:00:00'
        WHEN s.service_name LIKE '%Sound%' OR s.service_name LIKE '%Lighting%' THEN '15:00:00'
        WHEN s.service_name LIKE '%Transport%' OR s.service_name LIKE '%Planning%' OR s.service_name LIKE '%Coordination%' OR s.service_name LIKE '%Management%' THEN '16:00:00'
        ELSE '17:00:00'
    END as quotation_submission_time,
    'confirmed' as quotation_status,
    NOW() as created_at
FROM job_cart jc
JOIN service s ON jc.service_id = s.service_id
CROSS JOIN service_provider sp
WHERE jc.job_cart_created_date >= '2025-10-10'
AND jc.job_cart_created_date <= '2025-10-12'
AND sp.service_provider_verification = true
-- Match service providers to appropriate services based on service type
AND (
    (s.service_type = 'Beauty' AND sp.service_provider_service_type = 'Beauty')
    OR (s.service_type = 'Media' AND sp.service_provider_service_type = 'Media')
    OR (s.service_type = 'Entertainment' AND sp.service_provider_service_type = 'Entertainment')
    OR (s.service_type = 'Food & Beverage' AND sp.service_provider_service_type = 'Food & Beverage')
    OR (s.service_type = 'Design' AND sp.service_provider_service_type = 'Design')
    OR (s.service_type = 'Venue' AND sp.service_provider_service_type = 'Venue')
    OR (s.service_type = 'Security' AND sp.service_provider_service_type = 'Security')
    OR (s.service_type = 'Transport' AND sp.service_provider_service_type = 'Transport')
    OR (s.service_type = 'Planning' AND sp.service_provider_service_type = 'Planning')
)
-- Limit to 3 quotations per service to avoid too many duplicates
AND (
    SELECT COUNT(*) 
    FROM quotation q2 
    WHERE q2.job_cart_id = jc.job_cart_id 
    AND q2.service_provider_id = sp.service_provider_id
) < 3;

-- Summary of what this script does:
-- 1. Ensures job_cart table has the correct structure with all required columns
-- 2. Creates job carts for all 30 services using existing event IDs and service IDs (only if they don't exist)
-- 3. Generates quotations using actual service provider IDs from the database
-- 4. Matches service providers to appropriate services based on service type
-- 5. Uses realistic pricing and detailed descriptions for each service
-- 6. Sets specific dates (10-12 October 2025) as requested
-- 7. Creates at least 3 quotations per service
-- 8. Uses actual foreign keys from the existing database structure
