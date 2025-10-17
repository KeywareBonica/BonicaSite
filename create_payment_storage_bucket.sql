-- =====================================================
-- PAYMENT PROOF STORAGE BUCKET SETUP
-- =====================================================
-- This script creates and configures the storage bucket
-- for payment proof files (images and PDFs)
-- =====================================================

-- =====================================================
-- Step 1: Create storage bucket for payment proofs
-- =====================================================
-- Note: This needs to be run in Supabase Dashboard > Storage
-- Or use the Supabase API

-- Bucket configuration:
-- Name: payment-proofs
-- Public: false (only authenticated users can access)
-- File size limit: 5MB
-- Allowed MIME types: image/jpeg, image/jpg, image/png, application/pdf

-- To create via SQL (if your Supabase version supports it):
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'payment-proofs',
    'payment-proofs',
    false,
    5242880, -- 5MB in bytes
    ARRAY['image/jpeg', 'image/jpg', 'image/png', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- Step 2: Create storage policies for payment proofs
-- =====================================================

-- Policy 1: Clients can upload their own payment proofs
CREATE POLICY "Clients can upload payment proofs"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'payment-proofs' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy 2: Clients can view their own payment proofs
CREATE POLICY "Clients can view own payment proofs"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'payment-proofs' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy 3: Service providers (admins) can view all payment proofs
CREATE POLICY "Admins can view all payment proofs"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'payment-proofs' AND
    EXISTS (
        SELECT 1 FROM public.service_provider
        WHERE service_provider_id = auth.uid()
    )
);

-- Policy 4: Admins can delete payment proofs (for cleanup)
CREATE POLICY "Admins can delete payment proofs"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'payment-proofs' AND
    EXISTS (
        SELECT 1 FROM public.service_provider
        WHERE service_provider_id = auth.uid()
    )
);

-- =====================================================
-- Step 3: Verification
-- =====================================================
SELECT 
    'Storage bucket created' as status,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets
WHERE id = 'payment-proofs';

-- =====================================================
-- MANUAL STEPS (If SQL approach doesn't work)
-- =====================================================
/*
If the above SQL doesn't work, follow these manual steps in Supabase Dashboard:

1. Go to Storage in the Supabase Dashboard
2. Click "New Bucket"
3. Configure as follows:
   - Name: payment-proofs
   - Public: OFF (keep it private)
   - File size limit: 5 MB
   - Allowed MIME types: image/jpeg, image/jpg, image/png, application/pdf

4. Create RLS Policies:
   a) For INSERT:
      - Name: "Clients can upload payment proofs"
      - Target roles: authenticated
      - WITH CHECK: bucket_id = 'payment-proofs'
   
   b) For SELECT:
      - Name: "Users can view relevant payment proofs"
      - Target roles: authenticated
      - USING: bucket_id = 'payment-proofs'
   
   c) For DELETE:
      - Name: "Admins can delete payment proofs"
      - Target roles: authenticated
      - USING: bucket_id = 'payment-proofs' AND EXISTS (
                 SELECT 1 FROM service_provider WHERE service_provider_id = auth.uid()
               )
*/

-- =====================================================
-- STORAGE BUCKET SETUP COMPLETE
-- =====================================================






