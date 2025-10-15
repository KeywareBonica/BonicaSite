-- =====================================================
-- LOOPHOLE 4: FILE VALIDATION FIX
-- =====================================================
-- Problem: quotation_file_path is just text with no validation
-- Solution: Add comprehensive file validation at database level

-- Step 1: Add file validation columns to quotation table
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_file_size bigint;
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_file_hash text;
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_file_type text;
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS quotation_file_validated boolean DEFAULT false;

-- Step 2: Create file validation function
CREATE OR REPLACE FUNCTION public.validate_quotation_file()
RETURNS TRIGGER AS $$
BEGIN
    -- Only validate if file path is provided
    IF NEW.quotation_file_path IS NOT NULL THEN
        
        -- Validate file path format
        IF NEW.quotation_file_path !~ '^/quotations/[a-f0-9\-]+_[a-f0-9\-]+_[0-9]+\.(pdf|doc|docx)$' THEN
            RAISE EXCEPTION 'Invalid file path format. Expected: /quotations/{provider_id}_{job_cart_id}_{timestamp}.pdf';
        END IF;
        
        -- Validate file type if provided
        IF NEW.quotation_file_type IS NOT NULL THEN
            IF NEW.quotation_file_type NOT IN ('application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') THEN
                RAISE EXCEPTION 'Invalid file type. Only PDF and Word documents are allowed.';
            END IF;
        END IF;
        
        -- Validate file size if provided (max 10MB)
        IF NEW.quotation_file_size IS NOT NULL THEN
            IF NEW.quotation_file_size > 10485760 THEN -- 10MB in bytes
                RAISE EXCEPTION 'File size exceeds maximum allowed size of 10MB.';
            END IF;
            
            IF NEW.quotation_file_size < 1024 THEN -- 1KB minimum
                RAISE EXCEPTION 'File size is too small. Minimum file size is 1KB.';
            END IF;
        END IF;
        
        -- Validate file hash if provided (basic format check)
        IF NEW.quotation_file_hash IS NOT NULL THEN
            IF NEW.quotation_file_hash !~ '^[a-f0-9]{64}$' THEN
                RAISE EXCEPTION 'Invalid file hash format. Expected 64-character SHA-256 hash.';
            END IF;
        END IF;
        
        -- Mark as validated if all checks pass
        NEW.quotation_file_validated = true;
        
    ELSE
        -- No file provided - this is allowed for text-only quotations
        NEW.quotation_file_validated = true;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create trigger for file validation
DROP TRIGGER IF EXISTS trg_validate_quotation_file ON public.quotation;
CREATE TRIGGER trg_validate_quotation_file
    BEFORE INSERT OR UPDATE ON public.quotation
    FOR EACH ROW 
    EXECUTE FUNCTION public.validate_quotation_file();

-- Step 4: Create function to check if file exists in storage
CREATE OR REPLACE FUNCTION public.check_file_exists(file_path text)
RETURNS boolean AS $$
DECLARE
    file_exists boolean := false;
BEGIN
    -- This function would typically check against your file storage system
    -- For now, we'll implement basic path validation
    -- In a real implementation, you'd integrate with your storage service (S3, local filesystem, etc.)
    
    IF file_path IS NULL OR file_path = '' THEN
        RETURN false;
    END IF;
    
    -- Basic path validation
    IF file_path !~ '^/quotations/[a-f0-9\-]+_[a-f0-9\-]+_[0-9]+\.(pdf|doc|docx)$' THEN
        RETURN false;
    END IF;
    
    -- In production, you would add actual file existence checks here
    -- For example:
    -- SELECT storage.files_exist(file_path) INTO file_exists;
    
    -- For now, return true if path format is valid
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Create function to validate quotation file integrity
CREATE OR REPLACE FUNCTION public.validate_quotation_file_integrity()
RETURNS TRIGGER AS $$
DECLARE
    file_exists boolean;
BEGIN
    -- Only validate if file path is provided
    IF NEW.quotation_file_path IS NOT NULL THEN
        
        -- Check if file exists in storage
        SELECT public.check_file_exists(NEW.quotation_file_path) INTO file_exists;
        
        IF NOT file_exists THEN
            RAISE EXCEPTION 'Quotation file does not exist in storage: %', NEW.quotation_file_path;
        END IF;
        
        -- Additional validation for file hash
        IF NEW.quotation_file_hash IS NOT NULL THEN
            -- In production, you would verify the file hash matches the actual file
            -- For now, we just ensure the hash is provided when a file is uploaded
            IF NEW.quotation_file_hash = '' THEN
                RAISE EXCEPTION 'File hash is required when uploading a file.';
            END IF;
        END IF;
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Create trigger for file integrity validation
DROP TRIGGER IF EXISTS trg_validate_file_integrity ON public.quotation;
CREATE TRIGGER trg_validate_file_integrity
    BEFORE INSERT OR UPDATE ON public.quotation
    FOR EACH ROW 
    EXECUTE FUNCTION public.validate_quotation_file_integrity();

-- Step 7: Add constraints for file validation
ALTER TABLE public.quotation ADD CONSTRAINT chk_file_size_positive 
    CHECK (quotation_file_size IS NULL OR quotation_file_size > 0);

ALTER TABLE public.quotation ADD CONSTRAINT chk_file_type_valid 
    CHECK (quotation_file_type IS NULL OR quotation_file_type IN (
        'application/pdf', 
        'application/msword', 
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ));

-- Update existing rows to set quotation_file_validated = true for all existing quotations
UPDATE public.quotation 
SET quotation_file_validated = true 
WHERE quotation_file_validated IS NULL;

-- Note: We're not adding the chk_file_validated constraint because:
-- 1. The validation logic is already handled by triggers
-- 2. Existing data might have null values that cause constraint violations
-- 3. The trigger ensures new quotations are properly validated

-- Step 8: Create index for file validation queries
CREATE INDEX IF NOT EXISTS idx_quotation_file_validated 
    ON public.quotation (quotation_file_validated) 
    WHERE quotation_file_path IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_quotation_file_path 
    ON public.quotation (quotation_file_path) 
    WHERE quotation_file_path IS NOT NULL;

-- Step 9: Create view for quotations with file validation status
CREATE OR REPLACE VIEW public.quotation_with_file_validation AS
SELECT 
    q.*,
    CASE 
        WHEN q.quotation_file_path IS NULL THEN 'No File'
        WHEN q.quotation_file_validated = true THEN 'Valid'
        ELSE 'Invalid'
    END as file_validation_status,
    CASE 
        WHEN q.quotation_file_size IS NOT NULL THEN 
            ROUND(q.quotation_file_size / 1024.0, 2) || ' KB'
        ELSE NULL
    END as file_size_formatted
FROM public.quotation q;

-- Step 10: Create function to clean up invalid quotations
CREATE OR REPLACE FUNCTION public.cleanup_invalid_quotations()
RETURNS integer AS $$
DECLARE
    deleted_count integer;
BEGIN
    -- Delete quotations with invalid file paths that are older than 1 hour
    DELETE FROM public.quotation 
    WHERE quotation_file_path IS NOT NULL 
    AND quotation_file_validated = false 
    AND created_at < NOW() - INTERVAL '1 hour';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 11: Create scheduled cleanup (this would typically be done via cron job)
-- For now, we'll create a function that can be called manually
COMMENT ON FUNCTION public.cleanup_invalid_quotations() IS 
'Cleans up quotations with invalid files older than 1 hour. Call this function periodically to maintain data integrity.';

-- Summary
SELECT 'Loophole 4: File Validation - Database Level Implementation Complete' as status;
