-- === SIMPLE ENUM DEBUG SCRIPT - NO PG_GET_FUNCTIONDEF ===
-- This script avoids pg_get_functiondef() to prevent array_agg errors
-- Focuses on finding the exact source of enum issues

-- === STEP 1: Check what enums currently exist ===
SELECT '=== EXISTING ENUMS ===' as section;

SELECT 
    typname as enum_name,
    enumlabel as enum_value,
    enumsortorder as sort_order
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
ORDER BY typname, enumsortorder;

-- === STEP 2: Check column types ===
SELECT '=== COLUMN TYPES ===' as section;

SELECT 
    table_name, 
    column_name, 
    data_type,
    CASE 
        WHEN data_type = 'USER-DEFINED' THEN udt_name
        ELSE data_type
    END as actual_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND (data_type = 'USER-DEFINED' OR column_name LIKE '%status%' OR column_name LIKE '%type%')
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

-- === STEP 4: Find ALL views (without function definitions) ===
SELECT '=== ALL VIEWS ===' as section;

SELECT 
    schemaname,
    viewname,
    CASE 
        WHEN LENGTH(definition) > 500 THEN LEFT(definition, 500) || '...'
        ELSE definition
    END as definition_preview
FROM pg_views 
WHERE schemaname = 'public'
ORDER BY viewname;

-- === STEP 5: Find ALL functions (names only, no definitions) ===
SELECT '=== ALL FUNCTIONS ===' as section;

SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
ORDER BY p.proname;

-- === STEP 6: Find ALL triggers ===
SELECT '=== ALL TRIGGERS ===' as section;

SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
ORDER BY trigger_name;

-- === STEP 7: Find ALL policies ===
SELECT '=== ALL POLICIES ===' as section;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY policyname;

-- === STEP 8: Find ALL constraints ===
SELECT '=== ALL CONSTRAINTS ===' as section;

SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- === STEP 9: Suggested enum definitions ===
SELECT '=== SUGGESTED ENUM DEFINITIONS ===' as section;

-- Job Cart Status values
SELECT 
    'Job Cart Status Enum should include:' as suggestion, 
    STRING_AGG(job_cart_status, ', ' ORDER BY job_cart_status) as values
FROM (
    SELECT DISTINCT job_cart_status 
    FROM public.job_cart
) sub;

-- Quotation Status values
SELECT 
    'Quotation Status Enum should include:' as suggestion, 
    STRING_AGG(quotation_status, ', ' ORDER BY quotation_status) as values
FROM (
    SELECT DISTINCT quotation_status
    FROM public.quotation
) sub;

-- Notification Type values
SELECT 
    'Notification Type Enum should include:' as suggestion, 
    STRING_AGG(type, ', ' ORDER BY type) as values
FROM (
    SELECT DISTINCT type
    FROM public.notification
) sub;

-- Notification User Type values
SELECT 
    'Notification User Type Enum should include:' as suggestion, 
    STRING_AGG(user_type, ', ' ORDER BY user_type) as values
FROM (
    SELECT DISTINCT user_type
    FROM public.notification
) sub;

-- Resource Locks User Type values
SELECT 
    'Resource Locks User Type Enum should include:' as suggestion, 
    STRING_AGG(user_type, ', ' ORDER BY user_type) as values
FROM (
    SELECT DISTINCT user_type
    FROM public.resource_locks
) sub;

-- === COMPLETE! ===
-- This script avoids pg_get_functiondef() entirely to prevent array_agg errors


