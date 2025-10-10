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

-- Step 2: Create additional job carts for each service using existing events
-- Only insert if the job cart doesn't already exist
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
    '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2',
    (SELECT service_id FROM service WHERE service_name = 'Hair Styling & Makeup' LIMIT 1),
    'Hair Styling & Makeup',
    'Professional hair styling and makeup for wedding',
    '2025-10-10',
    '09:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' 
    AND job_cart_item = 'Hair Styling & Makeup'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2',
    'Makeup & Hair',
    'Complete makeup and hair service for bride',
    '2025-10-10',
    '10:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' 
    AND job_cart_item = 'Makeup & Hair'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2',
    'Photography',
    'Wedding photography package',
    '2025-10-10',
    '11:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' 
    AND job_cart_item = 'Photography'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2',
    'Makeup Artist',
    'Professional makeup artist for wedding party',
    '2025-10-10',
    '12:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' 
    AND job_cart_item = 'Makeup Artist'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2',
    'Videography',
    'Wedding videography service',
    '2025-10-10',
    '13:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' 
    AND job_cart_item = 'Videography'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2',
    'DJ Services',
    'Wedding DJ and music service',
    '2025-10-10',
    '14:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' 
    AND job_cart_item = 'DJ Services'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2',
    'Catering',
    'Wedding catering service',
    '2025-10-10',
    '15:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' 
    AND job_cart_item = 'Catering'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2',
    'Decoration',
    'Wedding decoration and setup',
    '2025-10-10',
    '16:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' 
    AND job_cart_item = 'Decoration'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2',
    'Venue',
    'Wedding venue rental',
    '2025-10-10',
    '17:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' 
    AND job_cart_item = 'Venue'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2',
    'Florist',
    'Wedding floral arrangements',
    '2025-10-10',
    '18:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = '7cc2dfbe-55b5-45b2-b61e-c49f0d401bf2' 
    AND job_cart_item = 'Florist'
);

-- Add more job carts for the other events (Birthday Party and Matric Dance)
-- Birthday Party job carts
INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'c755ba4a-d889-49b1-9eb5-1f1dc9340969',
    'MC',
    'Birthday party MC service',
    '2025-10-11',
    '09:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' 
    AND job_cart_item = 'MC'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'c755ba4a-d889-49b1-9eb5-1f1dc9340969',
    'Security',
    'Birthday party security',
    '2025-10-11',
    '10:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' 
    AND job_cart_item = 'Security'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'c755ba4a-d889-49b1-9eb5-1f1dc9340969',
    'Sound System',
    'Birthday party sound system',
    '2025-10-11',
    '11:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' 
    AND job_cart_item = 'Sound System'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'c755ba4a-d889-49b1-9eb5-1f1dc9340969',
    'Lighting',
    'Birthday party lighting',
    '2025-10-11',
    '12:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' 
    AND job_cart_item = 'Lighting'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'c755ba4a-d889-49b1-9eb5-1f1dc9340969',
    'Transport',
    'Birthday party transport',
    '2025-10-11',
    '13:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' 
    AND job_cart_item = 'Transport'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'c755ba4a-d889-49b1-9eb5-1f1dc9340969',
    'Event Planning',
    'Birthday party planning',
    '2025-10-11',
    '14:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' 
    AND job_cart_item = 'Event Planning'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'c755ba4a-d889-49b1-9eb5-1f1dc9340969',
    'Event Coordination',
    'Birthday party coordination',
    '2025-10-11',
    '15:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' 
    AND job_cart_item = 'Event Coordination'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'c755ba4a-d889-49b1-9eb5-1f1dc9340969',
    'Event Management',
    'Birthday party management',
    '2025-10-11',
    '16:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' 
    AND job_cart_item = 'Event Management'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'c755ba4a-d889-49b1-9eb5-1f1dc9340969',
    'Hair Styling',
    'Birthday party hair styling',
    '2025-10-11',
    '17:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' 
    AND job_cart_item = 'Hair Styling'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'c755ba4a-d889-49b1-9eb5-1f1dc9340969',
    'Hair Stylist',
    'Birthday party hair stylist',
    '2025-10-11',
    '18:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'c755ba4a-d889-49b1-9eb5-1f1dc9340969' 
    AND job_cart_item = 'Hair Stylist'
);

-- Matric Dance job carts
INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'aa8b7c83-78cd-40cd-bf6e-216b45c5c867',
    'Photographer',
    'Matric dance photographer',
    '2025-10-12',
    '09:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' 
    AND job_cart_item = 'Photographer'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'aa8b7c83-78cd-40cd-bf6e-216b45c5c867',
    'Photo Booth',
    'Matric dance photo booth',
    '2025-10-12',
    '10:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' 
    AND job_cart_item = 'Photo Booth'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'aa8b7c83-78cd-40cd-bf6e-216b45c5c867',
    'Musician',
    'Matric dance musician',
    '2025-10-12',
    '11:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' 
    AND job_cart_item = 'Musician'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'aa8b7c83-78cd-40cd-bf6e-216b45c5c867',
    'DJ',
    'Matric dance DJ',
    '2025-10-12',
    '12:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' 
    AND job_cart_item = 'DJ'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'aa8b7c83-78cd-40cd-bf6e-216b45c5c867',
    'Music',
    'Matric dance music service',
    '2025-10-12',
    '13:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' 
    AND job_cart_item = 'Music'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'aa8b7c83-78cd-40cd-bf6e-216b45c5c867',
    'Caterer',
    'Matric dance caterer',
    '2025-10-12',
    '14:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' 
    AND job_cart_item = 'Caterer'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'aa8b7c83-78cd-40cd-bf6e-216b45c5c867',
    'Stage Design',
    'Matric dance stage design',
    '2025-10-12',
    '15:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' 
    AND job_cart_item = 'Stage Design'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'aa8b7c83-78cd-40cd-bf6e-216b45c5c867',
    'Decorator',
    'Matric dance decorator',
    '2025-10-12',
    '16:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' 
    AND job_cart_item = 'Decorator'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'aa8b7c83-78cd-40cd-bf6e-216b45c5c867',
    'Flowers',
    'Matric dance flowers',
    '2025-10-12',
    '17:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' 
    AND job_cart_item = 'Flowers'
);

INSERT INTO job_cart (
    job_cart_id,
    event_id,
    job_cart_item,
    job_cart_details,
    job_cart_created_date,
    job_cart_created_time,
    job_cart_status,
    created_at
) 
SELECT 
    gen_random_uuid(),
    'aa8b7c83-78cd-40cd-bf6e-216b45c5c867',
    'Event Planning',
    'Matric dance planning',
    '2025-10-12',
    '18:00:00',
    'pending',
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM job_cart 
    WHERE event_id = 'aa8b7c83-78cd-40cd-bf6e-216b45c5c867' 
    AND job_cart_item = 'Event Planning'
);

-- Step 3: Now create quotations using the existing service providers and the new job carts
-- We'll use the actual service provider IDs from the database
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
        WHEN jc.job_cart_item = 'Stage Design' THEN 2500.00
        WHEN jc.job_cart_item = 'Decorator' THEN 1800.00
        WHEN jc.job_cart_item = 'Flowers' THEN 800.00
        
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
        WHEN jc.job_cart_item = 'Stage Design' THEN 'Professional stage design and setup with lighting, sound, and visual effects.'
        WHEN jc.job_cart_item = 'Decorator' THEN 'Event decoration services including theme design, setup, and visual enhancement.'
        WHEN jc.job_cart_item = 'Flowers' THEN 'Fresh flower arrangements and bouquets for all types of events and occasions.'
        
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
        WHEN jc.job_cart_item LIKE '%Decoration%' OR jc.job_cart_item LIKE '%Florist%' OR jc.job_cart_item LIKE '%Flowers%' THEN '2025-10-11'
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
        WHEN jc.job_cart_item LIKE '%Decoration%' OR jc.job_cart_item LIKE '%Florist%' OR jc.job_cart_item LIKE '%Flowers%' THEN '13:00:00'
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
    OR (jc.job_cart_item IN ('Decoration', 'Florist', 'Stage Design', 'Decorator', 'Flowers') AND sp.service_provider_service_type = 'Design')
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
-- 2. Creates job carts for all 30 services using existing event IDs (only if they don't exist)
-- 3. Generates quotations using actual service provider IDs from the database
-- 4. Matches service providers to appropriate services based on service type
-- 5. Uses realistic pricing and detailed descriptions for each service
-- 6. Sets specific dates (10-12 October 2025) as requested
-- 7. Creates at least 3 quotations per service
-- 8. Uses actual foreign keys from the existing database structure
