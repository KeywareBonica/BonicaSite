-- ===============================================
-- REPLACE DUPLICATE NAMES WITH REAL SOUTH AFRICAN NAMES
-- ===============================================

-- Step 1: Replace duplicate names with actual different names
-- Hair Styling & Makeup duplicates
UPDATE service_provider 
SET service_provider_name = 'Thandi', service_provider_surname = 'Nkosi'
WHERE service_provider_name = 'Nomsa' AND service_provider_surname = 'Mthembu' 
AND service_provider_id IN (
    SELECT service_provider_id FROM service_provider 
    WHERE service_provider_name = 'Nomsa' AND service_provider_surname = 'Mthembu'
    ORDER BY service_provider_id OFFSET 1 LIMIT 10
);

UPDATE service_provider 
SET service_provider_name = 'Zanele', service_provider_surname = 'Mthembu'
WHERE service_provider_name = 'Nomsa' AND service_provider_surname = 'Mthembu' 
AND service_provider_id IN (
    SELECT service_provider_id FROM service_provider 
    WHERE service_provider_name = 'Nomsa' AND service_provider_surname = 'Mthembu'
    ORDER BY service_provider_id OFFSET 11 LIMIT 10
);

UPDATE service_provider 
SET service_provider_name = 'Nomsa', service_provider_surname = 'Zulu'
WHERE service_provider_name = 'Nomsa' AND service_provider_surname = 'Mthembu' 
AND service_provider_id IN (
    SELECT service_provider_id FROM service_provider 
    WHERE service_provider_name = 'Nomsa' AND service_provider_surname = 'Mthembu'
    ORDER BY service_provider_id OFFSET 21 LIMIT 10
);

UPDATE service_provider 
SET service_provider_name = 'Precious', service_provider_surname = 'Mthembu'
WHERE service_provider_name = 'Nomsa' AND service_provider_surname = 'Mthembu' 
AND service_provider_id IN (
    SELECT service_provider_id FROM service_provider 
    WHERE service_provider_name = 'Nomsa' AND service_provider_surname = 'Mthembu'
    ORDER BY service_provider_id OFFSET 31 LIMIT 10
);

UPDATE service_provider 
SET service_provider_name = 'Lerato', service_provider_surname = 'Mthembu'
WHERE service_provider_name = 'Nomsa' AND service_provider_surname = 'Mthembu' 
AND service_provider_id IN (
    SELECT service_provider_id FROM service_provider 
    WHERE service_provider_name = 'Nomsa' AND service_provider_surname = 'Mthembu'
    ORDER BY service_provider_id OFFSET 41 LIMIT 10
);

-- Photography duplicates
UPDATE service_provider 
SET service_provider_name = 'Mandla', service_provider_surname = 'Dlamini'
WHERE service_provider_name = 'Sipho' AND service_provider_surname = 'Mthembu' 
AND service_provider_id IN (
    SELECT service_provider_id FROM service_provider 
    WHERE service_provider_name = 'Sipho' AND service_provider_surname = 'Mthembu'
    ORDER BY service_provider_id OFFSET 1 LIMIT 10
);

UPDATE service_provider 
SET service_provider_name = 'Bongani', service_provider_surname = 'Mthembu'
WHERE service_provider_name = 'Sipho' AND service_provider_surname = 'Mthembu' 
AND service_provider_id IN (
    SELECT service_provider_id FROM service_provider 
    WHERE service_provider_name = 'Sipho' AND service_provider_surname = 'Mthembu'
    ORDER BY service_provider_id OFFSET 11 LIMIT 10
);

UPDATE service_provider 
SET service_provider_name = 'Sipho', service_provider_surname = 'Zulu'
WHERE service_provider_name = 'Sipho' AND service_provider_surname = 'Mthembu' 
AND service_provider_id IN (
    SELECT service_provider_id FROM service_provider 
    WHERE service_provider_name = 'Sipho' AND service_provider_surname = 'Mthembu'
    ORDER BY service_provider_id OFFSET 21 LIMIT 10
);

UPDATE service_provider 
SET service_provider_name = 'Thabo', service_provider_surname = 'Mthembu'
WHERE service_provider_name = 'Sipho' AND service_provider_surname = 'Mthembu' 
AND service_provider_id IN (
    SELECT service_provider_id FROM service_provider 
    WHERE service_provider_name = 'Sipho' AND service_provider_surname = 'Mthembu'
    ORDER BY service_provider_id OFFSET 31 LIMIT 10
);

UPDATE service_provider 
SET service_provider_name = 'Sipho', service_provider_surname = 'Nkosi'
WHERE service_provider_name = 'Sipho' AND service_provider_surname = 'Mthembu' 
AND service_provider_id IN (
    SELECT service_provider_id FROM service_provider 
    WHERE service_provider_name = 'Sipho' AND service_provider_surname = 'Mthembu'
    ORDER BY service_provider_id OFFSET 41 LIMIT 10
);

-- Step 2: Update emails to match new names
UPDATE service_provider 
SET service_provider_email = LOWER(service_provider_name) || '.' || LOWER(service_provider_surname) || '.' || SUBSTRING(service_provider_id::text, 1, 8) || '@email.com';

-- Step 3: Verification - Check if names are now unique
SELECT 
    'After Fix - Duplicate Names:' AS info,
    service_provider_name,
    service_provider_surname,
    COUNT(*) AS count
FROM service_provider
GROUP BY service_provider_name, service_provider_surname
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- Step 4: Sample of updated names
SELECT 
    'Sample Updated Names:' AS info,
    sp.service_provider_name,
    sp.service_provider_surname,
    sp.service_provider_email,
    s.service_name
FROM service_provider sp
JOIN service s ON sp.service_id = s.service_id
ORDER BY s.service_name, sp.service_provider_name
LIMIT 20;

-- Step 5: Check total counts
SELECT 'Total Service Providers:' AS info, COUNT(*) AS count FROM service_provider;
SELECT 'Unique Name Combinations:' AS info, COUNT(DISTINCT service_provider_name || ' ' || service_provider_surname) AS count FROM service_provider;
