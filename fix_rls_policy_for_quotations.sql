-- ============================================================================
-- RLS POLICY FIX FOR QUOTATION FILE UPLOADS
-- Allows service providers to upload and manage quotation files
-- ============================================================================

-- First, ensure the quotations bucket exists
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'quotations', 
    'quotations', 
    false, 
    10485760, -- 10MB limit
    ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- RLS POLICIES FOR QUOTATION FILE UPLOADS AND VIEWING
-- ============================================================================

-- Policy 1: Allow service providers to upload quotation files
CREATE POLICY "Service providers can upload quotation files" 
ON storage.objects 
FOR INSERT 
TO authenticated 
WITH CHECK (
    bucket_id = 'quotations' 
    AND auth.role() = 'authenticated'
    AND EXISTS (
        SELECT 1 FROM public.service_provider 
        WHERE service_provider_id::text = (storage.foldername(name))[1]
    )
);

-- Policy 2: Allow service providers to view their own quotation files
CREATE POLICY "Service providers can view their quotation files" 
ON storage.objects 
FOR SELECT 
TO authenticated 
WITH CHECK (
    bucket_id = 'quotations' 
    AND auth.role() = 'authenticated'
    AND EXISTS (
        SELECT 1 FROM public.service_provider 
        WHERE service_provider_id::text = (storage.foldername(name))[1]
    )
);

-- Policy 3: Allow clients to view quotation files (for quotations they can access)
CREATE POLICY "Clients can view quotation files" 
ON storage.objects 
FOR SELECT 
TO authenticated 
WITH CHECK (
    bucket_id = 'quotations' 
    AND auth.role() = 'authenticated'
    AND EXISTS (
        SELECT 1 FROM public.quotation q
        JOIN public.job_cart jc ON q.job_cart_id = jc.job_cart_id
        WHERE q.quotation_file_path = name
        AND jc.client_id::text = auth.uid()::text
    )
);

-- Policy 4: Allow service providers to update their quotation files
CREATE POLICY "Service providers can update their quotation files" 
ON storage.objects 
FOR UPDATE 
TO authenticated 
WITH CHECK (
    bucket_id = 'quotations' 
    AND auth.role() = 'authenticated'
    AND EXISTS (
        SELECT 1 FROM public.service_provider 
        WHERE service_provider_id::text = (storage.foldername(name))[1]
    )
);

-- Policy 5: Allow service providers to delete their quotation files
CREATE POLICY "Service providers can delete their quotation files" 
ON storage.objects 
FOR DELETE 
TO authenticated 
WITH CHECK (
    bucket_id = 'quotations' 
    AND auth.role() = 'authenticated'
    AND EXISTS (
        SELECT 1 FROM public.service_provider 
        WHERE service_provider_id::text = (storage.foldername(name))[1]
    )
);

-- ============================================================================
-- ALTERNATIVE SIMPLER POLICY (if the above doesn't work)
-- ============================================================================

-- If the complex policies don't work, use this simpler approach:
-- (Uncomment and use this if the above policies fail)

/*
-- Simple policy: Allow all authenticated users to manage quotation files
CREATE POLICY "Allow quotation file management" 
ON storage.objects 
FOR ALL 
TO authenticated 
WITH CHECK (bucket_id = 'quotations');
*/

-- ============================================================================
-- EVEN SIMPLER POLICY (if still having issues)
-- ============================================================================

-- If you're still having RLS issues, temporarily disable RLS on storage.objects:
-- (Only use this for testing - not recommended for production)

/*
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
*/

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage';

-- Check if quotations bucket exists
SELECT * FROM storage.buckets WHERE id = 'quotations';

-- ============================================================================
-- NOTES
-- ============================================================================
-- 1. The policies assume file paths are structured as: service_provider_id/filename
-- 2. If your file path structure is different, adjust the folder extraction logic
-- 3. The policies check if the service_provider_id in the file path exists in the service_provider table
-- 4. If you get errors, try the simpler policy (uncommented version above)
