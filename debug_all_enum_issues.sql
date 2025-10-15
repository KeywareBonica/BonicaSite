-- === COMPREHENSIVE ENUM DEBUG SCRIPT ===
-- This script finds ALL enum-related issues in your database

-- === STEP 1: Check what enums currently exist ===
SELECT '=== EXISTING ENUMS ===' as section;

SELECT 
    typname as enum_name,
    enumlabel as enum_value,
    enumsortorder as sort_order
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
ORDER BY typname, enumsortorder;

-- === STEP 2: Check column types and data types ===
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

-- === STEP 3: Check actual data values in your tables ===
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

-- === STEP 4: Find ALL views that might have enum issues ===
SELECT '=== VIEWS WITH POTENTIAL ENUM ISSUES ===' as section;

SELECT 
    schemaname,
    viewname,
    CASE 
        WHEN LENGTH(definition) > 500 THEN LEFT(definition, 500) || '...'
        ELSE definition
    END as definition_preview
FROM pg_views 
WHERE schemaname = 'public'
AND (definition ILIKE '%enum%' 
     OR definition ILIKE '%status%' 
     OR definition ILIKE '%type%'
     OR definition ILIKE '%notification%'
     OR definition ILIKE '%quotation%'
     OR definition ILIKE '%job_cart%');

-- === STEP 5: Find ALL functions that might have enum issues ===
SELECT '=== FUNCTIONS WITH POTENTIAL ENUM ISSUES ===' as section;

SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    CASE 
        WHEN LENGTH(pg_get_functiondef(p.oid)) > 500 THEN LEFT(pg_get_functiondef(p.oid), 500) || '...'
        ELSE pg_get_functiondef(p.oid)
    END as function_preview
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND (pg_get_functiondef(p.oid) ILIKE '%enum%' 
     OR pg_get_functiondef(p.oid) ILIKE '%status%' 
     OR pg_get_functiondef(p.oid) ILIKE '%type%'
     OR pg_get_functiondef(p.oid) ILIKE '%notification%'
     OR pg_get_functiondef(p.oid) ILIKE '%quotation%'
     OR pg_get_functiondef(p.oid) ILIKE '%job_cart%');

-- === STEP 6: Find ALL triggers that might have enum issues ===
SELECT '=== TRIGGERS WITH POTENTIAL ENUM ISSUES ===' as section;

SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND (action_statement ILIKE '%enum%' 
     OR action_statement ILIKE '%status%' 
     OR action_statement ILIKE '%type%'
     OR action_statement ILIKE '%notification%'
     OR action_statement ILIKE '%quotation%'
     OR action_statement ILIKE '%job_cart%');

-- === STEP 7: Find ALL policies that might have enum issues ===
SELECT '=== POLICIES WITH POTENTIAL ENUM ISSUES ===' as section;

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
AND (qual ILIKE '%enum%' 
     OR qual ILIKE '%status%' 
     OR qual ILIKE '%type%'
     OR qual ILIKE '%notification%'
     OR qual ILIKE '%quotation%'
     OR qual ILIKE '%job_cart%'
     OR with_check ILIKE '%enum%' 
     OR with_check ILIKE '%status%' 
     OR with_check ILIKE '%type%'
     OR with_check ILIKE '%notification%'
     OR with_check ILIKE '%quotation%'
     OR with_check ILIKE '%job_cart%');

-- === STEP 8: Find ALL constraints that might have enum issues ===
SELECT '=== CONSTRAINTS WITH POTENTIAL ENUM ISSUES ===' as section;

SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public'
AND (cc.check_clause ILIKE '%enum%' 
     OR cc.check_clause ILIKE '%status%' 
     OR cc.check_clause ILIKE '%type%'
     OR cc.check_clause ILIKE '%notification%'
     OR cc.check_clause ILIKE '%quotation%'
     OR cc.check_clause ILIKE '%job_cart%');

-- === STEP 9: Find ALL indexes that might have enum issues ===
SELECT '=== INDEXES WITH POTENTIAL ENUM ISSUES ===' as section;

SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
AND (indexdef ILIKE '%enum%' 
     OR indexdef ILIKE '%status%' 
     OR indexdef ILIKE '%type%'
     OR indexdef ILIKE '%notification%'
     OR indexdef ILIKE '%quotation%'
     OR indexdef ILIKE '%job_cart%');

-- === STEP 10: Check for any remaining problematic objects ===
SELECT '=== SUMMARY OF POTENTIAL PROBLEMS ===' as section;

SELECT 
    'View' as object_type,
    viewname as object_name,
    'Has enum-related code' as issue
FROM pg_views 
WHERE schemaname = 'public'
AND definition ILIKE '%notification%type%'

UNION ALL

SELECT 
    'Function' as object_type,
    p.proname as object_name,
    'Has enum-related code' as issue
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND pg_get_functiondef(p.oid) ILIKE '%notification%type%'

UNION ALL

SELECT 
    'Trigger' as object_type,
    trigger_name as object_name,
    'Has enum-related code' as issue
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND action_statement ILIKE '%notification%type%'

UNION ALL

SELECT 
    'Policy' as object_type,
    policyname as object_name,
    'Has enum-related code' as issue
FROM pg_policies 
WHERE schemaname = 'public'
AND (qual ILIKE '%notification%type%' OR with_check ILIKE '%notification%type%')

UNION ALL

SELECT 
    'Constraint' as object_type,
    constraint_name as object_name,
    'Has enum-related code' as issue
FROM information_schema.check_constraints cc
WHERE cc.check_clause ILIKE '%notification%type%';

-- === STEP 11: Suggested enum definitions based on actual data ===
SELECT '=== SUGGESTED ENUM DEFINITIONS ===' as section;

-- Job Cart Status values
SELECT 
    'Job Cart Status Enum should include:' as suggestion, 
    STRING_AGG(DISTINCT job_cart_status, ', ' ORDER BY job_cart_status) as values
FROM public.job_cart;

-- Quotation Status values  
SELECT 
    'Quotation Status Enum should include:' as suggestion, 
    STRING_AGG(DISTINCT quotation_status, ', ' ORDER BY quotation_status) as values
FROM public.quotation;

-- Notification Type values
SELECT 
    'Notification Type Enum should include:' as suggestion, 
    STRING_AGG(DISTINCT type, ', ' ORDER BY type) as values
FROM public.notification;

-- Notification User Type values
SELECT 
    'Notification User Type Enum should include:' as suggestion, 
    STRING_AGG(DISTINCT user_type, ', ' ORDER BY user_type) as values
FROM public.notification;

-- Resource Locks User Type values
SELECT 
    'Resource Locks User Type Enum should include:' as suggestion, 
    STRING_AGG(DISTINCT user_type, ', ' ORDER BY user_type) as values
FROM public.resource_locks;
