-- ===============================================
-- FIX SQL ERROR: Drop Trigger and Function Safely
-- ===============================================

-- Step 1: Drop the trigger first (it depends on the function)
DROP TRIGGER IF EXISTS trigger_validate_quotation_file ON quotation;

-- Step 2: Now drop the function (no dependencies)
DROP FUNCTION IF EXISTS validate_quotation_file_upload();

-- Verification
SELECT 'Trigger and function removed successfully' AS status;
