-- cleanup_booking_payment_status.sql

-- =====================================================
-- Step 1: Check current payment_status values
-- =====================================================
SELECT 
    'Current payment_status values in booking table:' as info;
    
SELECT 
    payment_status,
    COUNT(*) as count
FROM public.booking 
GROUP BY payment_status
ORDER BY payment_status;

-- =====================================================
-- Step 2: Drop any existing check constraints on payment_status
-- =====================================================
DO $$ 
DECLARE
    constraint_name text;
BEGIN
    -- Find and drop any existing check constraints on payment_status
    SELECT conname INTO constraint_name
    FROM pg_constraint 
    WHERE conrelid = 'public.booking'::regclass 
    AND conname LIKE '%payment_status%';
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE public.booking DROP CONSTRAINT IF EXISTS ' || constraint_name;
        RAISE NOTICE 'Dropped constraint: %', constraint_name;
    END IF;
END $$;

-- =====================================================
-- Step 3: Update any problematic payment_status values
-- =====================================================
-- Update any NULL values to 'unpaid'
UPDATE public.booking 
SET payment_status = 'unpaid'
WHERE payment_status IS NULL;

-- Update any invalid string values to 'unpaid'
-- (This will only work if the column is currently text type)
DO $$ 
BEGIN
    -- Try to update any non-enum values to 'unpaid'
    -- This will fail silently if the column is already the enum type
    BEGIN
        UPDATE public.booking 
        SET payment_status = 'unpaid'
        WHERE payment_status NOT IN ('unpaid', 'pending_verification', 'verified', 'rejected', 'refunded');
    EXCEPTION
        WHEN OTHERS THEN
            -- Column might already be enum type, ignore the error
            NULL;
    END;
END $$;

-- =====================================================
-- Step 4: Verify the cleanup
-- =====================================================
SELECT 
    'After cleanup - payment_status values:' as info;
    
SELECT 
    payment_status,
    COUNT(*) as count
FROM public.booking 
GROUP BY payment_status
ORDER BY payment_status;





