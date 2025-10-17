-- step1_cleanup_payment_status.sql
-- Run this FIRST to clean up existing payment_status values

-- =====================================================
-- Clean up payment_status values before migration
-- =====================================================

-- Update 'Completed' to 'verified' (most logical mapping)
UPDATE public.booking 
SET payment_status = 'verified'
WHERE payment_status = 'Completed';

-- Update 'pending' and 'Pending' to 'unpaid' (they haven't paid yet)
UPDATE public.booking 
SET payment_status = 'unpaid'
WHERE payment_status IN ('pending', 'Pending');

-- Update NULL values to 'unpaid'
UPDATE public.booking 
SET payment_status = 'unpaid'
WHERE payment_status IS NULL;

-- Verify the cleanup
SELECT 
    'After cleanup - payment_status values:' as info;

SELECT 
    payment_status,
    COUNT(*) as count
FROM public.booking 
GROUP BY payment_status
ORDER BY payment_status;
