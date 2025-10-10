-- Comprehensive script to rename ALL duplicate service provider names
-- This handles Mandla Dlamini (10), Robert Jones (10), Daniel Rodriguez (10), Kevin Martin (10)

-- First, let's see ALL current duplicates
SELECT 
    service_provider_name,
    service_provider_surname,
    COUNT(*) as count
FROM service_provider 
GROUP BY service_provider_name, service_provider_surname
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- Handle Mandla Dlamini duplicates (10 total)
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

-- Handle Robert Jones duplicates (10 total)
UPDATE service_provider SET service_provider_name = 'Sibusiso', service_provider_surname = 'Khumalo'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 2
);

UPDATE service_provider SET service_provider_name = 'Ntombi', service_provider_surname = 'Mahlangu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 3
);

UPDATE service_provider SET service_provider_name = 'Khaya', service_provider_surname = 'Molefe'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 4
);

UPDATE service_provider SET service_provider_name = 'Puleng', service_provider_surname = 'Dlamini'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 5
);

UPDATE service_provider SET service_provider_name = 'Vusi', service_provider_surname = 'Mthembu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 6
);

UPDATE service_provider SET service_provider_name = 'Tshepo', service_provider_surname = 'Zulu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 7
);

UPDATE service_provider SET service_provider_name = 'Bongani', service_provider_surname = 'Morei'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 8
);

UPDATE service_provider SET service_provider_name = 'Zanele', service_provider_surname = 'Moipone'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 9
);

UPDATE service_provider SET service_provider_name = 'Mandla', service_provider_surname = 'Rambo'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Robert' AND service_provider_surname = 'Jones'
    ) t WHERE rn = 10
);

-- Handle Daniel Rodriguez duplicates (10 total)
UPDATE service_provider SET service_provider_name = 'Lerato', service_provider_surname = 'Mngomezulu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 2
);

UPDATE service_provider SET service_provider_name = 'Thabo', service_provider_surname = 'Thobejane'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 3
);

UPDATE service_provider SET service_provider_name = 'Mpho', service_provider_surname = 'Mabena'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 4
);

UPDATE service_provider SET service_provider_name = 'Kagiso', service_provider_surname = 'Mthembu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 5
);

UPDATE service_provider SET service_provider_name = 'Refilwe', service_provider_surname = 'Nkosi'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 6
);

UPDATE service_provider SET service_provider_name = 'Boitumelo', service_provider_surname = 'Khumalo'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 7
);

UPDATE service_provider SET service_provider_name = 'Thandiwe', service_provider_surname = 'Mahlangu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 8
);

UPDATE service_provider SET service_provider_name = 'Sibusiso', service_provider_surname = 'Molefe'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 9
);

UPDATE service_provider SET service_provider_name = 'Ntombi', service_provider_surname = 'Dlamini'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Daniel' AND service_provider_surname = 'Rodriguez'
    ) t WHERE rn = 10
);

-- Handle Kevin Martin duplicates (10 total)
UPDATE service_provider SET service_provider_name = 'Khaya', service_provider_surname = 'Zulu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Kevin' AND service_provider_surname = 'Martin'
    ) t WHERE rn = 2
);

UPDATE service_provider SET service_provider_name = 'Puleng', service_provider_surname = 'Morei'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Kevin' AND service_provider_surname = 'Martin'
    ) t WHERE rn = 3
);

UPDATE service_provider SET service_provider_name = 'Vusi', service_provider_surname = 'Moipone'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Kevin' AND service_provider_surname = 'Martin'
    ) t WHERE rn = 4
);

UPDATE service_provider SET service_provider_name = 'Tshepo', service_provider_surname = 'Rambo'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Kevin' AND service_provider_surname = 'Martin'
    ) t WHERE rn = 5
);

UPDATE service_provider SET service_provider_name = 'Bongani', service_provider_surname = 'Mngomezulu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Kevin' AND service_provider_surname = 'Martin'
    ) t WHERE rn = 6
);

UPDATE service_provider SET service_provider_name = 'Zanele', service_provider_surname = 'Thobejane'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Kevin' AND service_provider_surname = 'Martin'
    ) t WHERE rn = 7
);

UPDATE service_provider SET service_provider_name = 'Mandla', service_provider_surname = 'Mabena'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Kevin' AND service_provider_surname = 'Martin'
    ) t WHERE rn = 8
);

UPDATE service_provider SET service_provider_name = 'Sipho', service_provider_surname = 'Mthembu'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Kevin' AND service_provider_surname = 'Martin'
    ) t WHERE rn = 9
);

UPDATE service_provider SET service_provider_name = 'Nomsa', service_provider_surname = 'Nkosi'
WHERE service_provider_id IN (
    SELECT service_provider_id FROM (
        SELECT service_provider_id, ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as rn
        FROM service_provider WHERE service_provider_name = 'Kevin' AND service_provider_surname = 'Martin'
    ) t WHERE rn = 10
);

-- Final verification - check for any remaining duplicates
SELECT 
    service_provider_name,
    service_provider_surname,
    COUNT(*) as count
FROM service_provider 
GROUP BY service_provider_name, service_provider_surname
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- Show some examples of the renamed service providers
SELECT 
    service_provider_name,
    service_provider_surname,
    service_provider_email,
    service_provider_service_type
FROM service_provider 
WHERE service_provider_name IN ('Mandla', 'Sipho', 'Nomsa', 'Lerato', 'Thabo', 'Mpho', 'Kagiso', 'Refilwe', 'Boitumelo', 'Thandiwe', 'Sibusiso', 'Ntombi', 'Khaya', 'Puleng', 'Vusi', 'Tshepo', 'Bongani', 'Zanele')
ORDER BY service_provider_name, service_provider_surname
LIMIT 20;
