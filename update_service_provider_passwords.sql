-- Update service provider passwords with 20+ different real passwords
-- This script will assign different secure passwords to each service provider

-- First, let's see current password situation
SELECT 
    service_provider_password,
    COUNT(*) as count
FROM service_provider 
GROUP BY service_provider_password
ORDER BY count DESC;

-- Create a list of 20+ different secure passwords
WITH password_list AS (
    SELECT 
        service_provider_id,
        service_provider_name,
        service_provider_surname,
        ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as row_num
    FROM service_provider
),
password_assignments AS (
    SELECT 
        service_provider_id,
        service_provider_name,
        service_provider_surname,
        row_num,
        CASE 
            WHEN row_num % 20 = 1 THEN 'SecurePass2024!'
            WHEN row_num % 20 = 2 THEN 'MyEventBiz@2024'
            WHEN row_num % 20 = 3 THEN 'ServicePro#2024'
            WHEN row_num % 20 = 4 THEN 'EventManager$2024'
            WHEN row_num % 20 = 5 THEN 'BonicaEvents!2024'
            WHEN row_num % 20 = 6 THEN 'ProviderPass@2024'
            WHEN row_num % 20 = 7 THEN 'EventService#2024'
            WHEN row_num % 20 = 8 THEN 'SecureLogin$2024'
            WHEN row_num % 20 = 9 THEN 'EventPro!2024'
            WHEN row_num % 20 = 10 THEN 'ServiceLogin@2024'
            WHEN row_num % 20 = 11 THEN 'BonicaPro#2024'
            WHEN row_num % 20 = 12 THEN 'EventProvider$2024'
            WHEN row_num % 20 = 13 THEN 'SecureEvent!2024'
            WHEN row_num % 20 = 14 THEN 'MyService@2024'
            WHEN row_num % 20 = 15 THEN 'EventBiz#2024'
            WHEN row_num % 20 = 16 THEN 'ProviderLogin$2024'
            WHEN row_num % 20 = 17 THEN 'ServicePro!2024'
            WHEN row_num % 20 = 18 THEN 'EventManager@2024'
            WHEN row_num % 20 = 19 THEN 'BonicaLogin#2024'
            WHEN row_num % 20 = 0 THEN 'SecureProvider$2024'
        END as new_password
    FROM password_list
)
-- Show what passwords will be assigned
SELECT 
    service_provider_name,
    service_provider_surname,
    new_password,
    row_num
FROM password_assignments
ORDER BY row_num
LIMIT 30;

-- Update passwords using a simpler approach
WITH numbered_providers AS (
    SELECT 
        service_provider_id,
        ROW_NUMBER() OVER (ORDER BY created_at, service_provider_id) as row_num
    FROM service_provider
)
UPDATE service_provider 
SET service_provider_password = CASE 
    WHEN np.row_num % 20 = 1 THEN 'SecurePass2024!'
    WHEN np.row_num % 20 = 2 THEN 'MyEventBiz@2024'
    WHEN np.row_num % 20 = 3 THEN 'ServicePro#2024'
    WHEN np.row_num % 20 = 4 THEN 'EventManager$2024'
    WHEN np.row_num % 20 = 5 THEN 'BonicaEvents!2024'
    WHEN np.row_num % 20 = 6 THEN 'ProviderPass@2024'
    WHEN np.row_num % 20 = 7 THEN 'EventService#2024'
    WHEN np.row_num % 20 = 8 THEN 'SecureLogin$2024'
    WHEN np.row_num % 20 = 9 THEN 'EventPro!2024'
    WHEN np.row_num % 20 = 10 THEN 'ServiceLogin@2024'
    WHEN np.row_num % 20 = 11 THEN 'BonicaPro#2024'
    WHEN np.row_num % 20 = 12 THEN 'EventProvider$2024'
    WHEN np.row_num % 20 = 13 THEN 'SecureEvent!2024'
    WHEN np.row_num % 20 = 14 THEN 'MyService@2024'
    WHEN np.row_num % 20 = 15 THEN 'EventBiz#2024'
    WHEN np.row_num % 20 = 16 THEN 'ProviderLogin$2024'
    WHEN np.row_num % 20 = 17 THEN 'ServicePro!2024'
    WHEN np.row_num % 20 = 18 THEN 'EventManager@2024'
    WHEN np.row_num % 20 = 19 THEN 'BonicaLogin#2024'
    WHEN np.row_num % 20 = 0 THEN 'SecureProvider$2024'
END
FROM numbered_providers np
WHERE service_provider.service_provider_id = np.service_provider_id;

-- Verify password distribution
SELECT 
    service_provider_password,
    COUNT(*) as count
FROM service_provider 
GROUP BY service_provider_password
ORDER BY count DESC;

-- Show some examples of updated passwords
SELECT 
    service_provider_name,
    service_provider_surname,
    service_provider_password
FROM service_provider 
ORDER BY created_at
LIMIT 25;
