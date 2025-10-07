-- Test script to verify password hashing in the database
-- This will help us understand what's actually being stored

-- 1. Check the current password field definition
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'client' 
AND column_name = 'client_password';

-- 2. Check if there are any constraints on the password field
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'client' 
AND kcu.column_name = 'client_password';

-- 3. Check recent client registrations and their password formats
SELECT 
    client_id,
    client_name,
    client_email,
    client_password,
    LENGTH(client_password) as password_length,
    CASE 
        WHEN client_password ~ '^[a-f0-9]{64}$' THEN 'Valid SHA-256 Hash'
        WHEN client_password ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 'UUID Format'
        WHEN LENGTH(client_password) < 20 THEN 'Short (Possibly Plain Text)'
        ELSE 'Other Format'
    END as password_type,
    created_at
FROM client 
ORDER BY created_at DESC 
LIMIT 10;

-- 4. Check service provider passwords too
SELECT 
    service_provider_id,
    service_provider_name,
    service_provider_email,
    service_provider_password,
    LENGTH(service_provider_password) as password_length,
    CASE 
        WHEN service_provider_password ~ '^[a-f0-9]{64}$' THEN 'Valid SHA-256 Hash'
        WHEN service_provider_password ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN 'UUID Format'
        WHEN LENGTH(service_provider_password) < 20 THEN 'Short (Possibly Plain Text)'
        ELSE 'Other Format'
    END as password_type,
    created_at
FROM service_provider 
ORDER BY created_at DESC 
LIMIT 10;

-- 5. Test the encryption function with a known password
-- Note: This will test the JavaScript hashing function
-- The hash for 'D!neo345' should be: 500075cdb58dd8ff2f410baed74f0eacc47c43a5c7dd7ea60f9297d224e1cf9e
SELECT 'D!neo345' as test_password, 
       '500075cdb58dd8ff2f410baed74f0eacc47c43a5c7dd7ea60f9297d224e1cf9e' as expected_hash,
       LENGTH('500075cdb58dd8ff2f410baed74f0eacc47c43a5c7dd7ea60f9297d224e1cf9e') as hash_length;
