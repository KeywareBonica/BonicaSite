-- === BASIC ENUM DEBUG - ONE QUERY AT A TIME ===

-- Query 1: Check what enums exist
SELECT 'EXISTING ENUMS:' as info;
SELECT typname as enum_name, enumlabel as enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
ORDER BY typname, enumlabel;


