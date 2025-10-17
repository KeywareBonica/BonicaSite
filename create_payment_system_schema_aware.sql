-- create_payment_system_schema_aware.sql
-- This version is aware of the existing schema structure

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

-- Handle the existing payment_status text column
DO $$ 
DECLARE
    current_type text;
BEGIN
    -- Get current column type
    SELECT data_type INTO current_type
    FROM information_schema.columns 
    WHERE table_name = 'booking' 
    AND table_schema = 'public'
    AND column_name = 'payment_status';
    
    -- If it exists and is text type, we need to convert it
    IF current_type = 'text' THEN
        -- First, update any existing values to valid enum values
        UPDATE public.booking 
        SET payment_status = 'unpaid'
        WHERE payment_status IS NULL 
           OR payment_status NOT IN ('unpaid', 'pending_verification', 'verified', 'rejected', 'refunded');
        
        -- Add a temporary column with the enum type
        ALTER TABLE public.booking 
        ADD COLUMN payment_status_new public.payment_status_enum DEFAULT 'unpaid';
        
        -- Copy data from old column to new column
        UPDATE public.booking 
        SET payment_status_new = CASE 
            WHEN payment_status = 'unpaid' THEN 'unpaid'::payment_status_enum
            WHEN payment_status = 'pending_verification' THEN 'pending_verification'::payment_status_enum
            WHEN payment_status = 'verified' THEN 'verified'::payment_status_enum
            WHEN payment_status = 'rejected' THEN 'rejected'::payment_status_enum
            WHEN payment_status = 'refunded' THEN 'refunded'::payment_status_enum
            ELSE 'unpaid'::payment_status_enum
        END;
        
        -- Drop the old column
        ALTER TABLE public.booking 
        DROP COLUMN payment_status;
        
        -- Rename the new column
        ALTER TABLE public.booking 
        RENAME COLUMN payment_status_new TO payment_status;
        
        -- Set NOT NULL constraint
        ALTER TABLE public.booking 
        ALTER COLUMN payment_status SET NOT NULL;
        
        RAISE NOTICE 'Successfully converted payment_status from text to enum';
    ELSIF current_type IS NULL THEN
        -- Column doesn't exist, create it
        ALTER TABLE public.booking 
        ADD COLUMN payment_status public.payment_status_enum DEFAULT 'unpaid' NOT NULL;
        
        RAISE NOTICE 'Created new payment_status column with enum type';
    ELSE
        RAISE NOTICE 'payment_status column already exists with type: %', current_type;
    END IF;
END $$;

-- Update existing bookings to 'unpaid' if payment_status is NULL (shouldn't happen after conversion, but just in case)
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
-- 7. Set RLS policies for payment table
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
        EXISTS (SELECT 1 FROM public.service_provider sp_admin WHERE sp_admin.service_provider_id = auth.uid() AND sp_admin.service_provider_service_type = 'Admin')
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
-- 8. Verification queries
-- =====================================================

-- Check that payment table was created successfully
SELECT 
    'Payment table created' as status,
    COUNT(*) as existing_payments
FROM public.payment;

-- Check that booking table has payment_status column with correct type
SELECT 
    'Booking payment_status column' as status,
    data_type as column_type
FROM information_schema.columns 
WHERE table_name = 'booking' 
AND table_schema = 'public'
AND column_name = 'payment_status';

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

-- Check current payment_status values in booking table
SELECT 
    'Current payment_status values in booking' as status,
    payment_status,
    COUNT(*) as count
FROM public.booking 
GROUP BY payment_status
ORDER BY payment_status;





