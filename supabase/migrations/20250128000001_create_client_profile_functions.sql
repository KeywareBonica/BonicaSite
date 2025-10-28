-- Client Profile Management Functions
-- Creates RPC functions for client profile operations

-- =====================================================
-- 1. Create get_client_profile function
-- =====================================================
CREATE OR REPLACE FUNCTION get_client_profile(p_client_id uuid)
RETURNS json AS $$
DECLARE
    client_data json;
BEGIN
    -- Get client data
    SELECT json_build_object(
        'client_id', client_id,
        'client_name', client_name,
        'client_surname', client_surname,
        'client_email', client_email,
        'client_contact', client_contact,
        'client_city', client_city,
        'client_town', client_town,
        'client_street_name', client_street_name,
        'client_house_number', client_house_number,
        'client_postal_code', client_postal_code,
        'client_preferred_notification', client_preferred_notification,
        'created_at', created_at
    ) INTO client_data
    FROM client
    WHERE client_id = p_client_id;
    
    IF client_data IS NULL THEN
        RETURN json_build_object('error', 'Client not found');
    END IF;
    
    RETURN json_build_object('client_data', client_data);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 2. Create update_client_profile function
-- =====================================================
CREATE OR REPLACE FUNCTION update_client_profile(
    p_client_id uuid,
    p_client_name text,
    p_client_surname text,
    p_client_email text,
    p_client_contact text,
    p_client_city text DEFAULT NULL,
    p_client_town text DEFAULT NULL,
    p_client_street_name text DEFAULT NULL,
    p_client_house_number text DEFAULT NULL,
    p_client_postal_code text DEFAULT NULL,
    p_client_province text DEFAULT NULL,
    p_client_preferred_notification text DEFAULT 'email'
)
RETURNS json AS $$
DECLARE
    updated_client client%ROWTYPE;
BEGIN
    -- Validate required fields
    IF p_client_name IS NULL OR trim(p_client_name) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Client name is required');
    END IF;
    
    IF p_client_surname IS NULL OR trim(p_client_surname) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Client surname is required');
    END IF;
    
    IF p_client_email IS NULL OR trim(p_client_email) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Client email is required');
    END IF;
    
    IF p_client_contact IS NULL OR trim(p_client_contact) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Client contact is required');
    END IF;
    
    -- Validate email format
    IF p_client_email !~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
        RETURN json_build_object('success', false, 'error', 'Invalid email format');
    END IF;
    
    -- Validate contact number (10 digits starting with 0)
    IF p_client_contact !~ '^0[0-9]{9}$' THEN
        RETURN json_build_object('success', false, 'error', 'Contact number must be 10 digits starting with 0');
    END IF;
    
    -- Check if email is already taken by another client
    IF EXISTS (
        SELECT 1 FROM client 
        WHERE client_email = p_client_email 
        AND client_id != p_client_id
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Email address is already in use');
    END IF;
    
    -- Update client profile
    UPDATE client SET
        client_name = trim(p_client_name),
        client_surname = trim(p_client_surname),
        client_email = trim(p_client_email),
        client_contact = trim(p_client_contact),
        client_city = CASE WHEN p_client_city IS NOT NULL THEN trim(p_client_city) ELSE client_city END,
        client_town = CASE WHEN p_client_town IS NOT NULL THEN trim(p_client_town) ELSE client_town END,
        client_street_name = CASE WHEN p_client_street_name IS NOT NULL THEN trim(p_client_street_name) ELSE client_street_name END,
        client_house_number = CASE WHEN p_client_house_number IS NOT NULL THEN trim(p_client_house_number) ELSE client_house_number END,
        client_postal_code = CASE WHEN p_client_postal_code IS NOT NULL THEN trim(p_client_postal_code) ELSE client_postal_code END,
        client_preferred_notification = COALESCE(p_client_preferred_notification, client_preferred_notification, 'email')
    WHERE client_id = p_client_id;
    
    -- Check if update was successful
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Client not found');
    END IF;
    
    -- Get updated client data
    SELECT * INTO updated_client FROM client WHERE client_id = p_client_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Profile updated successfully',
        'client_data', json_build_object(
            'client_id', updated_client.client_id,
            'client_name', updated_client.client_name,
            'client_surname', updated_client.client_surname,
            'client_email', updated_client.client_email,
            'client_contact', updated_client.client_contact,
            'client_city', updated_client.client_city,
            'client_town', updated_client.client_town,
            'client_street_name', updated_client.client_street_name,
            'client_house_number', updated_client.client_house_number,
            'client_postal_code', updated_client.client_postal_code,
            'client_preferred_notification', updated_client.client_preferred_notification,
            'created_at', updated_client.created_at
        )
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 3. Create update_client_password function
-- =====================================================
CREATE OR REPLACE FUNCTION update_client_password(
    p_client_id uuid,
    p_current_password text,
    p_new_password text
)
RETURNS json AS $$
DECLARE
    current_hash text;
    new_hash text;
BEGIN
    -- Validate inputs
    IF p_current_password IS NULL OR trim(p_current_password) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Current password is required');
    END IF;
    
    IF p_new_password IS NULL OR trim(p_new_password) = '' THEN
        RETURN json_build_object('success', false, 'error', 'New password is required');
    END IF;
    
    IF length(p_new_password) < 8 THEN
        RETURN json_build_object('success', false, 'error', 'New password must be at least 8 characters long');
    END IF;
    
    -- Get current password hash
    SELECT client_password INTO current_hash
    FROM client
    WHERE client_id = p_client_id;
    
    IF current_hash IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Client not found');
    END IF;
    
    -- Verify current password (assuming passwords are stored as plain text for now)
    -- In production, you should use proper password hashing
    IF current_hash != p_current_password THEN
        RETURN json_build_object('success', false, 'error', 'Current password is incorrect');
    END IF;
    
    -- Update password
    UPDATE client 
    SET client_password = p_new_password
    WHERE client_id = p_client_id;
    
    RETURN json_build_object('success', true, 'message', 'Password updated successfully');
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 4. Grant permissions
-- =====================================================
GRANT EXECUTE ON FUNCTION get_client_profile(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION update_client_profile(uuid, text, text, text, text, text, text, text, text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_client_password(uuid, text, text) TO authenticated;

-- =====================================================
-- 5. Add RLS policies for client table
-- =====================================================
ALTER TABLE client ENABLE ROW LEVEL SECURITY;

-- Policy for clients to view their own data
DROP POLICY IF EXISTS "Clients can view their own data" ON client;
CREATE POLICY "Clients can view their own data" ON client
    FOR SELECT USING (client_id = (SELECT client_id FROM client WHERE client_email = current_setting('request.jwt.claims', true)::json->>'email'));

-- Policy for clients to update their own data
DROP POLICY IF EXISTS "Clients can update their own data" ON client;
CREATE POLICY "Clients can update their own data" ON client
    FOR UPDATE USING (client_id = (SELECT client_id FROM client WHERE client_email = current_setting('request.jwt.claims', true)::json->>'email'));

-- Policy for clients to insert their own data (for registration)
DROP POLICY IF EXISTS "Clients can insert their own data" ON client;
CREATE POLICY "Clients can insert their own data" ON client
    FOR INSERT WITH CHECK (true); -- Allow registration

COMMENT ON FUNCTION get_client_profile(uuid) IS 'Retrieves client profile data by client ID';
COMMENT ON FUNCTION update_client_profile(uuid, text, text, text, text, text, text, text, text, text, text, text) IS 'Updates client profile information';
COMMENT ON FUNCTION update_client_password(uuid, text, text) IS 'Updates client password with validation';











