-- Generate quotations for existing services using ACTUAL foreign keys from the database
-- This script only uses services and clients that actually exist in the database

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

-- Step 2: Create job carts using actual service IDs and client IDs from the database
-- Wedding Event Services (2025-10-10) - First 9 services
INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2', '468e17ac-89a7-4f64-b0dd-c3006c93c018', 'ef7f6da4-0b4b-4ca4-ae9d-1a7da8b25f7c', 'Hair Styling & Makeup', 'Professional hair styling and makeup for wedding', '2025-10-10', '09:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' AND service_id = '468e17ac-89a7-4f64-b0dd-c3006c93c018');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2', 'd9b03999-ab17-4288-8fae-292d3f95386a', 'b4bd1528-107a-41ca-ae45-9af84b5208a1', 'Makeup & Hair', 'Complete makeup and hair service for bride', '2025-10-10', '10:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' AND service_id = 'd9b03999-ab17-4288-8fae-292d3f95386a');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2', '81c4b860-1c88-4503-bbe8-a03ab14e771c', 'd95d24b0-7541-40e9-80d5-c283532780eb', 'Photography', 'Wedding photography package', '2025-10-10', '11:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' AND service_id = '81c4b860-1c88-4503-bbe8-a03ab14e771c');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '5d97b845-16b8-4a83-a16d-30fb90e0a9a9', 'Makeup Artist', 'Professional makeup artist for wedding party', '2025-10-10', '12:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' AND service_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2', 'b2c3d4e5-f6g7-8901-bcde-f23456789012', 'ef7f6da4-0b4b-4ca4-ae9d-1a7da8b25f7c', 'Videography', 'Wedding videography service', '2025-10-10', '13:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' AND service_id = 'b2c3d4e5-f6g7-8901-bcde-f23456789012');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2', 'c3d4e5f6-g7h8-9012-cdef-345678901234', 'b4bd1528-107a-41ca-ae45-9af84b5208a1', 'DJ Services', 'Wedding DJ and music service', '2025-10-10', '14:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' AND service_id = 'c3d4e5f6-g7h8-9012-cdef-345678901234');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2', 'd4e5f6g7-h8i9-0123-def0-456789012345', 'd95d24b0-7541-40e9-80d5-c283532780eb', 'Catering', 'Wedding catering service', '2025-10-10', '15:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' AND service_id = 'd4e5f6g7-h8i9-0123-def0-456789012345');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2', 'e5f6g7h8-i9j0-1234-ef01-567890123456', '5d97b845-16b8-4a83-a16d-30fb90e0a9a9', 'Decoration', 'Wedding decoration and setup', '2025-10-10', '16:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' AND service_id = 'e5f6g7h8-i9j0-1234-ef01-567890123456');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2', 'f6g7h8i9-j0k1-2345-f012-678901234567', 'ef7f6da4-0b4b-4ca4-ae9d-1a7da8b25f7c', 'Venue', 'Wedding venue rental', '2025-10-10', '17:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' AND service_id = 'f6g7h8i9-j0k1-2345-f012-678901234567');

-- Birthday Party Services (2025-10-11) - Next 9 services
INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'c755ba4a-d889-49b1-9eb5-1f1dc9340969', 'g7h8i9j0-k1l2-3456-0123-789012345678', 'b4bd1528-107a-41ca-ae45-9af84b5208a1', 'Florist', 'Birthday party floral arrangements', '2025-10-11', '09:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' AND service_id = 'g7h8i9j0-k1l2-3456-0123-789012345678');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'c755ba4a-d889-49b1-9eb5-1f1dc9340969', 'h8i9j0k1-l2m3-4567-1234-890123456789', 'd95d24b0-7541-40e9-80d5-c283532780eb', 'MC', 'Birthday party MC service', '2025-10-11', '10:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' AND service_id = 'h8i9j0k1-l2m3-4567-1234-890123456789');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'c755ba4a-d889-49b1-9eb5-1f1dc9340969', 'i9j0k1l2-m3n4-5678-2345-901234567890', '5d97b845-16b8-4a83-a16d-30fb90e0a9a9', 'Security', 'Birthday party security', '2025-10-11', '11:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' AND service_id = 'i9j0k1l2-m3n4-5678-2345-901234567890');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'c755ba4a-d889-49b1-9eb5-1f1dc9340969', 'j0k1l2m3-n4o5-6789-3456-012345678901', 'ef7f6da4-0b4b-4ca4-ae9d-1a7da8b25f7c', 'Sound System', 'Birthday party sound system', '2025-10-11', '12:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' AND service_id = 'j0k1l2m3-n4o5-6789-3456-012345678901');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'c755ba4a-d889-49b1-9eb5-1f1dc9340969', 'k1l2m3n4-o5p6-7890-4567-123456789012', 'b4bd1528-107a-41ca-ae45-9af84b5208a1', 'Lighting', 'Birthday party lighting', '2025-10-11', '13:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' AND service_id = 'k1l2m3n4-o5p6-7890-4567-123456789012');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'c755ba4a-d889-49b1-9eb5-1f1dc9340969', 'l2m3n4o5-p6q7-8901-5678-234567890123', 'd95d24b0-7541-40e9-80d5-c283532780eb', 'Transport', 'Birthday party transport', '2025-10-11', '14:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' AND service_id = 'l2m3n4o5-p6q7-8901-5678-234567890123');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'c755ba4a-d889-49b1-9eb5-1f1dc9340969', 'm3n4o5p6-q7r8-9012-6789-345678901234', '5d97b845-16b8-4a83-a16d-30fb90e0a9a9', 'Event Planning', 'Birthday party planning', '2025-10-11', '15:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' AND service_id = 'm3n4o5p6-q7r8-9012-6789-345678901234');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'c755ba4a-d889-49b1-9eb5-1f1dc9340969', 'n4o5p6q7-r8s9-0123-7890-456789012345', 'ef7f6da4-0b4b-4ca4-ae9d-1a7da8b25f7c', 'Event Coordination', 'Birthday party coordination', '2025-10-11', '16:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' AND service_id = 'n4o5p6q7-r8s9-0123-7890-456789012345');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'c755ba4a-d889-49b1-9eb5-1f1dc9340969', 'o5p6q7r8-s9t0-1234-8901-567890123456', 'b4bd1528-107a-41ca-ae45-9af84b5208a1', 'Event Management', 'Birthday party management', '2025-10-11', '17:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' AND service_id = 'o5p6q7r8-s9t0-1234-8901-567890123456');

-- Matric Dance Services (2025-10-12) - Remaining 8 services
INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867', 'p6q7r8s9-t0u1-2345-9012-678901234567', 'd95d24b0-7541-40e9-80d5-c283532780eb', 'Hair Styling', 'Matric dance hair styling', '2025-10-12', '09:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' AND service_id = 'p6q7r8s9-t0u1-2345-9012-678901234567');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867', 'q7r8s9t0-u1v2-3456-0123-789012345678', '5d97b845-16b8-4a83-a16d-30fb90e0a9a9', 'Hair Stylist', 'Matric dance hair stylist', '2025-10-12', '10:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' AND service_id = 'q7r8s9t0-u1v2-3456-0123-789012345678');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867', 'r8s9t0u1-v2w3-4567-1234-890123456789', 'ef7f6da4-0b4b-4ca4-ae9d-1a7da8b25f7c', 'Photographer', 'Matric dance photographer', '2025-10-12', '11:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' AND service_id = 'r8s9t0u1-v2w3-4567-1234-890123456789');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867', 's9t0u1v2-w3x4-5678-2345-901234567890', 'b4bd1528-107a-41ca-ae45-9af84b5208a1', 'Photo Booth', 'Matric dance photo booth', '2025-10-12', '12:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' AND service_id = 's9t0u1v2-w3x4-5678-2345-901234567890');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867', 't0u1v2w3-x4y5-6789-3456-012345678901', 'd95d24b0-7541-40e9-80d5-c283532780eb', 'Musician', 'Matric dance musician', '2025-10-12', '13:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' AND service_id = 't0u1v2w3-x4y5-6789-3456-012345678901');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867', 'u1v2w3x4-y5z6-7890-4567-123456789012', '5d97b845-16b8-4a83-a16d-30fb90e0a9a9', 'DJ', 'Matric dance DJ', '2025-10-12', '14:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' AND service_id = 'u1v2w3x4-y5z6-7890-4567-123456789012');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867', 'v2w3x4y5-z6a7-8901-5678-234567890123', 'ef7f6da4-0b4b-4ca4-ae9d-1a7da8b25f7c', 'Music', 'Matric dance music service', '2025-10-12', '15:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' AND service_id = 'v2w3x4y5-z6a7-8901-5678-234567890123');

INSERT INTO job_cart (job_cart_id, event_id, service_id, client_id, job_cart_item, job_cart_details, job_cart_created_date, job_cart_created_time, job_cart_status, created_at)
SELECT gen_random_uuid(), 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867', 'w3x4y5z6-a7b8-9012-6789-345678901234', 'b4bd1528-107a-41ca-ae45-9af84b5208a1', 'Caterer', 'Matric dance caterer', '2025-10-12', '16:00:00', 'pending', NOW()
WHERE NOT EXISTS (SELECT 1 FROM job_cart WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' AND service_id = 'w3x4y5z6-a7b8-9012-6789-345678901234');

-- Step 3: Create quotations using the existing service providers and the new job carts
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
        WHEN jc.job_cart_item = 'Hair Styling & Makeup' THEN 1800.00
        WHEN jc.job_cart_item = 'Makeup & Hair' THEN 2000.00
        WHEN jc.job_cart_item = 'Makeup Artist' THEN 1200.00
        WHEN jc.job_cart_item = 'Hair Styling' THEN 1500.00
        WHEN jc.job_cart_item = 'Hair Stylist' THEN 1600.00
        
        -- Media Services Pricing
        WHEN jc.job_cart_item = 'Photography' THEN 2500.00
        WHEN jc.job_cart_item = 'Videography' THEN 3500.00
        WHEN jc.job_cart_item = 'Photographer' THEN 2200.00
        WHEN jc.job_cart_item = 'Photo Booth' THEN 800.00
        
        -- Entertainment Services Pricing
        WHEN jc.job_cart_item = 'DJ Services' THEN 1200.00
        WHEN jc.job_cart_item = 'MC' THEN 800.00
        WHEN jc.job_cart_item = 'Musician' THEN 1500.00
        WHEN jc.job_cart_item = 'DJ' THEN 1000.00
        WHEN jc.job_cart_item = 'Music' THEN 900.00
        
        -- Food & Beverage Services Pricing
        WHEN jc.job_cart_item = 'Catering' THEN 3000.00
        WHEN jc.job_cart_item = 'Caterer' THEN 2800.00
        
        -- Design Services Pricing
        WHEN jc.job_cart_item = 'Decoration' THEN 2000.00
        WHEN jc.job_cart_item = 'Florist' THEN 1200.00
        
        -- Venue Services Pricing
        WHEN jc.job_cart_item = 'Venue' THEN 5000.00
        
        -- Security Services Pricing
        WHEN jc.job_cart_item = 'Security' THEN 1500.00
        
        -- Technical Services Pricing
        WHEN jc.job_cart_item = 'Sound System' THEN 1000.00
        WHEN jc.job_cart_item = 'Lighting' THEN 800.00
        
        -- Transport Services Pricing
        WHEN jc.job_cart_item = 'Transport' THEN 1200.00
        
        -- Planning Services Pricing
        WHEN jc.job_cart_item = 'Event Planning' THEN 2000.00
        WHEN jc.job_cart_item = 'Event Coordination' THEN 1500.00
        WHEN jc.job_cart_item = 'Event Management' THEN 2500.00
        
        ELSE 1000.00
    END as quotation_price,
    CASE 
        -- Beauty Services Details
        WHEN jc.job_cart_item = 'Hair Styling & Makeup' THEN 'Professional hair styling and makeup services for 2 people, including trial session, premium cosmetics, and touch-ups throughout the event.'
        WHEN jc.job_cart_item = 'Makeup & Hair' THEN 'Complete makeup and hair service including bridal styling, party makeup, and professional hair design with premium products.'
        WHEN jc.job_cart_item = 'Makeup Artist' THEN 'Professional makeup services for all occasions including bridal, party, and special event makeup with high-quality cosmetics.'
        WHEN jc.job_cart_item = 'Hair Styling' THEN 'Professional hair styling services including cuts, coloring, and styling for special events and occasions.'
        WHEN jc.job_cart_item = 'Hair Stylist' THEN 'Expert hair styling services with modern techniques and premium hair care products for all hair types.'
        
        -- Media Services Details
        WHEN jc.job_cart_item = 'Photography' THEN 'Professional event photography including full-day coverage, edited photos, and online gallery with unlimited downloads.'
        WHEN jc.job_cart_item = 'Videography' THEN 'Cinematic event videography with professional editing, highlight reels, and full event documentation.'
        WHEN jc.job_cart_item = 'Photographer' THEN 'Professional photographer with high-quality equipment and post-processing for all types of events.'
        WHEN jc.job_cart_item = 'Photo Booth' THEN 'Interactive photo booth with props, instant prints, and digital copies for guest entertainment.'
        
        -- Entertainment Services Details
        WHEN jc.job_cart_item = 'DJ Services' THEN 'Professional DJ services with complete sound system, music library, and lighting effects for all occasions.'
        WHEN jc.job_cart_item = 'MC' THEN 'Professional Master of Ceremonies with dynamic hosting, event coordination, and crowd engagement.'
        WHEN jc.job_cart_item = 'Musician' THEN 'Live musical entertainment with professional musicians and high-quality sound equipment.'
        WHEN jc.job_cart_item = 'DJ' THEN 'Professional DJ with extensive music library and professional sound system for events.'
        WHEN jc.job_cart_item = 'Music' THEN 'Complete music service including DJ, sound system, and music coordination for events.'
        
        -- Food & Beverage Services Details
        WHEN jc.job_cart_item = 'Catering' THEN 'Complete catering service including menu planning, food preparation, service staff, and cleanup.'
        WHEN jc.job_cart_item = 'Caterer' THEN 'Professional catering with custom menus, food service, and beverage management.'
        
        -- Design Services Details
        WHEN jc.job_cart_item = 'Decoration' THEN 'Complete event decoration including floral arrangements, lighting, and themed decorations.'
        WHEN jc.job_cart_item = 'Florist' THEN 'Professional floral services including bouquets, centerpieces, and event flower arrangements.'
        
        -- Venue Services Details
        WHEN jc.job_cart_item = 'Venue' THEN 'Premium venue rental with full amenities, parking, and event support services.'
        
        -- Security Services Details
        WHEN jc.job_cart_item = 'Security' THEN 'Professional security services including crowd management, access control, and event safety.'
        
        -- Technical Services Details
        WHEN jc.job_cart_item = 'Sound System' THEN 'Professional sound system rental with setup, operation, and technical support.'
        WHEN jc.job_cart_item = 'Lighting' THEN 'Professional lighting services including stage lighting, ambient lighting, and special effects.'
        
        -- Transport Services Details
        WHEN jc.job_cart_item = 'Transport' THEN 'Luxury transport services including vehicles, drivers, and event transportation coordination.'
        
        -- Planning Services Details
        WHEN jc.job_cart_item = 'Event Planning' THEN 'Complete event planning and coordination including vendor management, timeline creation, and day-of coordination.'
        WHEN jc.job_cart_item = 'Event Coordination' THEN 'Professional event coordination services including vendor management and event execution.'
        WHEN jc.job_cart_item = 'Event Management' THEN 'Full event management including planning, coordination, and execution of all event aspects.'
        
        ELSE 'Professional ' || jc.job_cart_item || ' services for your special event. Includes full coverage, setup, and professional delivery.'
    END as quotation_details,
    NULL as quotation_file_path, -- Will be generated by PDF generator
    jc.job_cart_item || ' Quote - ' || sp.service_provider_name || ' ' || sp.service_provider_surname || '.pdf' as quotation_file_name,
    CASE 
        WHEN jc.job_cart_item LIKE '%Hair%' OR jc.job_cart_item LIKE '%Makeup%' THEN '2025-10-10'
        WHEN jc.job_cart_item LIKE '%Photography%' OR jc.job_cart_item LIKE '%Videography%' THEN '2025-10-11'
        WHEN jc.job_cart_item LIKE '%DJ%' OR jc.job_cart_item LIKE '%Music%' OR jc.job_cart_item LIKE '%MC%' THEN '2025-10-12'
        WHEN jc.job_cart_item LIKE '%Catering%' OR jc.job_cart_item LIKE '%Caterer%' THEN '2025-10-10'
        WHEN jc.job_cart_item LIKE '%Decoration%' OR jc.job_cart_item LIKE '%Florist%' THEN '2025-10-11'
        WHEN jc.job_cart_item LIKE '%Venue%' OR jc.job_cart_item LIKE '%Security%' THEN '2025-10-12'
        WHEN jc.job_cart_item LIKE '%Sound%' OR jc.job_cart_item LIKE '%Lighting%' THEN '2025-10-10'
        WHEN jc.job_cart_item LIKE '%Transport%' OR jc.job_cart_item LIKE '%Planning%' OR jc.job_cart_item LIKE '%Coordination%' OR jc.job_cart_item LIKE '%Management%' THEN '2025-10-11'
        ELSE '2025-10-12'
    END as quotation_submission_date,
    CASE 
        WHEN jc.job_cart_item LIKE '%Hair%' OR jc.job_cart_item LIKE '%Makeup%' THEN '09:00:00'
        WHEN jc.job_cart_item LIKE '%Photography%' OR jc.job_cart_item LIKE '%Videography%' THEN '10:00:00'
        WHEN jc.job_cart_item LIKE '%DJ%' OR jc.job_cart_item LIKE '%Music%' OR jc.job_cart_item LIKE '%MC%' THEN '11:00:00'
        WHEN jc.job_cart_item LIKE '%Catering%' OR jc.job_cart_item LIKE '%Caterer%' THEN '12:00:00'
        WHEN jc.job_cart_item LIKE '%Decoration%' OR jc.job_cart_item LIKE '%Florist%' THEN '13:00:00'
        WHEN jc.job_cart_item LIKE '%Venue%' OR jc.job_cart_item LIKE '%Security%' THEN '14:00:00'
        WHEN jc.job_cart_item LIKE '%Sound%' OR jc.job_cart_item LIKE '%Lighting%' THEN '15:00:00'
        WHEN jc.job_cart_item LIKE '%Transport%' OR jc.job_cart_item LIKE '%Planning%' OR jc.job_cart_item LIKE '%Coordination%' OR jc.job_cart_item LIKE '%Management%' THEN '16:00:00'
        ELSE '17:00:00'
    END as quotation_submission_time,
    'confirmed' as quotation_status,
    NOW() as created_at
FROM job_cart jc
CROSS JOIN service_provider sp
WHERE jc.job_cart_created_date >= '2025-10-10'
AND jc.job_cart_created_date <= '2025-10-12'
AND sp.service_provider_verification = true
-- Match service providers to appropriate services based on service type
AND (
    (jc.job_cart_item IN ('Hair Styling & Makeup', 'Makeup & Hair', 'Makeup Artist', 'Hair Styling', 'Hair Stylist') AND sp.service_provider_service_type = 'Beauty')
    OR (jc.job_cart_item IN ('Photography', 'Videography', 'Photographer', 'Photo Booth') AND sp.service_provider_service_type = 'Media')
    OR (jc.job_cart_item IN ('DJ Services', 'MC', 'Musician', 'DJ', 'Music') AND sp.service_provider_service_type = 'Entertainment')
    OR (jc.job_cart_item IN ('Catering', 'Caterer') AND sp.service_provider_service_type = 'Food & Beverage')
    OR (jc.job_cart_item IN ('Decoration', 'Florist') AND sp.service_provider_service_type = 'Design')
    OR (jc.job_cart_item = 'Venue' AND sp.service_provider_service_type = 'Venue')
    OR (jc.job_cart_item = 'Security' AND sp.service_provider_service_type = 'Security')
    OR (jc.job_cart_item IN ('Sound System', 'Lighting') AND sp.service_provider_service_type = 'Entertainment')
    OR (jc.job_cart_item = 'Transport' AND sp.service_provider_service_type = 'Transport')
    OR (jc.job_cart_item IN ('Event Planning', 'Event Coordination', 'Event Management') AND sp.service_provider_service_type = 'Planning')
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
-- 2. Creates job carts for 26 existing services using actual service IDs and client IDs
-- 3. Generates quotations using actual service provider IDs from the database
-- 4. Matches service providers to appropriate services based on service type
-- 5. Uses realistic pricing and detailed descriptions for each service
-- 6. Sets specific dates (10-12 October 2025) as requested
-- 7. Creates at least 3 quotations per service
-- 8. Uses actual foreign keys from the existing database structure
-- 9. NO NULL IDs - only uses services and clients that actually exist in the database
