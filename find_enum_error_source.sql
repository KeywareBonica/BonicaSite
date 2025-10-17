-- === FIND THE SOURCE OF THE ENUM ERROR ===
-- Run this to identify exactly where the enum comparison error is coming from

-- Check for views that might have enum comparisons
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public'
AND (definition ILIKE '%notification%type%' OR definition ILIKE '%enum%');

-- Check for functions that might have enum comparisons
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND (pg_get_functiondef(p.oid) ILIKE '%notification%type%' OR pg_get_functiondef(p.oid) ILIKE '%enum%');

-- Check for triggers that might have enum comparisons
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND (action_statement ILIKE '%notification%type%' OR action_statement ILIKE '%enum%');

-- Check for policies that might have enum comparisons
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
AND (qual ILIKE '%notification%type%' OR with_check ILIKE '%notification%type%');

-- Check for any remaining problematic objects
SELECT 
    'View' as object_type,
    viewname as object_name,
    definition
FROM pg_views 
WHERE schemaname = 'public'
AND definition ILIKE '%notification%type%'

UNION ALL

SELECT 
    'Function' as object_type,
    proname as object_name,
    pg_get_functiondef(oid) as definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND pg_get_functiondef(oid) ILIKE '%notification%type%'

UNION ALL

SELECT 
    'Trigger' as object_type,
    trigger_name as object_name,
    action_statement as definition
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND action_statement ILIKE '%notification%type%';







