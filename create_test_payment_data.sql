-- create_test_payment_data.sql
-- Create test payment data to populate your payment dashboard

-- =====================================================
-- 1. Check what bookings we have to work with
-- =====================================================
SELECT 
    'Available bookings for payment test:' as info;

SELECT 
    b.booking_id,
    b.booking_status,
    b.client_id,
    b.service_provider_id,
    c.client_name,
    c.client_surname,
    e.event_type,
    e.event_date
FROM public.booking b
JOIN public.client c ON b.client_id = c.client_id
JOIN public.event e ON b.event_id = e.event_id
WHERE b.booking_status IN ('confirmed', 'active', 'pending')
ORDER BY b.created_at DESC
LIMIT 10;

-- =====================================================
-- 2. Create test payments for existing bookings
-- =====================================================

-- Insert test payment for the first booking (if any exist)
INSERT INTO public.payment (
    booking_id,
    client_id,
    service_provider_id,
    payment_amount,
    payment_method,
    payment_status,
    proof_of_payment_file_name,
    proof_of_payment_file_path,
    proof_of_payment_file_type,
    proof_of_payment_file_size,
    uploaded_at
)
SELECT 
    b.booking_id,
    b.client_id,
    b.service_provider_id,
    CASE 
        WHEN b.booking_total_price IS NOT NULL THEN b.booking_total_price
        ELSE 1500.00
    END,
    'bank_transfer',
    'pending_verification',
    'payment_proof_' || b.booking_id::text || '.pdf',
    'uploads/payment_proof_' || b.booking_id::text || '.pdf',
    'application/pdf',
    1024000, -- 1MB file size
    now() - (random() * interval '7 days')
FROM public.booking b
WHERE b.booking_status IN ('confirmed', 'active', 'pending')
AND NOT EXISTS (
    SELECT 1 FROM public.payment p 
    WHERE p.booking_id = b.booking_id
)
LIMIT 3;

-- =====================================================
-- 3. Create additional test payments with different statuses
-- =====================================================

-- Create an approved payment
INSERT INTO public.payment (
    booking_id,
    client_id,
    service_provider_id,
    payment_amount,
    payment_method,
    payment_status,
    proof_of_payment_file_name,
    proof_of_payment_file_path,
    proof_of_payment_file_type,
    proof_of_payment_file_size,
    verified_by,
    verification_date,
    verification_notes,
    uploaded_at,
    created_at
)
SELECT 
    b.booking_id,
    b.client_id,
    b.service_provider_id,
    2000.00,
    'bank_transfer',
    'verified',
    'approved_payment_' || b.booking_id::text || '.pdf',
    'uploads/approved_payment_' || b.booking_id::text || '.pdf',
    'application/pdf',
    2048000, -- 2MB file size
    b.service_provider_id, -- Verified by service provider
    now() - interval '1 day',
    'Payment verified successfully. Bank transfer confirmed.',
    now() - interval '2 days',
    now() - interval '2 days'
FROM public.booking b
WHERE b.booking_status IN ('confirmed', 'active', 'pending')
AND b.service_provider_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM public.payment p 
    WHERE p.booking_id = b.booking_id
)
LIMIT 1;

-- Create a rejected payment
INSERT INTO public.payment (
    booking_id,
    client_id,
    service_provider_id,
    payment_amount,
    payment_method,
    payment_status,
    proof_of_payment_file_name,
    proof_of_payment_file_path,
    proof_of_payment_file_type,
    proof_of_payment_file_size,
    verified_by,
    verification_date,
    rejection_reason,
    uploaded_at,
    created_at
)
SELECT 
    b.booking_id,
    b.client_id,
    b.service_provider_id,
    800.00,
    'bank_transfer',
    'rejected',
    'rejected_payment_' || b.booking_id::text || '.pdf',
    'uploads/rejected_payment_' || b.booking_id::text || '.pdf',
    'application/pdf',
    512000, -- 512KB file size
    b.service_provider_id, -- Rejected by service provider
    now() - interval '3 hours',
    'Payment proof is unclear. Please upload a clearer bank statement.',
    now() - interval '1 day',
    now() - interval '1 day'
FROM public.booking b
WHERE b.booking_status IN ('confirmed', 'active', 'pending')
AND b.service_provider_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM public.payment p 
    WHERE p.booking_id = b.booking_id
)
LIMIT 1;

-- =====================================================
-- 4. Verify the test data was created
-- =====================================================
SELECT 
    'Payment test data created:' as info;

SELECT 
    payment_id,
    payment_status,
    payment_amount,
    payment_method,
    proof_of_payment_file_name,
    uploaded_at,
    verification_date
FROM public.payment
ORDER BY uploaded_at DESC;

-- =====================================================
-- 5. Show payment summary for dashboard
-- =====================================================
SELECT 
    'Payment summary for dashboard:' as info;

SELECT 
    payment_status,
    COUNT(*) as count,
    SUM(payment_amount) as total_amount
FROM public.payment
GROUP BY payment_status
ORDER BY payment_status;

-- =====================================================
-- 6. Show detailed payment data for dashboard table
-- =====================================================
SELECT 
    'Detailed payment data for dashboard:' as info;

SELECT 
    p.payment_id,
    c.client_name || ' ' || c.client_surname as client_name,
    b.booking_id,
    p.payment_amount,
    p.payment_method,
    p.payment_status,
    p.uploaded_at,
    p.proof_of_payment_file_name,
    CASE 
        WHEN p.payment_status = 'pending_verification' THEN 'Review'
        WHEN p.payment_status = 'verified' THEN 'Approved'
        WHEN p.payment_status = 'rejected' THEN 'Rejected'
        ELSE 'Unknown'
    END as action_needed
FROM public.payment p
JOIN public.booking b ON p.booking_id = b.booking_id
JOIN public.client c ON p.client_id = c.client_id
ORDER BY p.uploaded_at DESC;





