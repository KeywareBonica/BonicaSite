-- Rename all "Robert Jones" duplicates (10 records) with different South African names

-- First, let's see the current "Robert Jones" duplicates
SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_email,
    ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as row_num
FROM service_provider 
WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
ORDER BY created_at, service_provider_id;

-- Update all "Robert Jones" duplicates with different names
-- Keep the first one as "Robert Jones", rename the rest

UPDATE service_provider SET service_provider_name = 'Sipho', service_provider_surname = 'Zulu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 2
);

UPDATE service_provider SET service_provider_name = 'Nomsa', service_provider_surname = 'Morei'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 3
);

UPDATE service_provider SET service_provider_name = 'Lerato', service_provider_surname = 'Moipone'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 4
);

UPDATE service_provider SET service_provider_name = 'Thabo', service_provider_surname = 'Rambo'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 5
);

UPDATE service_provider SET service_provider_name = 'Mpho', service_provider_surname = 'Mngomezulu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 6
);

UPDATE service_provider SET service_provider_name = 'Kagiso', service_provider_surname = 'Thobejane'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 7
);

UPDATE service_provider SET service_provider_name = 'Refilwe', service_provider_surname = 'Mabena'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 8
);

UPDATE service_provider SET service_provider_name = 'Boitumelo', service_provider_surname = 'Mthembu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 9
);

UPDATE service_provider SET service_provider_name = 'Thandiwe', service_provider_surname = 'Nkosi'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 10
);

-- Final verification - should only have 1 "Robert Jones" now
SELECT 
    service_provider_name,
    service_provider_surname,
    COUNT(*) as count
FROM service_provider 
WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
GROUP BY service_provider_name, service_provider_surname;
