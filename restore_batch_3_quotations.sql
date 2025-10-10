-- ===============================================
-- RESTORE QUOTATIONS - BATCH 3 (Quotations)
-- ===============================================

-- Step 3: Create quotations (smaller batches)
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
-- Create quotations for existing job carts and service providers
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
        END) * (0.8 + (RANDOM() * 0.4))
    )::NUMERIC(10,2) AS quotation_price,
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY jc.job_cart_id ORDER BY sp.service_provider_id) = 1 THEN 'Professional ' || s.service_name || ' services for your special event.'
        WHEN ROW_NUMBER() OVER (PARTITION BY jc.job_cart_id ORDER BY sp.service_provider_id) = 2 THEN 'Alternative ' || s.service_name || ' package with competitive pricing.'
        WHEN ROW_NUMBER() OVER (PARTITION BY jc.job_cart_id ORDER BY sp.service_provider_id) = 3 THEN 'Budget-friendly ' || s.service_name || ' option with quality service.'
        ELSE 'Premium ' || s.service_name || ' services with enhanced features.'
    END,
    'confirmed',
    '2025-10-10',
    '09:30:00'::TIME + (INTERVAL '1 minute' * (ROW_NUMBER() OVER (PARTITION BY jc.job_cart_id ORDER BY sp.service_provider_id) - 1)),
    'quotations/quotation_' || SUBSTRING(jc.job_cart_id::text, 1, 8) || '_' || SUBSTRING(sp.service_provider_id::text, 1, 8) || '.pdf' AS quotation_file_path,
    'quotation_' || SUBSTRING(jc.job_cart_id::text, 1, 8) || '_' || SUBSTRING(sp.service_provider_id::text, 1, 8) || '.pdf' AS quotation_file_name,
    NOW()
FROM job_cart jc
JOIN service s ON jc.service_id = s.service_id
JOIN service_provider sp ON sp.service_id = s.service_id
WHERE jc.job_cart_created_date = '2025-10-10'
AND jc.job_cart_status = 'pending'
ON CONFLICT (quotation_id) DO NOTHING;

-- Verification
SELECT 'Quotations Created:' AS info, COUNT(*) AS count FROM quotation WHERE quotation_submission_date = '2025-10-10';
