-- Create payment storage bucket for proof of payment files (if it doesn't exist)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
SELECT 'payment', 'payment', true, 10485760, ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'application/pdf']
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'payment');

-- Enable RLS on storage.objects table
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated users to upload payment proofs" ON storage.objects;
DROP POLICY IF EXISTS "Allow public access to view payment proofs" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update their payment proofs" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete their payment proofs" ON storage.objects;

-- Create comprehensive RLS policies for payment storage
CREATE POLICY "payment_upload_policy" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'payment' 
    AND (
        auth.role() = 'authenticated' 
        OR auth.role() = 'anon'
    )
);

CREATE POLICY "payment_select_policy" ON storage.objects
FOR SELECT USING (
    bucket_id = 'payment'
);

CREATE POLICY "payment_update_policy" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'payment' 
    AND (
        auth.role() = 'authenticated' 
        OR auth.role() = 'anon'
    )
);

CREATE POLICY "payment_delete_policy" ON storage.objects
FOR DELETE USING (
    bucket_id = 'payment' 
    AND (
        auth.role() = 'authenticated' 
        OR auth.role() = 'anon'
    )
);
