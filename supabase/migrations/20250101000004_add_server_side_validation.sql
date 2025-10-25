-- Server-side validation functions and triggers
-- This provides backup validation at the database level to prevent invalid data storage

-- Create validation functions
CREATE OR REPLACE FUNCTION validate_name(input_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if name is not null and not empty
    IF input_name IS NULL OR TRIM(input_name) = '' THEN
        RETURN FALSE;
    END IF;
    
    -- Check if name contains only letters and spaces
    IF NOT input_name ~ '^[a-zA-Z\s]+$' THEN
        RETURN FALSE;
    END IF;
    
    -- Check if name contains numbers
    IF input_name ~ '\d' THEN
        RETURN FALSE;
    END IF;
    
    -- Check if name contains special characters (excluding spaces)
    IF input_name ~ '[^a-zA-Z\s]' THEN
        RETURN FALSE;
    END IF;
    
    -- Check length (2-50 characters)
    IF LENGTH(TRIM(input_name)) < 2 OR LENGTH(TRIM(input_name)) > 50 THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_email(input_email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if email is not null and not empty
    IF input_email IS NULL OR TRIM(input_email) = '' THEN
        RETURN FALSE;
    END IF;
    
    -- Convert to lowercase for validation
    input_email := LOWER(TRIM(input_email));
    
    -- Check basic email format
    IF NOT input_email ~ '^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
        RETURN FALSE;
    END IF;
    
    -- Check for @ symbol
    IF NOT input_email LIKE '%@%' THEN
        RETURN FALSE;
    END IF;
    
    -- Check domain format
    IF NOT input_email LIKE '%@%.%' THEN
        RETURN FALSE;
    END IF;
    
    -- Check TLD length (must be at least 2 characters)
    IF LENGTH(SPLIT_PART(SPLIT_PART(input_email, '@', 2), '.', -1)) < 2 THEN
        RETURN FALSE;
    END IF;
    
    -- Check for valid domain extensions
    IF NOT (
        input_email LIKE '%.com' OR 
        input_email LIKE '%.org' OR 
        input_email LIKE '%.net' OR 
        input_email LIKE '%.co.za' OR 
        input_email LIKE '%.co' OR 
        input_email LIKE '%.za' OR 
        input_email LIKE '%.gov.za' OR 
        input_email LIKE '%.ac.za'
    ) THEN
        RETURN FALSE;
    END IF;
    
    -- Check for invalid characters
    IF input_email ~ '[^a-zA-Z0-9._@-]' THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_phone(input_phone TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if phone is not null and not empty
    IF input_phone IS NULL OR TRIM(input_phone) = '' THEN
        RETURN FALSE;
    END IF;
    
    -- Remove non-digit characters
    input_phone := REGEXP_REPLACE(input_phone, '[^0-9]', '', 'g');
    
    -- Check if it's exactly 10 digits starting with 0
    IF NOT input_phone ~ '^0[0-9]{9}$' THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_password(input_password TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if password is not null and not empty
    IF input_password IS NULL OR input_password = '' THEN
        RETURN FALSE;
    END IF;
    
    -- Check minimum length (8 characters)
    IF LENGTH(input_password) < 8 THEN
        RETURN FALSE;
    END IF;
    
    -- Check for uppercase letter
    IF NOT input_password ~ '[A-Z]' THEN
        RETURN FALSE;
    END IF;
    
    -- Check for lowercase letter
    IF NOT input_password ~ '[a-z]' THEN
        RETURN FALSE;
    END IF;
    
    -- Check for numbers
    IF NOT input_password ~ '\d' THEN
        RETURN FALSE;
    END IF;
    
    -- Check for special characters
    IF NOT input_password ~ '[!@#$%^&*(),.?":{}|<>]' THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_text_field(input_text TEXT, max_length INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if text is not null and not empty
    IF input_text IS NULL OR TRIM(input_text) = '' THEN
        RETURN FALSE;
    END IF;
    
    -- Check length
    IF LENGTH(TRIM(input_text)) > max_length THEN
        RETURN FALSE;
    END IF;
    
    -- Check for invalid characters (allow letters, spaces, hyphens, en-dashes, em-dashes)
    IF input_text ~ '[#@$%^&*()_+=\[\]{};'':"\\|,.<>\/?~`0-9]' THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Create validation functions for address fields
CREATE OR REPLACE FUNCTION validate_address_field(input_text TEXT, field_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if text is not null and not empty
    IF input_text IS NULL OR TRIM(input_text) = '' THEN
        RETURN FALSE;
    END IF;
    
    -- Check length (reasonable limit for address fields)
    IF LENGTH(TRIM(input_text)) > 100 THEN
        RETURN FALSE;
    END IF;
    
    -- Check for invalid characters (allow letters, spaces, hyphens, en-dashes, em-dashes)
    IF input_text ~ '[#@$%^&*()_+=\[\]{};'':"\\|,.<>\/?~`0-9]' THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_house_number(input_text TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if text is not null and not empty
    IF input_text IS NULL OR TRIM(input_text) = '' THEN
        RETURN FALSE;
    END IF;
    
    -- Check length
    IF LENGTH(TRIM(input_text)) > 20 THEN
        RETURN FALSE;
    END IF;
    
    -- Allow letters, numbers, spaces, hyphens, and forward slashes for house numbers
    -- Examples: "123", "45A", "12-14", "123/125"
    IF NOT input_text ~ '^[a-zA-Z0-9\s\-\/]+$' THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_postal_code(input_text TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if text is not null and not empty
    IF input_text IS NULL OR TRIM(input_text) = '' THEN
        RETURN FALSE;
    END IF;
    
    -- Check length (typical postal code length)
    IF LENGTH(TRIM(input_text)) < 3 OR LENGTH(TRIM(input_text)) > 10 THEN
        RETURN FALSE;
    END IF;
    
    -- Allow letters and numbers for postal codes
    -- Examples: "1234", "ABC123", "1234AB"
    IF NOT input_text ~ '^[a-zA-Z0-9]+$' THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_custom_service_name(input_text TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if text is not null and not empty
    IF input_text IS NULL OR TRIM(input_text) = '' THEN
        RETURN FALSE;
    END IF;
    
    -- Check length
    IF LENGTH(TRIM(input_text)) > 50 THEN
        RETURN FALSE;
    END IF;
    
    -- Check for invalid characters (allow letters, spaces, hyphens, en-dashes, em-dashes)
    IF input_text ~ '[#@$%^&*()_+=\[\]{};'':"\\|,.<>\/?~`0-9]' THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Create validation triggers for client table
CREATE OR REPLACE FUNCTION validate_client_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate client name
    IF NOT validate_name(NEW.client_name) THEN
        RAISE EXCEPTION 'Invalid client name: Name must contain only letters and spaces (2-50 characters), no numbers or special characters allowed';
    END IF;
    
    -- Validate client surname
    IF NOT validate_name(NEW.client_surname) THEN
        RAISE EXCEPTION 'Invalid client surname: Surname must contain only letters and spaces (2-50 characters), no numbers or special characters allowed';
    END IF;
    
    -- Validate client email
    IF NOT validate_email(NEW.client_email) THEN
        RAISE EXCEPTION 'Invalid client email: Email must have a valid domain with extension (.com, .co.za, .org, etc.)';
    END IF;
    
    -- Validate client phone
    IF NOT validate_phone(NEW.client_contact) THEN
        RAISE EXCEPTION 'Invalid client phone: Phone number must be 10 digits starting with 0 (format: 0XXXXXXXXX)';
    END IF;
    
    -- Validate client password (only if it's not already hashed)
    IF NEW.client_password IS NOT NULL AND LENGTH(NEW.client_password) < 60 THEN
        IF NOT validate_password(NEW.client_password) THEN
            RAISE EXCEPTION 'Invalid client password: Password must be at least 8 characters with uppercase, lowercase, numbers, and special characters';
        END IF;
    END IF;
    
    -- Validate address fields
    IF NEW.client_province IS NOT NULL AND NEW.client_province != '' THEN
        IF NOT validate_address_field(NEW.client_province, 'Province') THEN
            RAISE EXCEPTION 'Invalid client province: Province must contain only letters, spaces, and hyphens (max 100 characters), no numbers or special characters allowed';
        END IF;
    END IF;
    
    IF NEW.client_city IS NOT NULL AND NEW.client_city != '' THEN
        IF NOT validate_address_field(NEW.client_city, 'City') THEN
            RAISE EXCEPTION 'Invalid client city: City must contain only letters, spaces, and hyphens (max 100 characters), no numbers or special characters allowed';
        END IF;
    END IF;
    
    IF NEW.client_town IS NOT NULL AND NEW.client_town != '' THEN
        IF NOT validate_address_field(NEW.client_town, 'Town') THEN
            RAISE EXCEPTION 'Invalid client town: Town must contain only letters, spaces, and hyphens (max 100 characters), no numbers or special characters allowed';
        END IF;
    END IF;
    
    IF NEW.client_street_name IS NOT NULL AND NEW.client_street_name != '' THEN
        IF NOT validate_address_field(NEW.client_street_name, 'Street Name') THEN
            RAISE EXCEPTION 'Invalid client street name: Street name must contain only letters, spaces, and hyphens (max 100 characters), no numbers or special characters allowed';
        END IF;
    END IF;
    
    IF NEW.client_house_number IS NOT NULL AND NEW.client_house_number != '' THEN
        IF NOT validate_house_number(NEW.client_house_number) THEN
            RAISE EXCEPTION 'Invalid client house number: House number can only contain letters, numbers, spaces, hyphens, and forward slashes (max 20 characters)';
        END IF;
    END IF;
    
    IF NEW.client_postal_code IS NOT NULL AND NEW.client_postal_code != '' THEN
        IF NOT validate_postal_code(NEW.client_postal_code) THEN
            RAISE EXCEPTION 'Invalid client postal code: Postal code can only contain letters and numbers (3-10 characters)';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create validation triggers for quotation table
CREATE OR REPLACE FUNCTION validate_quotation_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate quotation price
    IF NEW.quotation_price IS NOT NULL THEN
        IF NOT validate_numeric_field(NEW.quotation_price, 1, 999999) THEN
            RAISE EXCEPTION 'Invalid quotation price: Price must be between R1 and R999,999';
        END IF;
    END IF;
    
    -- Validate quotation details
    IF NEW.quotation_details IS NOT NULL AND NEW.quotation_details != '' THEN
        IF NOT validate_text_field(NEW.quotation_details, 1000) THEN
            RAISE EXCEPTION 'Invalid quotation details: Details must contain only letters, spaces, and hyphens (max 1000 characters), no numbers or special characters allowed';
        END IF;
    END IF;
    
    -- Validate quotation file name
    IF NEW.quotation_file_name IS NOT NULL AND NEW.quotation_file_name != '' THEN
        IF LENGTH(NEW.quotation_file_name) > 255 THEN
            RAISE EXCEPTION 'Invalid quotation file name: File name is too long (max 255 characters)';
        END IF;
        
        IF NEW.quotation_file_name ~ '[<>:"/\\|?*]' THEN
            RAISE EXCEPTION 'Invalid quotation file name: File name contains invalid characters';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create validation triggers for service_provider table
CREATE OR REPLACE FUNCTION validate_service_provider_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate service provider name
    IF NOT validate_name(NEW.service_provider_name) THEN
        RAISE EXCEPTION 'Invalid service provider name: Name must contain only letters and spaces (2-50 characters), no numbers or special characters allowed';
    END IF;
    
    -- Validate service provider surname
    IF NOT validate_name(NEW.service_provider_surname) THEN
        RAISE EXCEPTION 'Invalid service provider surname: Surname must contain only letters and spaces (2-50 characters), no numbers or special characters allowed';
    END IF;
    
    -- Validate service provider email
    IF NOT validate_email(NEW.service_provider_email) THEN
        RAISE EXCEPTION 'Invalid service provider email: Email must have a valid domain with extension (.com, .co.za, .org, etc.)';
    END IF;
    
    -- Validate service provider phone
    IF NOT validate_phone(NEW.service_provider_contact) THEN
        RAISE EXCEPTION 'Invalid service provider phone: Phone number must be 10 digits starting with 0 (format: 0XXXXXXXXX)';
    END IF;
    
    -- Validate service provider password (only if it's not already hashed)
    IF NEW.service_provider_password IS NOT NULL AND LENGTH(NEW.service_provider_password) < 60 THEN
        IF NOT validate_password(NEW.service_provider_password) THEN
            RAISE EXCEPTION 'Invalid service provider password: Password must be at least 8 characters with uppercase, lowercase, numbers, and special characters';
        END IF;
    END IF;
    
    -- Validate location field
    IF NEW.service_provider_location IS NOT NULL AND NEW.service_provider_location != '' THEN
        IF NOT validate_address_field(NEW.service_provider_location, 'Location') THEN
            RAISE EXCEPTION 'Invalid service provider location: Location must contain only letters, spaces, and hyphens (max 100 characters), no numbers or special characters allowed';
        END IF;
    END IF;
    
    -- Validate caption
    IF NEW.service_provider_caption IS NOT NULL AND NEW.service_provider_caption != '' THEN
        IF NOT validate_text_field(NEW.service_provider_caption, 100) THEN
            RAISE EXCEPTION 'Invalid service provider caption: Caption must contain only letters, spaces, and hyphens (max 100 characters), no numbers or special characters allowed';
        END IF;
    END IF;
    
    -- Validate description
    IF NEW.service_provider_description IS NOT NULL AND NEW.service_provider_description != '' THEN
        IF NOT validate_text_field(NEW.service_provider_description, 500) THEN
            RAISE EXCEPTION 'Invalid service provider description: Description must contain only letters, spaces, and hyphens (max 500 characters), no numbers or special characters allowed';
        END IF;
    END IF;
    
    -- Validate base rate
    IF NEW.service_provider_base_rate IS NOT NULL THEN
        IF NOT validate_numeric_field(NEW.service_provider_base_rate, 1, 999999) THEN
            RAISE EXCEPTION 'Invalid service provider base rate: Rate must be between R1 and R999,999';
        END IF;
    END IF;
    
    -- Validate overtime rate
    IF NEW.service_provider_overtime_rate IS NOT NULL THEN
        IF NOT validate_numeric_field(NEW.service_provider_overtime_rate, 1, 999999) THEN
            RAISE EXCEPTION 'Invalid service provider overtime rate: Rate must be between R1 and R999,999';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS validate_client_data_trigger ON client;
CREATE TRIGGER validate_client_data_trigger
    BEFORE INSERT OR UPDATE ON client
    FOR EACH ROW
    EXECUTE FUNCTION validate_client_data();

DROP TRIGGER IF EXISTS validate_service_provider_data_trigger ON service_provider;
CREATE TRIGGER validate_service_provider_data_trigger
    BEFORE INSERT OR UPDATE ON service_provider
    FOR EACH ROW
    EXECUTE FUNCTION validate_service_provider_data();

DROP TRIGGER IF EXISTS validate_quotation_data_trigger ON quotation;
CREATE TRIGGER validate_quotation_data_trigger
    BEFORE INSERT OR UPDATE ON quotation
    FOR EACH ROW
    EXECUTE FUNCTION validate_quotation_data();

-- Create indexes for better performance on validation checks
CREATE INDEX IF NOT EXISTS idx_client_email_lower ON client (LOWER(client_email));
CREATE INDEX IF NOT EXISTS idx_client_contact ON client (client_contact);
CREATE INDEX IF NOT EXISTS idx_service_provider_email_lower ON service_provider (LOWER(service_provider_email));
CREATE INDEX IF NOT EXISTS idx_service_provider_contact ON service_provider (service_provider_contact);

-- Add comments for documentation
COMMENT ON FUNCTION validate_name(TEXT) IS 'Validates that a name contains only letters and spaces, is 2-50 characters long, and contains no numbers or special characters';
COMMENT ON FUNCTION validate_email(TEXT) IS 'Validates that an email has proper format with valid domain extension (.com, .co.za, etc.)';
COMMENT ON FUNCTION validate_phone(TEXT) IS 'Validates South African phone number format (10 digits starting with 0)';
COMMENT ON FUNCTION validate_password(TEXT) IS 'Validates password strength (8+ chars, uppercase, lowercase, numbers, special chars)';
COMMENT ON FUNCTION validate_text_field(TEXT, INTEGER) IS 'Validates text fields contain only letters, spaces, and hyphens within specified length';
COMMENT ON FUNCTION validate_numeric_field(NUMERIC, NUMERIC, NUMERIC) IS 'Validates numeric fields are within specified range';
COMMENT ON FUNCTION validate_client_data() IS 'Trigger function to validate client data before insert/update';
COMMENT ON FUNCTION validate_service_provider_data() IS 'Trigger function to validate service provider data before insert/update';
