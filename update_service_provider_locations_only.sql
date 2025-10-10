-- ===============================================
-- Simple Update: Change Service Provider Locations Only
-- ===============================================

-- Update service provider locations to specific areas
UPDATE service_provider 
SET service_provider_location = CASE 
    WHEN RANDOM() < 0.25 THEN 'Sandton'
    WHEN RANDOM() < 0.5 THEN 'Rosebank'
    WHEN RANDOM() < 0.75 THEN 'Soweto'
    ELSE 'Johannesburg'
END;

-- Verification: Show updated locations
SELECT 
    'Service Provider Locations Updated' AS info,
    service_provider_location,
    COUNT(*) AS count
FROM service_provider 
WHERE service_provider_location IN ('Sandton', 'Rosebank', 'Soweto', 'Johannesburg')
GROUP BY service_provider_location
ORDER BY service_provider_location;

-- Show sample quotations with new locations
SELECT 
    'Sample Quotations with New Locations' AS info,
    q.quotation_id,
    s.service_name,
    sp.service_provider_name || ' ' || sp.service_provider_surname AS provider_name,
    sp.service_provider_location,
    q.quotation_price,
    q.quotation_status
FROM quotation q
JOIN service s ON q.service_id = s.service_id
JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
WHERE q.quotation_submission_date = '2025-10-10'
AND q.quotation_status = 'confirmed'
ORDER BY s.service_name, q.quotation_price
LIMIT 10;
