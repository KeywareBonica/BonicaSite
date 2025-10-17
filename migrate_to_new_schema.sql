-- Migration script to transition from existing schema to new comprehensive schema
-- Run this script to migrate your existing data

-- Step 1: Backup existing data (run these SELECT statements first to export data)
-- You should run these and save the results before proceeding:

/*
-- Export existing data
\copy (SELECT * FROM public.client) TO 'backup_client.csv' WITH CSV HEADER;
\copy (SELECT * FROM public.service_provider) TO 'backup_service_provider.csv' WITH CSV HEADER;
\copy (SELECT * FROM public.service) TO 'backup_service.csv' WITH CSV HEADER;
\copy (SELECT * FROM public.event) TO 'backup_event.csv' WITH CSV HEADER;
\copy (SELECT * FROM public.job_cart) TO 'backup_job_cart.csv' WITH CSV HEADER;
\copy (SELECT * FROM public.quotation) TO 'backup_quotation.csv' WITH CSV HEADER;
\copy (SELECT * FROM public.booking) TO 'backup_booking.csv' WITH CSV HEADER;
*/

-- Step 2: Drop existing triggers and functions to avoid conflicts
DROP TRIGGER IF EXISTS trg_quotation_after_update ON public.quotation;
DROP TRIGGER IF EXISTS trg_quotation_after_insert ON public.quotation;
DROP FUNCTION IF EXISTS public.fn_handle_quotation_accepted();
DROP FUNCTION IF EXISTS public.fn_on_new_quotation();

-- Step 3: Drop existing tables (in reverse dependency order)
DROP TABLE IF EXISTS public.review CASCADE;
DROP TABLE IF EXISTS public.booking CASCADE;
DROP TABLE IF EXISTS public.quotation CASCADE;
DROP TABLE IF EXISTS public.job_cart CASCADE;
DROP TABLE IF EXISTS public.service_provider CASCADE;
DROP TABLE IF EXISTS public.service CASCADE;
DROP TABLE IF EXISTS public.event CASCADE;
DROP TABLE IF EXISTS public.client CASCADE;
DROP TABLE IF EXISTS public.notification CASCADE;
DROP TABLE IF EXISTS public.resource_locks CASCADE;
DROP TABLE IF EXISTS public.quotation_history CASCADE;

-- Step 4: Drop existing types
DROP TYPE IF EXISTS job_cart_status_enum CASCADE;
DROP TYPE IF EXISTS quotation_status_enum CASCADE;
DROP TYPE IF EXISTS notification_type_enum CASCADE;
DROP TYPE IF EXISTS user_type_enum CASCADE;

-- Step 5: Run the new schema
-- Execute schema.sql here (or run it separately)

-- Step 6: Import your backed up data
-- Use the backup files you created in Step 1

-- Example for client table:
/*
\copy public.client FROM 'backup_client.csv' WITH CSV HEADER;
\copy public.service FROM 'backup_service.csv' WITH CSV HEADER;
\copy public.event FROM 'backup_event.csv' WITH CSV HEADER;
\copy public.service_provider FROM 'backup_service_provider.csv' WITH CSV HEADER;
\copy public.job_cart FROM 'backup_job_cart.csv' WITH CSV HEADER;
\copy public.quotation FROM 'backup_quotation.csv' WITH CSV HEADER;
\copy public.booking FROM 'backup_booking.csv' WITH CSV HEADER;
*/

-- Step 7: Verify data integrity
-- Run these queries to check your data:

/*
-- Check row counts
SELECT 'client' as table_name, COUNT(*) as row_count FROM public.client
UNION ALL
SELECT 'service', COUNT(*) FROM public.service
UNION ALL
SELECT 'event', COUNT(*) FROM public.event
UNION ALL
SELECT 'service_provider', COUNT(*) FROM public.service_provider
UNION ALL
SELECT 'job_cart', COUNT(*) FROM public.job_cart
UNION ALL
SELECT 'quotation', COUNT(*) FROM public.quotation
UNION ALL
SELECT 'booking', COUNT(*) FROM public.booking;

-- Check foreign key relationships
SELECT 
    jc.job_cart_id,
    jc.client_id,
    c.client_name,
    jc.service_id,
    s.service_name
FROM public.job_cart jc
LEFT JOIN public.client c ON jc.client_id = c.client_id
LEFT JOIN public.service s ON jc.service_id = s.service_id
WHERE c.client_id IS NULL OR s.service_id IS NULL;
*/

-- Step 8: Test triggers
-- Insert a test quotation to verify triggers work:
/*
INSERT INTO public.quotation (
    service_provider_id,
    job_cart_id,
    quotation_price,
    quotation_details
) VALUES (
    (SELECT service_provider_id FROM public.service_provider LIMIT 1),
    (SELECT job_cart_id FROM public.job_cart LIMIT 1),
    500.00,
    'Test quotation'
);

-- Update to accepted to test booking creation
UPDATE public.quotation 
SET quotation_status = 'accepted' 
WHERE quotation_id = (SELECT quotation_id FROM public.quotation ORDER BY created_at DESC LIMIT 1);
*/







