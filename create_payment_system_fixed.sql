-- create_payment_system_fixed.sql

-- =====================================================
-- 1. Create payment_status_enum if it doesn't exist
-- =====================================================
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status_enum') THEN
        CREATE TYPE public.payment_status_enum AS ENUM ('unpaid', 'pending_verification', 'verified', 'rejected', 'refunded');
    END IF;
END $$;

-- =====================================================
-- 2. Create the payment table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.payment (
    payment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id uuid NOT NULL REFERENCES public.booking(booking_id) ON DELETE CASCADE,
    client_id uuid NOT NULL REFERENCES public.client(client_id),
    service_provider_id uuid REFERENCES public.service_provider(service_provider_id), -- Optional: if payment is linked to a specific SP
    
    payment_amount numeric NOT NULL,
    payment_method text DEFAULT 'bank_transfer', -- e.g., 'bank_transfer', 'card', 'cash'
    payment_status public.payment_status_enum DEFAULT 'pending_verification',
    
    proof_of_payment_file_path text,
    proof_of_payment_file_name text,
    proof_of_payment_file_type text,
    proof_of_payment_file_size bigint,
    
    verified_by uuid REFERENCES public.service_provider(service_provider_id), -- Admin/SP who verified
    verification_date timestamp with time zone,
    verification_notes text,
    rejection_reason text,
    
    uploaded_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_payment_booking_id ON public.payment(booking_id);
CREATE INDEX IF NOT EXISTS idx_payment_client_id ON public.payment(client_id);
CREATE INDEX IF NOT EXISTS idx_payment_status ON public.payment(payment_status);

-- =====================================================
-- 3. Update the booking table to reference payment and new payment_status
-- =====================================================

-- First, add payment_id column if it doesn't exist
ALTER TABLE public.booking 
ADD COLUMN IF NOT EXISTS payment_id uuid REFERENCES public.payment(payment_id);

-- Check if payment_status column exists and its current type
DO $$ 
DECLARE
    column_exists boolean;
    column_type text;
BEGIN
    -- Check if payment_status column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'booking' 
        AND table_schema = 'public'
        AND column_name = 'payment_status'
    ) INTO column_exists;
    
    IF column_exists THEN
        -- Get current column type
        SELECT data_type INTO column_type
        FROM information_schema.columns 
        WHERE table_name = 'booking' 
        AND table_schema = 'public'
        AND column_name = 'payment_status';
        
        -- If it's not the enum type, we need to handle the conversion
        IF column_type != 'USER-DEFINED' OR column_type IS NULL THEN
            -- Drop the existing column and recreate it
            ALTER TABLE public.booking DROP COLUMN payment_status;
        END IF;
    END IF;
    
    -- Add payment_status column with enum type
    ALTER TABLE public.booking 
    ADD COLUMN IF NOT EXISTS payment_status public.payment_status_enum DEFAULT 'unpaid';
END $$;

-- Update existing bookings to 'unpaid' if payment_status is NULL
UPDATE public.booking
SET payment_status = 'unpaid'
WHERE payment_status IS NULL;

-- =====================================================
-- 4. Create RPC function for client to submit payment proof
-- =====================================================
CREATE OR REPLACE FUNCTION public.submit_payment(
    p_booking_id uuid,
    p_client_id uuid,
    p_payment_amount numeric,
    p_payment_reference text,
    p_file_path text,
    p_file_name text,
    p_file_type text,
    p_file_size bigint
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_payment_id uuid;
    v_current_booking_status text;
    v_current_payment_status public.payment_status_enum;
BEGIN
    -- Check if the client is the owner of the booking
    IF NOT EXISTS (SELECT 1 FROM public.booking WHERE booking_id = p_booking_id AND client_id = p_client_id) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Unauthorized: Client does not own this booking.');
    END IF;

    -- Get current booking status and payment status
    SELECT booking_status, payment_status INTO v_current_booking_status, v_current_payment_status
    FROM public.booking
    WHERE booking_id = p_booking_id;

    -- Prevent submission if booking is already cancelled or completed
    IF v_current_booking_status IN ('cancelled', 'completed') THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Cannot submit payment for a ' || v_current_booking_status || ' booking.');
    END IF;

    -- Insert new payment record
    INSERT INTO public.payment (
        booking_id,
        client_id,
        payment_amount,
        payment_method,
        payment_status,
        proof_of_payment_file_path,
        proof_of_payment_file_name,
        proof_of_payment_file_type,
        proof_of_payment_file_size,
        verification_notes -- Store reference here initially
    ) VALUES (
        p_booking_id,
        p_client_id,
        p_payment_amount,
        'bank_transfer', -- Assuming bank transfer for POP
        'pending_verification',
        p_file_path,
        p_file_name,
        p_file_type,
        p_file_size,
        'Reference: ' || p_payment_reference
    )
    RETURNING payment_id INTO v_payment_id;

    -- Update the booking with the new payment_id and status
    UPDATE public.booking
    SET
        payment_id = v_payment_id,
        payment_status = 'pending_verification',
        booking_status = 'payment_submitted', -- New booking status for this stage
        updated_at = now()
    WHERE
        booking_id = p_booking_id;

    -- Optional: Notify service providers or admin about new payment submission
    -- This would typically involve a trigger or another RPC call/queue system

    RETURN jsonb_build_object('success', TRUE, 'payment_id', v_payment_id, 'message', 'Payment proof submitted successfully.');

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

-- =====================================================
-- 5. Create RPC function for admin/service provider to verify/reject payment
-- =====================================================
CREATE OR REPLACE FUNCTION public.verify_payment(
    p_payment_id uuid,
    p_service_provider_id uuid, -- The SP/Admin performing verification
    p_action text,              -- 'verify' or 'reject'
    p_notes text DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_booking_id uuid;
    v_client_id uuid;
    v_current_payment_status public.payment_status_enum;
    v_new_payment_status public.payment_status_enum;
    v_new_booking_status text;
BEGIN
    -- Check if the service provider exists and has appropriate role (e.g., admin)
    -- For now, we assume any service_provider_id can verify.
    IF NOT EXISTS (SELECT 1 FROM public.service_provider WHERE service_provider_id = p_service_provider_id) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Unauthorized: Service provider not found.');
    END IF;

    -- Get current payment details
    SELECT booking_id, client_id, payment_status INTO v_booking_id, v_client_id, v_current_payment_status
    FROM public.payment
    WHERE payment_id = p_payment_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Payment record not found.');
    END IF;

    IF v_current_payment_status != 'pending_verification' THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Payment is not in pending_verification status.');
    END IF;

    IF p_action = 'verify' THEN
        v_new_payment_status := 'verified';
        v_new_booking_status := 'confirmed';
        UPDATE public.payment
        SET
            payment_status = v_new_payment_status,
            verified_by = p_service_provider_id,
            verification_date = now(),
            verification_notes = p_notes,
            rejection_reason = NULL,
            updated_at = now()
        WHERE payment_id = p_payment_id;

        UPDATE public.booking
        SET
            payment_status = v_new_payment_status,
            booking_status = v_new_booking_status,
            updated_at = now()
        WHERE booking_id = v_booking_id;

        -- Optional: Send notification to client
        -- PERFORM public.create_notification(v_client_id, 'client', 'Payment Verified', 'Your payment for booking ' || v_booking_id || ' has been verified. Your booking is now confirmed!');

        RETURN jsonb_build_object('success', TRUE, 'message', 'Payment verified successfully.');

    ELSIF p_action = 'reject' THEN
        v_new_payment_status := 'rejected';
        -- Booking status might revert or stay 'payment_submitted' depending on desired flow
        -- For now, let's keep booking_status as 'payment_submitted' and client needs to re-upload
        UPDATE public.payment
        SET
            payment_status = v_new_payment_status,
            verified_by = p_service_provider_id,
            verification_date = now(),
            rejection_reason = p_notes,
            verification_notes = NULL,
            updated_at = now()
        WHERE payment_id = p_payment_id;

        -- Optional: Send notification to client
        -- PERFORM public.create_notification(v_client_id, 'client', 'Payment Rejected', 'Your payment for booking ' || v_booking_id || ' was rejected. Reason: ' || COALESCE(p_notes, 'No reason provided.') || '. Please re-upload proof of payment.');

        RETURN jsonb_build_object('success', TRUE, 'message', 'Payment rejected successfully.');

    ELSE
        RETURN jsonb_build_object('success', FALSE, 'error', 'Invalid action specified. Must be "verify" or "reject".');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

-- =====================================================
-- 6. Create RPC function to get pending payments for admin dashboard
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_pending_payments()
RETURNS SETOF jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT
        jsonb_build_object(
            'payment_id', p.payment_id,
            'payment_amount', p.payment_amount,
            'payment_status', p.payment_status,
            'proof_of_payment_file_path', p.proof_of_payment_file_path,
            'proof_of_payment_file_name', p.proof_of_payment_file_name,
            'uploaded_at', p.uploaded_at,
            'booking', jsonb_build_object(
                'booking_id', b.booking_id,
                'booking_date', b.booking_date,
                'booking_status', b.booking_status,
                'event_id', e.event_id,
                'event_type', e.event_type,
                'event_date', e.event_date,
                'event_location', e.event_location
            ),
            'client', jsonb_build_object(
                'client_id', c.client_id,
                'client_name', c.client_name,
                'client_surname', c.client_surname,
                'client_email', c.client_email,
                'client_contact', c.client_contact
            ),
            'service_provider', jsonb_build_object(
                'service_provider_id', sp.service_provider_id,
                'service_provider_name', sp.service_provider_name,
                'service_provider_service_type', sp.service_provider_service_type
            )
        )
    FROM
        public.payment p
    JOIN
        public.booking b ON p.booking_id = b.booking_id
    JOIN
        public.client c ON p.client_id = c.client_id
    LEFT JOIN
        public.event e ON b.event_id = e.event_id
    LEFT JOIN
        public.service_provider sp ON b.service_provider_id = sp.service_provider_id -- Link to assigned SP in booking
    WHERE
        p.payment_status = 'pending_verification'
    ORDER BY
        p.uploaded_at DESC;
END;
$$;

-- =====================================================
-- 7. Set RLS policies for payment table (example)
-- =====================================================
ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;

-- Policy for clients to view their own payments
DROP POLICY IF EXISTS "Clients can view their own payments." ON public.payment;
CREATE POLICY "Clients can view their own payments."
ON public.payment FOR SELECT
TO authenticated
USING (client_id = auth.uid());

-- Policy for service providers (admins) to view all payments (or payments for their bookings)
DROP POLICY IF EXISTS "Service providers can view payments for their bookings or all if admin." ON public.payment;
CREATE POLICY "Service providers can view payments for their bookings or all if admin."
ON public.payment FOR SELECT
TO authenticated
USING (
    EXISTS (SELECT 1 FROM public.service_provider sp WHERE sp.service_provider_id = auth.uid())
    AND (
        -- Option 1: SP can see payments for bookings they are assigned to
        service_provider_id = auth.uid()
        OR
        -- Option 2: If SP has an 'admin' role, they can see all payments
        EXISTS (SELECT 1 FROM public.service_provider sp_admin WHERE sp_admin.service_provider_id = auth.uid() AND sp_admin.service_provider_service_type = 'Admin') -- Assuming 'Admin' is a service type for admins
    )
);

-- Policy for clients to insert their own payments
DROP POLICY IF EXISTS "Clients can insert their own payments." ON public.payment;
CREATE POLICY "Clients can insert their own payments."
ON public.payment FOR INSERT
TO authenticated
WITH CHECK (client_id = auth.uid());

-- Policy for service providers (admins) to update payment status
DROP POLICY IF EXISTS "Service providers can update payment status." ON public.payment;
CREATE POLICY "Service providers can update payment status."
ON public.payment FOR UPDATE
TO authenticated
USING (
    EXISTS (SELECT 1 FROM public.service_provider sp WHERE sp.service_provider_id = auth.uid())
    AND (
        -- Option 1: SP can update payments for bookings they are assigned to
        service_provider_id = auth.uid()
        OR
        -- Option 2: If SP has an 'admin' role, they can update all payments
        EXISTS (SELECT 1 FROM public.service_provider sp_admin WHERE sp_admin.service_provider_id = auth.uid() AND sp_admin.service_provider_service_type = 'Admin')
    )
)
WITH CHECK (
    EXISTS (SELECT 1 FROM public.service_provider sp WHERE sp.service_provider_id = auth.uid())
    AND (
        -- Option 1: SP
        service_provider_id = auth.uid()
        OR
        -- Option 2: Admin role
        EXISTS (SELECT 1 FROM public.service_provider sp_admin WHERE sp_admin.service_provider_id = auth.uid() AND sp_admin.service_provider_service_type = 'Admin')
    )
);

-- =====================================================
-- 8. Create storage bucket for payment proofs (if using Supabase Storage)
-- =====================================================
-- Note: This would typically be done through the Supabase dashboard or CLI
-- INSERT INTO storage.buckets (id, name, public) VALUES ('payment-proofs', 'payment-proofs', false);

-- =====================================================
-- 9. Verification queries
-- =====================================================

-- Check that payment table was created successfully
SELECT 
    'Payment table created' as status,
    COUNT(*) as existing_payments
FROM public.payment;

-- Check that booking table has payment_status column
SELECT 
    'Booking payment_status column' as status,
    COUNT(*) as bookings_with_payment_status
FROM public.booking 
WHERE payment_status IS NOT NULL;

-- Check enum values
SELECT 
    'Payment status enum values' as status,
    unnest(enum_range(NULL::payment_status_enum)) as enum_values;

-- Check RPC functions exist
SELECT 
    'RPC Functions' as status,
    COUNT(*) as function_count
FROM pg_proc 
WHERE proname IN ('submit_payment', 'verify_payment', 'get_pending_payments')
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');





