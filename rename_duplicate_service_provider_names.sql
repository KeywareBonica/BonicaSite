-- Rename duplicate service provider names to make them all unique
-- This script will keep the first occurrence and rename subsequent duplicates

-- First, let's see what duplicates we have
SELECT 
    service_provider_name,
    service_provider_surname,
    COUNT(*) as duplicate_count,
    STRING_AGG(service_provider_id::text, ', ') as service_provider_ids
FROM service_provider 
GROUP BY service_provider_name, service_provider_surname
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Create a temporary table to identify duplicates and assign new names
CREATE TEMP TABLE service_provider_rename AS
SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    ROW_NUMBER() OVER (
        PARTITION BY service_provider_name, service_provider_surname 
        ORDER BY created_at ASC, service_provider_id ASC
    ) as row_num,
    -- Generate new names for duplicates
    CASE 
        WHEN ROW_NUMBER() OVER (
            PARTITION BY service_provider_name, service_provider_surname 
            ORDER BY created_at ASC, service_provider_id ASC
        ) = 1 THEN service_provider_name
        ELSE service_provider_name || ' ' || (
            ROW_NUMBER() OVER (
                PARTITION BY service_provider_name, service_provider_surname 
                ORDER BY created_at ASC, service_provider_id ASC
            )
        )::text
    END as new_name,
    CASE 
        WHEN ROW_NUMBER() OVER (
            PARTITION BY service_provider_name, service_provider_surname 
            ORDER BY created_at ASC, service_provider_id ASC
        ) = 1 THEN service_provider_surname
        ELSE service_provider_surname || ' ' || (
            ROW_NUMBER() OVER (
                PARTITION BY service_provider_name, service_provider_surname 
                ORDER BY created_at ASC, service_provider_id ASC
            )
        )::text
    END as new_surname
FROM service_provider;

-- Show what names will be changed
SELECT 
    service_provider_id,
    service_provider_name as old_name,
    service_provider_surname as old_surname,
    new_name,
    new_surname,
    CASE 
        WHEN row_num = 1 THEN 'KEEP ORIGINAL'
        ELSE 'RENAME TO: ' || new_name || ' ' || new_surname
    END as action
FROM service_provider_rename
WHERE (service_provider_name, service_provider_surname) IN (
    SELECT service_provider_name, service_provider_surname 
    FROM service_provider 
    GROUP BY service_provider_name, service_provider_surname 
    HAVING COUNT(*) > 1
)
ORDER BY service_provider_name, service_provider_surname, row_num;

-- Update the service provider names
UPDATE service_provider 
SET 
    service_provider_name = spr.new_name,
    service_provider_surname = spr.new_surname
FROM service_provider_rename spr
WHERE service_provider.service_provider_id = spr.service_provider_id
AND spr.row_num > 1; -- Only update duplicates, keep original names

-- Verify the results - should show no duplicates now
SELECT 
    service_provider_name,
    service_provider_surname,
    COUNT(*) as count
FROM service_provider 
GROUP BY service_provider_name, service_provider_surname
HAVING COUNT(*) > 1;

-- Show some examples of the renamed service providers
SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_email,
    service_provider_service_type
FROM service_provider 
WHERE service_provider_name LIKE '% %' -- Names with spaces (likely renamed)
ORDER BY service_provider_name, service_provider_surname
LIMIT 20;

-- Show final count
SELECT 
    COUNT(*) as total_service_providers,
    COUNT(DISTINCT CONCAT(service_provider_name, ' ', service_provider_surname)) as unique_names
FROM service_provider;

-- Clean up temporary table
DROP TABLE IF EXISTS service_provider_rename;
