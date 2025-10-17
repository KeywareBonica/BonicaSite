-- step2_pre_migration_check.sql
-- Run this SECOND to see current state

-- =====================================================
-- 1. Check current booking table structure
-- =====================================================
SELECT 
    'Current booking table columns:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'booking' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- 2. Check current payment_status values
-- =====================================================
SELECT 
    'Current payment_status values:' as info;

SELECT 
    COALESCE(payment_status, 'NULL') as payment_status_value,
    COUNT(*) as count
FROM public.booking 
GROUP BY payment_status
ORDER BY payment_status;

-- =====================================================
-- 3. Check if payment table already exists
-- =====================================================
SELECT 
    'Payment table exists:' as info,
    EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'payment'
    ) as payment_table_exists;

-- =====================================================
-- 4. Check if payment_status_enum already exists
-- =====================================================
SELECT 
    'Payment status enum exists:' as info,
    EXISTS (
        SELECT 1 
        FROM pg_type 
        WHERE typname = 'payment_status_enum'
    ) as payment_status_enum_exists;

-- =====================================================
-- 5. Check if RPC functions already exist
-- =====================================================
SELECT 
    'Existing RPC functions:' as info,
    proname as function_name
FROM pg_proc 
WHERE proname IN ('submit_payment', 'verify_payment', 'get_pending_payments')
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- =====================================================
-- 6. Sample booking data to understand current state
-- =====================================================
SELECT 
    'Sample booking data:' as info;

SELECT 
    booking_id,
    booking_status,
    payment_status,
    client_id,
    service_provider_id
FROM public.booking 
LIMIT 5;





