-- =====================================================
-- LOOPHOLE 4: FILE STORAGE VALIDATION
-- =====================================================
-- Problem: No validation that files actually exist in storage
-- Solution: Create file storage validation system

-- Step 1: Create file storage tracking table
CREATE TABLE IF NOT EXISTS public.file_storage (
    file_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    file_path text NOT NULL UNIQUE,
    file_name text NOT NULL,
    file_size bigint NOT NULL,
    file_type text NOT NULL,
    file_hash text NOT NULL,
    upload_date timestamp without time zone DEFAULT now(),
    uploaded_by uuid,
    uploaded_by_type user_type_enum,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    
    CONSTRAINT chk_file_size_positive CHECK (file_size > 0),
    CONSTRAINT chk_file_type_valid CHECK (file_type IN (
        'application/pdf', 
        'application/msword', 
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    )),
    CONSTRAINT chk_file_hash_format CHECK (file_hash ~ '^[a-f0-9]{64}$')
);

-- Step 2: Create indexes for file storage queries
CREATE INDEX IF NOT EXISTS idx_file_storage_path ON public.file_storage (file_path);
CREATE INDEX IF NOT EXISTS idx_file_storage_hash ON public.file_storage (file_hash);
CREATE INDEX IF NOT EXISTS idx_file_storage_active ON public.file_storage (is_active) WHERE is_active = true;

-- Step 3: Create function to register file in storage
CREATE OR REPLACE FUNCTION public.register_file_in_storage(
    p_file_path text,
    p_file_name text,
    p_file_size bigint,
    p_file_type text,
    p_file_hash text,
    p_uploaded_by uuid DEFAULT NULL,
    p_uploaded_by_type user_type_enum DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
    file_id uuid;
BEGIN
    -- Validate file parameters
    IF p_file_path IS NULL OR p_file_path = '' THEN
        RAISE EXCEPTION 'File path cannot be null or empty';
    END IF;
    
    IF p_file_name IS NULL OR p_file_name = '' THEN
        RAISE EXCEPTION 'File name cannot be null or empty';
    END IF;
    
    IF p_file_size IS NULL OR p_file_size <= 0 THEN
        RAISE EXCEPTION 'File size must be greater than 0';
    END IF;
    
    IF p_file_type IS NULL OR p_file_type NOT IN (
        'application/pdf', 
        'application/msword', 
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ) THEN
        RAISE EXCEPTION 'Invalid file type';
    END IF;
    
    IF p_file_hash IS NULL OR p_file_hash !~ '^[a-f0-9]{64}$' THEN
        RAISE EXCEPTION 'Invalid file hash format';
    END IF;
    
    -- Check if file already exists
    IF EXISTS (SELECT 1 FROM public.file_storage WHERE file_path = p_file_path AND is_active = true) THEN
        RAISE EXCEPTION 'File already exists in storage: %', p_file_path;
    END IF;
    
    -- Insert file record
    INSERT INTO public.file_storage (
        file_path, file_name, file_size, file_type, file_hash, 
        uploaded_by, uploaded_by_type
    ) VALUES (
        p_file_path, p_file_name, p_file_size, p_file_type, p_file_hash,
        p_uploaded_by, p_uploaded_by_type
    ) RETURNING file_id INTO file_id;
    
    RETURN file_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Create function to check if file exists in storage
CREATE OR REPLACE FUNCTION public.file_exists_in_storage(p_file_path text)
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.file_storage 
        WHERE file_path = p_file_path 
        AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Create function to verify file integrity
CREATE OR REPLACE FUNCTION public.verify_file_integrity(
    p_file_path text,
    p_expected_hash text DEFAULT NULL
)
RETURNS boolean AS $$
DECLARE
    stored_hash text;
    stored_size bigint;
BEGIN
    -- Get file information from storage
    SELECT file_hash, file_size INTO stored_hash, stored_size
    FROM public.file_storage 
    WHERE file_path = p_file_path AND is_active = true;
    
    -- File not found
    IF stored_hash IS NULL THEN
        RETURN false;
    END IF;
    
    -- If expected hash provided, verify it matches
    IF p_expected_hash IS NOT NULL THEN
        RETURN stored_hash = p_expected_hash;
    END IF;
    
    -- File exists and is active
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Update quotation table to reference file storage
ALTER TABLE public.quotation ADD COLUMN IF NOT EXISTS file_storage_id uuid;

-- Add foreign key constraint
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'quotation_file_storage_fkey'
        AND table_name = 'quotation'
    ) THEN
        ALTER TABLE public.quotation
        ADD CONSTRAINT quotation_file_storage_fkey
        FOREIGN KEY (file_storage_id) REFERENCES public.file_storage(file_id);
    END IF;
END$$;

-- Step 7: Create function to link quotation with file storage
CREATE OR REPLACE FUNCTION public.link_quotation_with_file(
    p_quotation_id uuid,
    p_file_path text,
    p_file_name text,
    p_file_size bigint,
    p_file_type text,
    p_file_hash text,
    p_uploaded_by uuid DEFAULT NULL,
    p_uploaded_by_type user_type_enum DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
    file_id uuid;
BEGIN
    -- Register file in storage
    SELECT public.register_file_in_storage(
        p_file_path, p_file_name, p_file_size, p_file_type, p_file_hash,
        p_uploaded_by, p_uploaded_by_type
    ) INTO file_id;
    
    -- Update quotation with file storage ID
    UPDATE public.quotation 
    SET file_storage_id = file_id
    WHERE quotation_id = p_quotation_id;
    
    RETURN file_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 8: Create enhanced quotation view with file validation
CREATE OR REPLACE VIEW public.quotation_with_file_validation_enhanced AS
SELECT 
    q.*,
    fs.file_name as actual_file_name,
    fs.file_size as actual_file_size,
    fs.file_type as actual_file_type,
    fs.file_hash as actual_file_hash,
    fs.upload_date as file_upload_date,
    fs.is_active as file_is_active,
    CASE 
        WHEN q.quotation_file_path IS NULL THEN 'No File'
        WHEN fs.file_id IS NULL THEN 'File Not Found'
        WHEN fs.is_active = false THEN 'File Deleted'
        WHEN q.quotation_file_hash IS NOT NULL AND fs.file_hash != q.quotation_file_hash THEN 'Hash Mismatch'
        WHEN q.quotation_file_validated = true THEN 'Valid'
        ELSE 'Invalid'
    END as file_validation_status,
    CASE 
        WHEN fs.file_size IS NOT NULL THEN 
            ROUND(fs.file_size / 1024.0, 2) || ' KB'
        ELSE NULL
    END as file_size_formatted
FROM public.quotation q
LEFT JOIN public.file_storage fs ON q.file_storage_id = fs.file_id;

-- Step 9: Create function to clean up orphaned files
CREATE OR REPLACE FUNCTION public.cleanup_orphaned_files()
RETURNS integer AS $$
DECLARE
    deleted_count integer;
BEGIN
    -- Delete files that are not referenced by any quotation and are older than 24 hours
    DELETE FROM public.file_storage 
    WHERE file_id NOT IN (
        SELECT DISTINCT file_storage_id 
        FROM public.quotation 
        WHERE file_storage_id IS NOT NULL
    )
    AND upload_date < NOW() - INTERVAL '24 hours'
    AND is_active = true;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 10: Create function to validate all quotation files
CREATE OR REPLACE FUNCTION public.validate_all_quotation_files()
RETURNS TABLE (
    quotation_id uuid,
    file_path text,
    validation_status text,
    issue_description text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        q.quotation_id,
        q.quotation_file_path,
        CASE 
            WHEN q.quotation_file_path IS NULL THEN 'No File'
            WHEN fs.file_id IS NULL THEN 'File Not Found'
            WHEN fs.is_active = false THEN 'File Deleted'
            WHEN q.quotation_file_hash IS NOT NULL AND fs.file_hash != q.quotation_file_hash THEN 'Hash Mismatch'
            WHEN q.quotation_file_validated = true THEN 'Valid'
            ELSE 'Invalid'
        END as validation_status,
        CASE 
            WHEN q.quotation_file_path IS NULL THEN 'No file attached to quotation'
            WHEN fs.file_id IS NULL THEN 'File not found in storage: ' || q.quotation_file_path
            WHEN fs.is_active = false THEN 'File has been deleted from storage'
            WHEN q.quotation_file_hash IS NOT NULL AND fs.file_hash != q.quotation_file_hash THEN 'File hash does not match stored hash'
            WHEN q.quotation_file_validated = true THEN 'File is valid'
            ELSE 'File validation failed'
        END as issue_description
    FROM public.quotation q
    LEFT JOIN public.file_storage fs ON q.file_storage_id = fs.file_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 11: Add RLS policies for file storage
ALTER TABLE public.file_storage ENABLE ROW LEVEL SECURITY;

-- Policy for service providers to view their own files
CREATE POLICY "Service providers can view their own files" ON public.file_storage
    FOR SELECT USING (
        uploaded_by = auth.uid() AND 
        uploaded_by_type = 'service_provider'::user_type_enum
    );

-- Policy for clients to view files for their quotations
CREATE POLICY "Clients can view files for their quotations" ON public.file_storage
    FOR SELECT USING (
        file_id IN (
            SELECT q.file_storage_id 
            FROM public.quotation q
            JOIN public.job_cart jc ON q.job_cart_id = jc.job_cart_id
            WHERE jc.client_id = auth.uid()
        )
    );

-- Summary
SELECT 'Loophole 4: File Storage Validation - Implementation Complete' as status;







