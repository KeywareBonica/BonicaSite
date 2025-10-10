-- ===============================================
-- Generate quotations with Supabase-compatible file paths
-- and randomized pricing for realism
-- ===============================================

-- Step 1: Ensure required columns exist
DO $$
BEGIN
    -- Add missing columns to job_cart if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='job_cart' AND column_name='job_cart_item') THEN
        ALTER TABLE job_cart ADD COLUMN job_cart_item TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='job_cart' AND column_name='job_cart_details') THEN
        ALTER TABLE job_cart ADD COLUMN job_cart_details TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='job_cart' AND column_name='job_cart_created_date') THEN
        ALTER TABLE job_cart ADD COLUMN job_cart_created_date DATE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='job_cart' AND column_name='job_cart_created_time') THEN
        ALTER TABLE job_cart ADD COLUMN job_cart_created_time TIME;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='job_cart' AND column_name='job_cart_status') THEN
        ALTER TABLE job_cart ADD COLUMN job_cart_status TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='job_cart' AND column_name='service_id') THEN
        ALTER TABLE job_cart ADD COLUMN service_id UUID;
        ALTER TABLE job_cart ADD CONSTRAINT job_cart_service_id_fkey FOREIGN KEY (service_id) REFERENCES service(service_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='job_cart' AND column_name='client_id') THEN
        ALTER TABLE job_cart ADD COLUMN client_id UUID;
        ALTER TABLE job_cart ADD CONSTRAINT job_cart_client_id_fkey FOREIGN KEY (client_id) REFERENCES client(client_id);
    END IF;
    
    -- Add missing columns to quotation if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='quotation_file_path') THEN
        ALTER TABLE quotation ADD COLUMN quotation_file_path TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='quotation_file_name') THEN
        ALTER TABLE quotation ADD COLUMN quotation_file_name TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='service_id') THEN
        ALTER TABLE quotation ADD COLUMN service_id UUID;
        ALTER TABLE quotation ADD CONSTRAINT quotation_service_id_fkey FOREIGN KEY (service_id) REFERENCES service(service_id);
    END IF;
END $$;

-- Step 2: Get existing IDs
WITH existing_data AS (
    SELECT 
        (SELECT client_id FROM client LIMIT 1) as client_id,
        (SELECT event_id FROM event LIMIT 1) as event_id,
        (SELECT service_provider_id FROM service_provider LIMIT 1) as service_provider_id
)

-- Step 3: Create job carts
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
)
AND NOT EXISTS (
    SELECT 1 FROM job_cart jc 
    WHERE jc.service_id = s.service_id 
    AND jc.job_cart_created_date = '2025-10-10'
)
ON CONFLICT (job_cart_id) DO NOTHING;

-- Step 4: Generate quotations (Supabase storage path) - 3 per service
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
            ELSE 2000.00
        END) * (1 + (RANDOM() * 0.15))
    )::NUMERIC(10,2) AS quotation_price,
    'Professional ' || s.service_name || ' services for your special event.',
    'confirmed',
    '2025-10-10',
    '09:30:00'::TIME,
    -- Supabase-compatible relative storage path
    'quotations/quotation_' || 
        SUBSTRING(jc.job_cart_id::text, 1, 8) || '_' || 
        SUBSTRING(sp.service_provider_id::text, 1, 8) || '.pdf' AS quotation_file_path,
    'quotation_' || 
        SUBSTRING(jc.job_cart_id::text, 1, 8) || '_' || 
        SUBSTRING(sp.service_provider_id::text, 1, 8) || '.pdf' AS quotation_file_name,
    NOW()
FROM job_cart jc
JOIN service s ON jc.service_id = s.service_id
JOIN service_provider sp ON sp.service_id = s.service_id
WHERE jc.job_cart_created_date = '2025-10-10'
AND jc.job_cart_status = 'pending'
AND NOT EXISTS (
    SELECT 1 FROM quotation q 
    WHERE q.job_cart_id = jc.job_cart_id 
    AND q.service_provider_id = sp.service_provider_id
)
ON CONFLICT (quotation_id) DO NOTHING;

-- Step 5: Create premium quotations
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
    (SELECT service_provider_id FROM service_provider 
     WHERE service_provider_id != sp.service_provider_id 
     ORDER BY RANDOM() LIMIT 1),
    jc.service_id,
    ROUND(
        (CASE 
            WHEN s.service_name = 'Hair Styling & Makeup' THEN 2800.00
            WHEN s.service_name = 'Photography' THEN 3200.00
            WHEN s.service_name = 'Videography' THEN 4800.00
            WHEN s.service_name = 'Catering' THEN 8500.00
            WHEN s.service_name = 'Decoration' THEN 3200.00
            WHEN s.service_name = 'DJ Services' THEN 2200.00
            WHEN s.service_name = 'Venue' THEN 13000.00
            WHEN s.service_name = 'Security' THEN 1600.00
            WHEN s.service_name = 'Event Planning' THEN 5200.00
            WHEN s.service_name = 'Florist' THEN 2000.00
            WHEN s.service_name = 'MC' THEN 2000.00
            ELSE 2200.00
        END) * (1 + (RANDOM() * 0.1))
    )::NUMERIC(10,2) AS quotation_price,
    'Premium ' || s.service_name || ' package with enhanced services.',
    'confirmed',
    '2025-10-10',
    '19:00:00'::TIME,
    'quotations/premium_quotation_' || 
        SUBSTRING(jc.job_cart_id::text, 1, 8) || '_' || 
        SUBSTRING(gen_random_uuid()::text, 1, 8) || '.pdf' AS quotation_file_path,
    'premium_quotation_' || 
        SUBSTRING(jc.job_cart_id::text, 1, 8) || '_' || 
        SUBSTRING(gen_random_uuid()::text, 1, 8) || '.pdf' AS quotation_file_name,
    NOW()
FROM job_cart jc
JOIN service s ON jc.service_id = s.service_id
JOIN service_provider sp ON sp.service_id = s.service_id
WHERE jc.job_cart_created_date = '2025-10-10'
AND jc.job_cart_status = 'pending'
AND s.service_name IN ('Photography', 'Videography', 'Catering', 'Event Planning', 'Venue')
LIMIT 15
ON CONFLICT (quotation_id) DO NOTHING;

-- Step 6: Verification queries
SELECT 'Job Carts Created' AS type, COUNT(*) AS count 
FROM job_cart WHERE job_cart_created_date = '2025-10-10';

SELECT 'Quotations Created' AS type, COUNT(*) AS count 
FROM quotation WHERE quotation_submission_date = '2025-10-10';

SELECT 'Quotations with PDFs' AS type, COUNT(*) AS count 
FROM quotation 
WHERE quotation_submission_date = '2025-10-10' 
AND quotation_file_path IS NOT NULL;

-- Step 7: Sample quotations
SELECT 
    'Sample Quotations' AS info,
    q.quotation_id,
    s.service_name,
    sp.service_provider_name || ' ' || sp.service_provider_surname AS provider_name,
    q.quotation_price,
    q.quotation_file_path,
    q.quotation_file_name,
    q.quotation_status
FROM quotation q
JOIN service s ON q.service_id = s.service_id
JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
WHERE q.quotation_submission_date = '2025-10-10'
ORDER BY s.service_name, q.quotation_price
LIMIT 10;
