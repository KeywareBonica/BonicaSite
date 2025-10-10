-- Rename all "Mandla Dlamini" duplicates (19 records) with different South African names

-- First, let's see the current "Mandla Dlamini" duplicates
SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_email,
    ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as row_num
FROM service_provider 
WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
ORDER BY created_at, service_provider_id;

-- Update all "Mandla Dlamini" duplicates with different names
-- Keep the first one as "Mandla Dlamini", rename the rest

UPDATE service_provider SET service_provider_name = 'Sipho', service_provider_surname = 'Zulu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 2
);

UPDATE service_provider SET service_provider_name = 'Nomsa', service_provider_surname = 'Morei'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 3
);

UPDATE service_provider SET service_provider_name = 'Lerato', service_provider_surname = 'Moipone'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 4
);

UPDATE service_provider SET service_provider_name = 'Thabo', service_provider_surname = 'Rambo'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 5
);

UPDATE service_provider SET service_provider_name = 'Mpho', service_provider_surname = 'Mngomezulu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 6
);

UPDATE service_provider SET service_provider_name = 'Kagiso', service_provider_surname = 'Thobejane'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 7
);

UPDATE service_provider SET service_provider_name = 'Refilwe', service_provider_surname = 'Mabena'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 8
);

UPDATE service_provider SET service_provider_name = 'Boitumelo', service_provider_surname = 'Mthembu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 9
);

UPDATE service_provider SET service_provider_name = 'Thandiwe', service_provider_surname = 'Nkosi'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 10
);

UPDATE service_provider SET service_provider_name = 'Sibusiso', service_provider_surname = 'Khumalo'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 11
);

UPDATE service_provider SET service_provider_name = 'Ntombi', service_provider_surname = 'Mahlangu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 12
);

UPDATE service_provider SET service_provider_name = 'Khaya', service_provider_surname = 'Molefe'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 13
);

UPDATE service_provider SET service_provider_name = 'Puleng', service_provider_surname = 'Dlamini'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 14
);

UPDATE service_provider SET service_provider_name = 'Vusi', service_provider_surname = 'Mthembu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 15
);

UPDATE service_provider SET service_provider_name = 'Tshepo', service_provider_surname = 'Zulu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 16
);

UPDATE service_provider SET service_provider_name = 'Bongani', service_provider_surname = 'Morei'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 17
);

UPDATE service_provider SET service_provider_name = 'Zanele', service_provider_surname = 'Moipone'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 18
);

UPDATE service_provider SET service_provider_name = 'Mandla', service_provider_surname = 'Rambo'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
    ) t WHERE rn = 19
);

-- Verify the results
SELECT 
    service_provider_name,
    service_provider_surname,
    COUNT(*) as count
FROM service_provider 
WHERE service_provider_name IN ('Mandla', 'Sipho', 'Nomsa', 'Lerato', 'Thabo', 'Mpho', 'Kagiso', 'Refilwe', 'Boitumelo', 'Thandiwe', 'Sibusiso', 'Ntombi', 'Khaya', 'Puleng', 'Vusi', 'Tshepo', 'Bongani', 'Zanele')
AND service_provider_surname IN ('Dlamini', 'Zulu', 'Morei', 'Moipone', 'Rambo', 'Mngomezulu', 'Thobejane', 'Mabena', 'Mthembu', 'Nkosi', 'Khumalo', 'Mahlangu', 'Molefe')
GROUP BY service_provider_name, service_provider_surname
ORDER BY count DESC;

-- Final verification - should only have 1 "Mandla Dlamini" now
SELECT 
    service_provider_name,
    service_provider_surname,
    COUNT(*) as count
FROM service_provider 
WHERE service_provider_name = 'Mandla' AND service_provider_surname = 'Dlamini'
GROUP BY service_provider_name, service_provider_surname;
