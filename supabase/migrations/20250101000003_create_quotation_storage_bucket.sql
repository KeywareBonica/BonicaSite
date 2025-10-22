-- Create quotation storage bucket for file uploads (if it doesn't exist)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
SELECT 'quotations', 'quotations', true, 10485760, ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'quotations');

-- Enable RLS on storage.objects table
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated users to upload quotations" ON storage.objects;
DROP POLICY IF EXISTS "Allow public access to view quotations" ON storage.objects;
DROP POLICY IF EXISTS "Allow service providers to update their quotations" ON storage.objects;
DROP POLICY IF EXISTS "Allow service providers to delete their quotations" ON storage.objects;

-- Create comprehensive RLS policies for quotation storage
CREATE POLICY "quotations_upload_policy" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'quotations' 
    AND (
        auth.role() = 'authenticated' 
        OR auth.role() = 'anon'
    )
);

CREATE POLICY "quotations_select_policy" ON storage.objects
FOR SELECT USING (
    bucket_id = 'quotations'
);

CREATE POLICY "quotations_update_policy" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'quotations' 
    AND (
        auth.role() = 'authenticated' 
        OR auth.role() = 'anon'
    )
);

CREATE POLICY "quotations_delete_policy" ON storage.objects
FOR DELETE USING (
    bucket_id = 'quotations' 
    AND (
        auth.role() = 'authenticated' 
        OR auth.role() = 'anon'
    )
);
