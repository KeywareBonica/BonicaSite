-- Check if service IDs in service.json match the ones in the database
-- This script will help identify mismatches between service.json and database

-- Step 1: Show all services currently in the database
SELECT 
    'DATABASE SERVICES' as source,
    service_id,
    service_name,
    service_type,
    service_description
FROM service
ORDER BY service_name;

-- Step 2: Check for invalid UUID characters in service.json
-- Note: The service.json file contains invalid UUID characters like 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
-- Valid UUID characters are only: 0-9, a-f, and hyphens

-- Step 3: Count total services in database vs expected from service.json
SELECT 
    'SERVICE COUNT COMPARISON' as check_type,
    'Database' as source,
    COUNT(*) as service_count
FROM service

UNION ALL

SELECT 
    'SERVICE COUNT COMPARISON' as check_type,
    'service.json (expected)' as source,
    26 as service_count;

-- Step 4: Check for services that might exist in database but not in service.json
-- (This would show if database has more services than expected)

-- Step 5: List service names from database to compare with service.json
SELECT 
    'SERVICE NAMES IN DATABASE' as check_type,
    service_name,
    service_type,
    service_id
FROM service
ORDER BY service_name;

-- Step 6: Check for duplicate service names in database
SELECT 
    'DUPLICATE SERVICE NAMES CHECK' as check_type,
    service_name,
    COUNT(*) as duplicate_count,
    STRING_AGG(service_id::text, ', ') as service_ids
FROM service
GROUP BY service_name
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Step 7: Show invalid UUIDs that would cause issues
-- (These are the UUIDs from service.json that contain invalid characters)
SELECT 
    'INVALID UUIDs IN SERVICE.JSON' as issue_type,
    'These UUIDs contain invalid characters (g-z) and need to be fixed' as description;

-- Invalid UUIDs from service.json (for reference):
-- b2c3d4e5-f6g7-8901-bcde-f23456789012 (contains 'g')
-- c3d4e5f6-g7h8-9012-cdef-345678901234 (contains 'g', 'h')
-- d4e5f6g7-h8i9-0123-def0-456789012345 (contains 'g', 'h', 'i')
-- e5f6g7h8-i9j0-1234-ef01-567890123456 (contains 'g', 'h', 'i', 'j')
-- f6g7h8i9-j0k1-2345-f012-678901234567 (contains 'g', 'h', 'i', 'j', 'k')
-- g7h8i9j0-k1l2-3456-0123-789012345678 (contains 'g', 'h', 'i', 'j', 'k', 'l')
-- h8i9j0k1-l2m3-4567-1234-890123456789 (contains 'h', 'i', 'j', 'k', 'l', 'm')
-- i9j0k1l2-m3n4-5678-2345-901234567890 (contains 'i', 'j', 'k', 'l', 'm', 'n')
-- j0k1l2m3-n4o5-6789-3456-012345678901 (contains 'j', 'k', 'l', 'm', 'n', 'o')
-- k1l2m3n4-o5p6-7890-4567-123456789012 (contains 'k', 'l', 'm', 'n', 'o', 'p')
-- l2m3n4o5-p6q7-8901-5678-234567890123 (contains 'l', 'm', 'n', 'o', 'p', 'q')
-- m3n4o5p6-q7r8-9012-6789-345678901234 (contains 'm', 'n', 'o', 'p', 'q', 'r')
-- n4o5p6q7-r8s9-0123-7890-456789012345 (contains 'n', 'o', 'p', 'q', 'r', 's')
-- o5p6q7r8-s9t0-1234-8901-567890123456 (contains 'o', 'p', 'q', 'r', 's', 't')
-- p6q7r8s9-t0u1-2345-9012-678901234567 (contains 'p', 'q', 'r', 's', 't', 'u')
-- q7r8s9t0-u1v2-3456-0123-789012345678 (contains 'q', 'r', 's', 't', 'u', 'v')
-- r8s9t0u1-v2w3-4567-1234-890123456789 (contains 'r', 's', 't', 'u', 'v', 'w')
-- s9t0u1v2-w3x4-5678-2345-901234567890 (contains 's', 't', 'u', 'v', 'w', 'x')
-- t0u1v2w3-x4y5-6789-3456-012345678901 (contains 't', 'u', 'v', 'w', 'x', 'y')
-- u1v2w3x4-y5z6-7890-4567-123456789012 (contains 'u', 'v', 'w', 'x', 'y', 'z')
-- v2w3x4y5-z6a7-8901-5678-234567890123 (contains 'v', 'w', 'x', 'y', 'z')
-- w3x4y5z6-a7b8-9012-6789-345678901234 (contains 'w', 'x', 'y', 'z')

-- Step 8: Summary of issues found
SELECT 
    'SUMMARY OF ISSUES' as check_type,
    'service.json contains 26 services with invalid UUID characters' as issue_1,
    'Valid UUIDs should only contain: 0-9, a-f, and hyphens' as solution_1,
    'Need to replace invalid characters with valid hex characters' as solution_2;
