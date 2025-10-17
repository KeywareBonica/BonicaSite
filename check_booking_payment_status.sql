-- check_booking_payment_status.sql

-- =====================================================
-- Step 1: Check current payment_status values in booking table
-- =====================================================
SELECT 
    payment_status,
    COUNT(*) as count
FROM public.booking 
GROUP BY payment_status
ORDER BY payment_status;

-- =====================================================
-- Step 2: Check if payment_status column exists and its type
-- =====================================================
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'booking' 
AND table_schema = 'public'
AND column_name = 'payment_status';

-- =====================================================
-- Step 3: Show all unique values including NULLs
-- =====================================================
SELECT 
    COALESCE(payment_status::text, 'NULL') as payment_status_value,
    COUNT(*) as count
FROM public.booking 
GROUP BY payment_status
ORDER BY payment_status;

-- =====================================================
-- Step 4: Check if payment table exists
-- =====================================================
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'payment'
) as payment_table_exists;

-- =====================================================
-- Step 5: Check if payment_status_enum exists
-- =====================================================
SELECT EXISTS (
    SELECT 1 
    FROM pg_type 
    WHERE typname = 'payment_status_enum'
) as payment_status_enum_exists;





