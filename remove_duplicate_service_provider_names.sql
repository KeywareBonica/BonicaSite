-- Remove duplicate service provider names from the service_provider table
-- This script will keep the first occurrence of each name and remove subsequent duplicates

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

-- Create a temporary table to identify which records to keep
CREATE TEMP TABLE service_provider_duplicates AS
SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    ROW_NUMBER() OVER (
        PARTITION BY service_provider_name, service_provider_surname 
        ORDER BY created_at ASC, service_provider_id ASC
    ) as row_num
FROM service_provider;

-- Show which records will be kept vs removed
SELECT 
    service_provider_name,
    service_provider_surname,
    service_provider_id,
    CASE 
        WHEN row_num = 1 THEN 'KEEP'
        ELSE 'REMOVE'
    END as action
FROM service_provider_duplicates
WHERE (service_provider_name, service_provider_surname) IN (
    SELECT service_provider_name, service_provider_surname 
    FROM service_provider 
    GROUP BY service_provider_name, service_provider_surname 
    HAVING COUNT(*) > 1
)
ORDER BY service_provider_name, service_provider_surname, row_num;

-- Get the IDs of records to remove
CREATE TEMP TABLE records_to_remove AS
SELECT service_provider_id
FROM service_provider_duplicates
WHERE row_num > 1;

-- Check if any of these service providers are referenced in quotations
SELECT 
    sp.service_provider_name,
    sp.service_provider_surname,
    COUNT(q.quotation_id) as quotation_count
FROM service_provider sp
JOIN records_to_remove rtr ON sp.service_provider_id = rtr.service_provider_id
LEFT JOIN quotation q ON sp.service_provider_id = q.service_provider_id
GROUP BY sp.service_provider_id, sp.service_provider_name, sp.service_provider_surname
ORDER BY quotation_count DESC;

-- If there are quotations linked to duplicate service providers, 
-- we need to reassign them to the kept service provider
-- First, create a mapping table
CREATE TEMP TABLE service_provider_mapping AS
SELECT 
    spd_remove.service_provider_id as old_id,
    spd_keep.service_provider_id as new_id,
    spd_remove.service_provider_name,
    spd_remove.service_provider_surname
FROM service_provider_duplicates spd_remove
JOIN service_provider_duplicates spd_keep ON 
    spd_remove.service_provider_name = spd_keep.service_provider_name AND
    spd_remove.service_provider_surname = spd_keep.service_provider_surname AND
    spd_keep.row_num = 1
WHERE spd_remove.row_num > 1;

-- Show the mapping
SELECT 
    old_id,
    new_id,
    service_provider_name,
    service_provider_surname
FROM service_provider_mapping
ORDER BY service_provider_name, service_provider_surname;

-- Update quotations to point to the kept service provider
UPDATE quotation 
SET service_provider_id = sm.new_id
FROM service_provider_mapping sm
WHERE quotation.service_provider_id = sm.old_id;

-- Update any other tables that might reference service_provider_id
-- (Add more UPDATE statements here if needed for other tables)

-- Now remove the duplicate service providers
DELETE FROM service_provider 
WHERE service_provider_id IN (SELECT service_provider_id FROM records_to_remove);

-- Verify the results
SELECT 
    service_provider_name,
    service_provider_surname,
    COUNT(*) as count
FROM service_provider 
GROUP BY service_provider_name, service_provider_surname
HAVING COUNT(*) > 1;

-- Show final count
SELECT 
    COUNT(*) as total_service_providers,
    COUNT(DISTINCT CONCAT(service_provider_name, ' ', service_provider_surname)) as unique_names
FROM service_provider;

-- Clean up temporary tables
DROP TABLE IF EXISTS service_provider_duplicates;
DROP TABLE IF EXISTS records_to_remove;
DROP TABLE IF EXISTS service_provider_mapping;
