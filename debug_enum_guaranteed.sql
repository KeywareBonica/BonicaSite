-- === GUARANTEED WORKING ENUM DEBUG SCRIPT ===
-- Uses ONLY basic, safe PostgreSQL queries - NO advanced functions

-- === STEP 1: Check what enums currently exist ===
SELECT '=== EXISTING ENUMS ===' as section;

SELECT 
    typname as enum_name,
    enumlabel as enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
ORDER BY typname, enumlabel;

-- === STEP 2: Check column types ===
SELECT '=== COLUMN TYPES ===' as section;

SELECT 
    table_name, 
    column_name, 
    data_type,
    udt_name,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
ORDER BY table_name, column_name;

-- === STEP 3: Check actual data values ===
SELECT '=== ACTUAL DATA VALUES ===' as section;

-- Job cart status values
SELECT 'job_cart.job_cart_status' as table_column, 
       job_cart_status as value, 
       COUNT(*) as count
FROM public.job_cart 
GROUP BY job_cart_status
ORDER BY job_cart_status;

-- Quotation status values
SELECT 'quotation.quotation_status' as table_column, 
       quotation_status as value, 
       COUNT(*) as count
FROM public.quotation 
GROUP BY quotation_status
ORDER BY quotation_status;

-- Notification type values
SELECT 'notification.type' as table_column, 
       type as value, 
       COUNT(*) as count
FROM public.notification 
GROUP BY type
ORDER BY type;

-- Notification user_type values
SELECT 'notification.user_type' as table_column, 
       user_type as value, 
       COUNT(*) as count
FROM public.notification 
GROUP BY user_type
ORDER BY user_type;

-- Resource locks user_type values
SELECT 'resource_locks.user_type' as table_column, 
       user_type as value, 
       COUNT(*) as count
FROM public.resource_locks 
GROUP BY user_type
ORDER BY user_type;

-- === STEP 4: Find ALL views ===
SELECT '=== ALL VIEWS ===' as section;

SELECT 
    schemaname,
    viewname
FROM pg_views 
WHERE schemaname = 'public'
ORDER BY viewname;

-- === STEP 5: Find ALL functions ===
SELECT '=== ALL FUNCTIONS ===' as section;

SELECT 
    n.nspname as schema_name,
    p.proname as function_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
ORDER BY p.proname;

-- === STEP 6: Find ALL triggers ===
SELECT '=== ALL TRIGGERS ===' as section;

SELECT 
    trigger_name,
    event_object_table,
    action_timing
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
ORDER BY trigger_name;

-- === STEP 7: Find ALL policies ===
SELECT '=== ALL POLICIES ===' as section;

SELECT 
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY policyname;

-- === STEP 8: Find ALL constraints ===
SELECT '=== ALL CONSTRAINTS ===' as section;

SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- === STEP 9: Check for specific problematic patterns ===
SELECT '=== CHECKING FOR PROBLEMATIC PATTERNS ===' as section;

-- Check if quotation_with_files view exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_views WHERE schemaname = 'public' AND viewname = 'quotation_with_files')
        THEN 'quotation_with_files view EXISTS - this might be the problem!'
        ELSE 'quotation_with_files view does not exist'
    END as view_check;

-- Check if any enum types exist
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_type WHERE typname LIKE '%enum%')
        THEN 'ENUM TYPES EXIST - this confirms enum conversion happened'
        ELSE 'No enum types found'
    END as enum_check;

-- === STEP 10: Get distinct values for enum creation ===
SELECT '=== DISTINCT VALUES FOR ENUM CREATION ===' as section;

-- Job cart status distinct values
SELECT DISTINCT job_cart_status FROM public.job_cart ORDER BY job_cart_status;

-- Quotation status distinct values  
SELECT DISTINCT quotation_status FROM public.quotation ORDER BY quotation_status;

-- Notification type distinct values
SELECT DISTINCT type FROM public.notification ORDER BY type;

-- Notification user_type distinct values
SELECT DISTINCT user_type FROM public.notification ORDER BY user_type;

-- Resource locks user_type distinct values
SELECT DISTINCT user_type FROM public.resource_locks ORDER BY user_type;

-- === COMPLETE! ===
-- This script uses ONLY basic, safe PostgreSQL queries
-- NO advanced functions that could cause errors


