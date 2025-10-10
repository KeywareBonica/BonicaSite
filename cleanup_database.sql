-- ===============================================
-- CLEAN UP QUOTATION TABLE
-- ===============================================

-- Step 1: Check current count
SELECT 'Current quotation count:' AS info, COUNT(*) AS count FROM quotation;

-- Step 2: Delete all existing quotations
DELETE FROM quotation;

-- Step 3: Delete all existing job carts
DELETE FROM job_cart;

-- Step 4: Delete all existing service providers (optional - only if you want to start fresh)
-- DELETE FROM service_provider;

-- Step 5: Verify cleanup
SELECT 'After cleanup - quotation count:' AS info, COUNT(*) AS count FROM quotation;
SELECT 'After cleanup - job_cart count:' AS info, COUNT(*) AS count FROM job_cart;
SELECT 'After cleanup - service_provider count:' AS info, COUNT(*) AS count FROM service_provider;

-- Step 6: Now you can run the clean script
SELECT 'Database cleaned! Now run complete_all_services_fixed.sql' AS status;
