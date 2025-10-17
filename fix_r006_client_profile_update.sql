-- fix_r006_client_profile_update.sql
-- R006: Implement client profile update function and database update API

-- =====================================================
-- 1. Create RPC function for client profile update
-- =====================================================
CREATE OR REPLACE FUNCTION public.update_client_profile(
    p_client_id uuid,
    p_client_name text DEFAULT NULL,
    p_client_surname text DEFAULT NULL,
    p_client_email text DEFAULT NULL,
    p_client_contact text DEFAULT NULL,
    p_client_city text DEFAULT NULL,
    p_client_town text DEFAULT NULL,
    p_client_street_name text DEFAULT NULL,
    p_client_house_number text DEFAULT NULL,
    p_client_postal_code text DEFAULT NULL,
    p_client_province text DEFAULT NULL,
    p_client_preferred_notification text DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_existing_client RECORD;
    v_updated_fields jsonb := '{}';
    v_update_query text := 'UPDATE public.client SET ';
    v_has_changes boolean := false;
BEGIN
    -- Check if client exists
    IF NOT EXISTS (SELECT 1 FROM public.client WHERE client_id = p_client_id) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Client not found.');
    END IF;

    -- Get current client data for comparison
    SELECT * INTO v_existing_client FROM public.client WHERE client_id = p_client_id;

    -- Check if email is being changed and if new email already exists
    IF p_client_email IS NOT NULL AND p_client_email != v_existing_client.client_email THEN
        IF EXISTS (SELECT 1 FROM public.client WHERE client_email = p_client_email AND client_id != p_client_id) THEN
            RETURN jsonb_build_object('success', FALSE, 'error', 'Email address already exists. Please use a different email.');
        END IF;
    END IF;

    -- Check if contact is being changed and if new contact already exists
    IF p_client_contact IS NOT NULL AND p_client_contact != v_existing_client.client_contact THEN
        IF EXISTS (SELECT 1 FROM public.client WHERE client_contact = p_client_contact AND client_id != p_client_id) THEN
            RETURN jsonb_build_object('success', FALSE, 'error', 'Contact number already exists. Please use a different contact number.');
        END IF;
    END IF;

    -- Build dynamic update query based on provided fields
    IF p_client_name IS NOT NULL AND p_client_name != v_existing_client.client_name THEN
        v_update_query := v_update_query || 'client_name = $1, ';
        v_updated_fields := v_updated_fields || jsonb_build_object('client_name', p_client_name);
        v_has_changes := true;
    END IF;

    IF p_client_surname IS NOT NULL AND p_client_surname != v_existing_client.client_surname THEN
        v_update_query := v_update_query || 'client_surname = $2, ';
        v_updated_fields := v_updated_fields || jsonb_build_object('client_surname', p_client_surname);
        v_has_changes := true;
    END IF;

    IF p_client_email IS NOT NULL AND p_client_email != v_existing_client.client_email THEN
        v_update_query := v_update_query || 'client_email = $3, ';
        v_updated_fields := v_updated_fields || jsonb_build_object('client_email', p_client_email);
        v_has_changes := true;
    END IF;

    IF p_client_contact IS NOT NULL AND p_client_contact != v_existing_client.client_contact THEN
        v_update_query := v_update_query || 'client_contact = $4, ';
        v_updated_fields := v_updated_fields || jsonb_build_object('client_contact', p_client_contact);
        v_has_changes := true;
    END IF;

    IF p_client_city IS NOT NULL AND p_client_city != v_existing_client.client_city THEN
        v_update_query := v_update_query || 'client_city = $5, ';
        v_updated_fields := v_updated_fields || jsonb_build_object('client_city', p_client_city);
        v_has_changes := true;
    END IF;

    IF p_client_town IS NOT NULL AND p_client_town != v_existing_client.client_town THEN
        v_update_query := v_update_query || 'client_town = $6, ';
        v_updated_fields := v_updated_fields || jsonb_build_object('client_town', p_client_town);
        v_has_changes := true;
    END IF;

    IF p_client_street_name IS NOT NULL AND p_client_street_name != v_existing_client.client_street_name THEN
        v_update_query := v_update_query || 'client_street_name = $7, ';
        v_updated_fields := v_updated_fields || jsonb_build_object('client_street_name', p_client_street_name);
        v_has_changes := true;
    END IF;

    IF p_client_house_number IS NOT NULL AND p_client_house_number != v_existing_client.client_house_number THEN
        v_update_query := v_update_query || 'client_house_number = $8, ';
        v_updated_fields := v_updated_fields || jsonb_build_object('client_house_number', p_client_house_number);
        v_has_changes := true;
    END IF;

    IF p_client_postal_code IS NOT NULL AND p_client_postal_code != v_existing_client.client_postal_code THEN
        v_update_query := v_update_query || 'client_postal_code = $9, ';
        v_updated_fields := v_updated_fields || jsonb_build_object('client_postal_code', p_client_postal_code);
        v_has_changes := true;
    END IF;

    IF p_client_province IS NOT NULL AND p_client_province != v_existing_client.client_province THEN
        v_update_query := v_update_query || 'client_province = $10, ';
        v_updated_fields := v_updated_fields || jsonb_build_object('client_province', p_client_province);
        v_has_changes := true;
    END IF;

    IF p_client_preferred_notification IS NOT NULL AND p_client_preferred_notification != v_existing_client.client_preferred_notification THEN
        v_update_query := v_update_query || 'client_preferred_notification = $11, ';
        v_updated_fields := v_updated_fields || jsonb_build_object('client_preferred_notification', p_client_preferred_notification);
        v_has_changes := true;
    END IF;

    -- If no changes detected
    IF NOT v_has_changes THEN
        RETURN jsonb_build_object('success', TRUE, 'message', 'No changes detected. Profile is up to date.');
    END IF;

    -- Remove trailing comma and add WHERE clause
    v_update_query := rtrim(v_update_query, ', ') || ' WHERE client_id = $12';

    -- Execute the update
    EXECUTE v_update_query 
    USING 
        p_client_name, p_client_surname, p_client_email, p_client_contact,
        p_client_city, p_client_town, p_client_street_name, p_client_house_number,
        p_client_postal_code, p_client_province, p_client_preferred_notification,
        p_client_id;

    -- Get updated client data
    SELECT * INTO v_existing_client FROM public.client WHERE client_id = p_client_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', 'Profile updated successfully.',
        'updated_fields', v_updated_fields,
        'client_data', jsonb_build_object(
            'client_id', v_existing_client.client_id,
            'client_name', v_existing_client.client_name,
            'client_surname', v_existing_client.client_surname,
            'client_email', v_existing_client.client_email,
            'client_contact', v_existing_client.client_contact,
            'client_city', v_existing_client.client_city,
            'client_town', v_existing_client.client_town,
            'client_street_name', v_existing_client.client_street_name,
            'client_house_number', v_existing_client.client_house_number,
            'client_postal_code', v_existing_client.client_postal_code,
            'client_province', v_existing_client.client_province,
            'client_preferred_notification', v_existing_client.client_preferred_notification,
            'created_at', v_existing_client.created_at
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

-- =====================================================
-- 2. Create RPC function for client password update
-- =====================================================
CREATE OR REPLACE FUNCTION public.update_client_password(
    p_client_id uuid,
    p_current_password text,
    p_new_password text
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_current_password_hash text;
    v_new_password_hash text;
BEGIN
    -- Check if client exists
    IF NOT EXISTS (SELECT 1 FROM public.client WHERE client_id = p_client_id) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Client not found.');
    END IF;

    -- Get current password hash
    SELECT client_password INTO v_current_password_hash 
    FROM public.client 
    WHERE client_id = p_client_id;

    -- Verify current password (simple comparison - in production, use proper hashing)
    IF v_current_password_hash != p_current_password THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Current password is incorrect.');
    END IF;

    -- Validate new password (basic validation)
    IF LENGTH(p_new_password) < 8 THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'New password must be at least 8 characters long.');
    END IF;

    -- Update password
    UPDATE public.client
    SET client_password = p_new_password
    WHERE client_id = p_client_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', 'Password updated successfully.'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

-- =====================================================
-- 3. Create RPC function to get client profile data
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_client_profile(p_client_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_client RECORD;
BEGIN
    -- Check if client exists
    IF NOT EXISTS (SELECT 1 FROM public.client WHERE client_id = p_client_id) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Client not found.');
    END IF;

    -- Get client data
    SELECT * INTO v_client FROM public.client WHERE client_id = p_client_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'client_data', jsonb_build_object(
            'client_id', v_client.client_id,
            'client_name', v_client.client_name,
            'client_surname', v_client.client_surname,
            'client_email', v_client.client_email,
            'client_contact', v_client.client_contact,
            'client_city', v_client.client_city,
            'client_town', v_client.client_town,
            'client_street_name', v_client.client_street_name,
            'client_house_number', v_client.client_house_number,
            'client_postal_code', v_client.client_postal_code,
            'client_province', v_client.client_province,
            'client_preferred_notification', v_client.client_preferred_notification,
            'created_at', v_client.created_at
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

-- =====================================================
-- 4. Create RPC function for client profile validation
-- =====================================================
CREATE OR REPLACE FUNCTION public.validate_client_profile_data(
    p_client_name text DEFAULT NULL,
    p_client_surname text DEFAULT NULL,
    p_client_email text DEFAULT NULL,
    p_client_contact text DEFAULT NULL,
    p_client_id uuid DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_errors jsonb := '[]';
    v_error_count integer := 0;
BEGIN
    -- Validate name
    IF p_client_name IS NOT NULL THEN
        IF LENGTH(TRIM(p_client_name)) < 2 THEN
            v_errors := v_errors || jsonb_build_object('field', 'client_name', 'message', 'Name must be at least 2 characters long.');
            v_error_count := v_error_count + 1;
        ELSIF NOT p_client_name ~ '^[a-zA-Z\s\-\.]+$' THEN
            v_errors := v_errors || jsonb_build_object('field', 'client_name', 'message', 'Name can only contain letters, spaces, hyphens, and periods.');
            v_error_count := v_error_count + 1;
        END IF;
    END IF;

    -- Validate surname
    IF p_client_surname IS NOT NULL THEN
        IF LENGTH(TRIM(p_client_surname)) < 2 THEN
            v_errors := v_errors || jsonb_build_object('field', 'client_surname', 'message', 'Surname must be at least 2 characters long.');
            v_error_count := v_error_count + 1;
        ELSIF NOT p_client_surname ~ '^[a-zA-Z\s\-\.]+$' THEN
            v_errors := v_errors || jsonb_build_object('field', 'client_surname', 'message', 'Surname can only contain letters, spaces, hyphens, and periods.');
            v_error_count := v_error_count + 1;
        END IF;
    END IF;

    -- Validate email
    IF p_client_email IS NOT NULL THEN
        IF NOT p_client_email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
            v_errors := v_errors || jsonb_build_object('field', 'client_email', 'message', 'Please enter a valid email address.');
            v_error_count := v_error_count + 1;
        ELSE
            -- Check if email already exists (excluding current client)
            IF EXISTS (
                SELECT 1 FROM public.client 
                WHERE client_email = p_client_email 
                AND (p_client_id IS NULL OR client_id != p_client_id)
            ) THEN
                v_errors := v_errors || jsonb_build_object('field', 'client_email', 'message', 'This email address is already registered.');
                v_error_count := v_error_count + 1;
            END IF;
        END IF;
    END IF;

    -- Validate contact number
    IF p_client_contact IS NOT NULL THEN
        -- Remove any non-digit characters for validation
        DECLARE
            v_clean_contact text := regexp_replace(p_client_contact, '[^0-9]', '', 'g');
        BEGIN
            IF LENGTH(v_clean_contact) != 10 THEN
                v_errors := v_errors || jsonb_build_object('field', 'client_contact', 'message', 'Contact number must be 10 digits.');
                v_error_count := v_error_count + 1;
            ELSIF NOT v_clean_contact ~ '^0[0-9]{9}$' THEN
                v_errors := v_errors || jsonb_build_object('field', 'client_contact', 'message', 'Contact number must start with 0 and be 10 digits.');
                v_error_count := v_error_count + 1;
            ELSE
                -- Check if contact already exists (excluding current client)
                IF EXISTS (
                    SELECT 1 FROM public.client 
                    WHERE client_contact = p_client_contact 
                    AND (p_client_id IS NULL OR client_id != p_client_id)
                ) THEN
                    v_errors := v_errors || jsonb_build_object('field', 'client_contact', 'message', 'This contact number is already registered.');
                    v_error_count := v_error_count + 1;
                END IF;
            END IF;
        END;
    END IF;

    -- Return validation result
    IF v_error_count = 0 THEN
        RETURN jsonb_build_object('success', TRUE, 'message', 'Validation passed.');
    ELSE
        RETURN jsonb_build_object(
            'success', FALSE,
            'error_count', v_error_count,
            'errors', v_errors,
            'message', 'Validation failed. Please check the errors.'
        );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

-- =====================================================
-- 5. Set up RLS policies for client profile updates
-- =====================================================

-- Policy for clients to view their own profile
DROP POLICY IF EXISTS "Clients can view their own profile." ON public.client;
CREATE POLICY "Clients can view their own profile."
ON public.client FOR SELECT
TO authenticated
USING (client_id = auth.uid());

-- Policy for clients to update their own profile
DROP POLICY IF EXISTS "Clients can update their own profile." ON public.client;
CREATE POLICY "Clients can update their own profile."
ON public.client FOR UPDATE
TO authenticated
USING (client_id = auth.uid())
WITH CHECK (client_id = auth.uid());

-- =====================================================
-- 6. Verification queries
-- =====================================================

-- Check that RPC functions exist
SELECT 
    'Client Profile RPC Functions' as status,
    COUNT(*) as function_count
FROM pg_proc 
WHERE proname IN ('update_client_profile', 'update_client_password', 'get_client_profile', 'validate_client_profile_data')
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- Check RLS policies
SELECT 
    'Client RLS Policies' as status,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'client' 
AND schemaname = 'public';

-- Test function exists (sample test)
SELECT 
    'Sample client count' as status,
    COUNT(*) as client_count
FROM public.client;





