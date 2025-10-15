-- === DEBUG SCRIPT: Find enum comparison issues ===
-- This script helps identify where enum vs text comparisons are failing

-- === STEP 1: Check current enum values in your data ===
SELECT '=== CURRENT DATA VALUES ===' as info;

SELECT 'job_cart_status values:' as table_column, job_cart_status as value, COUNT(*) as count
FROM public.job_cart 
GROUP BY job_cart_status
ORDER BY job_cart_status;

SELECT 'quotation_status values:' as table_column, quotation_status as value, COUNT(*) as count
FROM public.quotation 
GROUP BY quotation_status
ORDER BY quotation_status;

SELECT 'notification.type values:' as table_column, type as value, COUNT(*) as count
FROM public.notification 
GROUP BY type
ORDER BY type;

SELECT 'notification.user_type values:' as table_column, user_type as value, COUNT(*) as count
FROM public.notification 
GROUP BY user_type
ORDER BY user_type;

SELECT 'resource_locks.user_type values:' as table_column, user_type as value, COUNT(*) as count
FROM public.resource_locks 
GROUP BY user_type
ORDER BY user_type;

-- === STEP 2: Check what enums exist ===
SELECT '=== EXISTING ENUMS ===' as info;

SELECT typname as enum_name, enumlabel as enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
ORDER BY typname, enumsortorder;

-- === STEP 3: Check column types ===
SELECT '=== COLUMN TYPES ===' as info;

SELECT 
    table_name, 
    column_name, 
    data_type,
    CASE 
        WHEN data_type = 'USER-DEFINED' THEN udt_name
        ELSE data_type
    END as actual_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND column_name IN ('job_cart_status', 'quotation_status', 'type', 'user_type')
ORDER BY table_name, column_name;

-- === STEP 4: Check for views that might have enum comparisons ===
SELECT '=== VIEWS WITH POTENTIAL ENUM ISSUES ===' as info;

SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public'
AND (definition ILIKE '%notification%type%' OR definition ILIKE '%enum%');

-- === STEP 5: Check for functions that might have enum comparisons ===
SELECT '=== FUNCTIONS WITH POTENTIAL ENUM ISSUES ===' as info;

SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND (pg_get_functiondef(p.oid) ILIKE '%notification%type%' OR pg_get_functiondef(p.oid) ILIKE '%enum%');

-- === STEP 6: Check for triggers that might have enum issues ===
SELECT '=== TRIGGERS WITH POTENTIAL ENUM ISSUES ===' as info;

SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND (action_statement ILIKE '%notification%type%' OR action_statement ILIKE '%enum%');

-- === STEP 7: Create a comprehensive enum that includes ALL possible values ===
SELECT '=== SUGGESTED ENUM DEFINITIONS ===' as info;

-- This will show you what the enum definitions should include
SELECT 
    'Job Cart Status Enum should include:' as suggestion, 
    array_to_string(array_agg(DISTINCT job_cart_status ORDER BY job_cart_status), ', ') as values
FROM public.job_cart;

SELECT 
    'Quotation Status Enum should include:' as suggestion, 
    array_to_string(array_agg(DISTINCT quotation_status ORDER BY quotation_status), ', ') as values
FROM public.quotation;

SELECT 
    'Notification Type Enum should include:' as suggestion, 
    array_to_string(array_agg(DISTINCT type ORDER BY type), ', ') as values
FROM public.notification;

SELECT 
    'Notification User Type Enum should include:' as suggestion, 
    array_to_string(array_agg(DISTINCT user_type ORDER BY user_type), ', ') as values
FROM public.notification;

SELECT 
    'Resource Locks User Type Enum should include:' as suggestion, 
    array_to_string(array_agg(DISTINCT user_type ORDER BY user_type), ', ') as values
FROM public.resource_locks;
