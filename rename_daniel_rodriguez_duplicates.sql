-- Rename all "Daniel Rodriguez" duplicates (10 records) with different South African names

-- First, let's see the current "Daniel Rodriguez" duplicates
SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_email,
    ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as row_num
FROM service_provider 
WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
ORDER BY created_at, service_provider_id;

-- Update all "Daniel Rodriguez" duplicates with different names
-- Keep the first one as "Daniel Rodriguez", rename the rest

UPDATE service_provider SET service_provider_name = 'Sibusiso', service_provider_surname = 'Zulu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 2
);

UPDATE service_provider SET service_provider_name = 'Ntombi', service_provider_surname = 'Morei'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 3
);

UPDATE service_provider SET service_provider_name = 'Khaya', service_provider_surname = 'Moipone'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 4
);

UPDATE service_provider SET service_provider_name = 'Puleng', service_provider_surname = 'Rambo'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 5
);

UPDATE service_provider SET service_provider_name = 'Vusi', service_provider_surname = 'Mngomezulu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 6
);

UPDATE service_provider SET service_provider_name = 'Tshepo', service_provider_surname = 'Thobejane'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 7
);

UPDATE service_provider SET service_provider_name = 'Bongani', service_provider_surname = 'Mabena'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 8
);

UPDATE service_provider SET service_provider_name = 'Zanele', service_provider_surname = 'Mthembu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 9
);

UPDATE service_provider SET service_provider_name = 'Mandla', service_provider_surname = 'Nkosi'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 10
);

-- Final verification - should only have 1 "Daniel Rodriguez" now
SELECT 
    service_provider_name,
    service_provider_surname,
    COUNT(*) as count
FROM service_provider 
WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
GROUP BY service_provider_name, service_provider_surname;
