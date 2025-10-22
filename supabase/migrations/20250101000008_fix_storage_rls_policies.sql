-- Comprehensive Storage RLS Policy Fix
-- This migration ensures file uploads work properly by setting up correct RLS policies

-- First, ensure RLS is enabled on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing storage policies to avoid conflicts
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- Get all policies on storage.objects table
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'objects' 
        AND schemaname = 'storage'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', policy_record.policyname);
    END LOOP;
END $$;

-- Create universal storage policies that work for all buckets
-- These policies are more permissive to avoid authentication issues

-- Universal upload policy - allows both authenticated and anonymous users
CREATE POLICY "universal_upload_policy" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id IN ('quotations', 'payment', 'images', 'documents')
    AND (
        auth.role() = 'authenticated' 
        OR auth.role() = 'anon'
        OR auth.role() = 'service_role'
    )
);

-- Universal select policy - allows public access to all files
CREATE POLICY "universal_select_policy" ON storage.objects
FOR SELECT USING (
    bucket_id IN ('quotations', 'payment', 'images', 'documents')
);

-- Universal update policy - allows updates for all roles
CREATE POLICY "universal_update_policy" ON storage.objects
FOR UPDATE USING (
    bucket_id IN ('quotations', 'payment', 'images', 'documents')
    AND (
        auth.role() = 'authenticated' 
        OR auth.role() = 'anon'
        OR auth.role() = 'service_role'
    )
);

-- Universal delete policy - allows deletes for all roles
CREATE POLICY "universal_delete_policy" ON storage.objects
FOR DELETE USING (
    bucket_id IN ('quotations', 'payment', 'images', 'documents')
    AND (
        auth.role() = 'authenticated' 
        OR auth.role() = 'anon'
        OR auth.role() = 'service_role'
    )
);

-- Additional policy for service_role (admin operations)
CREATE POLICY "service_role_full_access" ON storage.objects
FOR ALL USING (
    auth.role() = 'service_role'
);

-- Ensure buckets exist with correct settings
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('quotations', 'quotations', true, 10485760, ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
    ('payment', 'payment', true, 10485760, ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'application/pdf']),
    ('images', 'images', true, 5242880, ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']),
    ('documents', 'documents', true, 10485760, ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/plain'])
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Grant necessary permissions
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.objects TO anon;
GRANT ALL ON storage.buckets TO authenticated;
GRANT ALL ON storage.buckets TO anon;
