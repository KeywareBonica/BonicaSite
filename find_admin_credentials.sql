-- find_admin_credentials.sql
-- Find service providers who can act as admins

-- =====================================================
-- 1. Check all service providers and their types
-- =====================================================
SELECT 
    'All Service Providers:' as info;

SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_email,
    service_provider_service_type,
    service_provider_verification
FROM public.service_provider
ORDER BY service_provider_service_type, service_provider_name;

-- =====================================================
-- 2. Check for any admin-type service providers
-- =====================================================
SELECT 
    'Admin Service Providers:' as info;

SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_email,
    service_provider_service_type
FROM public.service_provider
WHERE LOWER(service_provider_service_type) LIKE '%admin%'
   OR service_provider_service_type = 'Admin'
   OR service_provider_service_type = 'admin'
ORDER BY service_provider_name;

-- =====================================================
-- 3. Check service provider login credentials
-- =====================================================
SELECT 
    'Service Provider Login Info:' as info;

SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_email,
    service_provider_password,
    service_provider_service_type
FROM public.service_provider
LIMIT 10;

-- =====================================================
-- 4. Check if there are any verified service providers (potential admins)
-- =====================================================
SELECT 
    'Verified Service Providers:' as info;

SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_surname,
    service_provider_email,
    service_provider_service_type,
    service_provider_verification
FROM public.service_provider
WHERE service_provider_verification = true
ORDER BY service_provider_name;





