-- ============================================================================
-- REMOVE RLS POLICIES - ALTERNATIVE APPROACH
-- Uses Supabase's built-in functions instead of direct table modification
-- ============================================================================

-- Method 1: Drop policies using Supabase's policy management
-- (Run these one by one in Supabase SQL Editor)

-- Drop individual policies
DROP POLICY IF EXISTS "Service providers can upload quotation files" ON storage.objects;
DROP POLICY IF EXISTS "Service providers can view their quotation files" ON storage.objects;
DROP POLICY IF EXISTS "Clients can view quotation files" ON storage.objects;
DROP POLICY IF EXISTS "Service providers can update their quotation files" ON storage.objects;
DROP POLICY IF EXISTS "Service providers can delete their quotation files" ON storage.objects;
DROP POLICY IF EXISTS "Allow quotation file management" ON storage.objects;

-- ============================================================================
-- ALTERNATIVE: CREATE A SIMPLE PERMISSIVE POLICY
-- ============================================================================

-- If dropping policies doesn't work, create a simple permissive policy instead:
CREATE POLICY "Allow all quotation file access" 
ON storage.objects 
FOR ALL 
TO authenticated 
WITH CHECK (bucket_id = 'quotations');

-- ============================================================================
-- METHOD 3: USE SUPABASE DASHBOARD
-- ============================================================================

-- If SQL doesn't work, use Supabase Dashboard:
-- 1. Go to Authentication > Policies
-- 2. Find storage.objects policies
-- 3. Delete all quotation-related policies
-- 4. Or create a simple policy: "Allow all authenticated users"

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check current policies
SELECT policyname, cmd, permissive 
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if RLS is disabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'objects' 
AND schemaname = 'storage';

-- Check if any policies remain
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage';

-- ============================================================================
-- NOTES
-- ============================================================================
-- 1. This completely removes all security restrictions on file uploads
-- 2. Anyone with access to your Supabase project can upload/view files
-- 3. Use this only for development/testing - NOT recommended for production
-- 4. To re-enable RLS later, run: ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
