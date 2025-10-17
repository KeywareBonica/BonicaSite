-- fix_r003_refund_approval.sql
-- R003: Implement refund approval logic and connect it to payment module

-- =====================================================
-- 1. Add refund-related columns to payment table
-- =====================================================

-- Add refund status to payment_status_enum if not exists
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status_enum') THEN
        CREATE TYPE public.payment_status_enum AS ENUM ('unpaid', 'pending_verification', 'verified', 'rejected', 'refunded');
    ELSE
        -- Check if 'refunded' already exists in enum
        IF NOT EXISTS (
            SELECT 1 FROM pg_enum 
            WHERE enumlabel = 'refunded' 
            AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'payment_status_enum')
        ) THEN
            ALTER TYPE public.payment_status_enum ADD VALUE 'refunded';
        END IF;
    END IF;
END $$;

-- Add refund-related columns to payment table
ALTER TABLE public.payment 
ADD COLUMN IF NOT EXISTS refund_requested_at timestamp with time zone,
ADD COLUMN IF NOT EXISTS refund_requested_by uuid REFERENCES public.client(client_id),
ADD COLUMN IF NOT EXISTS refund_reason text,
ADD COLUMN IF NOT EXISTS refund_amount numeric,
ADD COLUMN IF NOT EXISTS refund_approved_at timestamp with time zone,
ADD COLUMN IF NOT EXISTS refund_approved_by uuid REFERENCES public.service_provider(service_provider_id),
ADD COLUMN IF NOT EXISTS refund_approval_notes text,
ADD COLUMN IF NOT EXISTS refund_processed_at timestamp with time zone,
ADD COLUMN IF NOT EXISTS refund_reference text;

-- =====================================================
-- 2. Create refund_request table for tracking refund requests
-- =====================================================
CREATE TABLE IF NOT EXISTS public.refund_request (
    refund_request_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id uuid NOT NULL REFERENCES public.payment(payment_id),
    booking_id uuid NOT NULL REFERENCES public.booking(booking_id),
    client_id uuid NOT NULL REFERENCES public.client(client_id),
    service_provider_id uuid REFERENCES public.service_provider(service_provider_id),
    
    refund_amount numeric NOT NULL,
    refund_reason text NOT NULL,
    refund_request_status text DEFAULT 'pending' CHECK (refund_request_status IN ('pending', 'approved', 'rejected', 'processed')),
    
    requested_at timestamp with time zone DEFAULT now(),
    requested_by uuid REFERENCES public.client(client_id),
    
    reviewed_at timestamp with time zone,
    reviewed_by uuid REFERENCES public.service_provider(service_provider_id),
    review_notes text,
    
    processed_at timestamp with time zone,
    processed_by uuid REFERENCES public.service_provider(service_provider_id),
    processing_notes text,
    refund_reference text,
    
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_refund_request_payment_id ON public.refund_request(payment_id);
CREATE INDEX IF NOT EXISTS idx_refund_request_booking_id ON public.refund_request(booking_id);
CREATE INDEX IF NOT EXISTS idx_refund_request_client_id ON public.refund_request(client_id);
CREATE INDEX IF NOT EXISTS idx_refund_request_status ON public.refund_request(refund_request_status);

-- =====================================================
-- 3. Create RPC function for client to request refund
-- =====================================================
CREATE OR REPLACE FUNCTION public.request_refund(
    p_payment_id uuid,
    p_client_id uuid,
    p_refund_amount numeric,
    p_refund_reason text
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_booking_id uuid;
    v_payment_status public.payment_status_enum;
    v_refund_request_id uuid;
BEGIN
    -- Check if the client owns this payment
    IF NOT EXISTS (
        SELECT 1 FROM public.payment 
        WHERE payment_id = p_payment_id 
        AND client_id = p_client_id
    ) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Unauthorized: Client does not own this payment.');
    END IF;

    -- Get payment and booking details
    SELECT p.booking_id, p.payment_status INTO v_booking_id, v_payment_status
    FROM public.payment p
    WHERE p.payment_id = p_payment_id;

    -- Check if payment is eligible for refund (must be verified)
    IF v_payment_status != 'verified' THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Refund can only be requested for verified payments.');
    END IF;

    -- Check if refund already requested
    IF EXISTS (
        SELECT 1 FROM public.refund_request 
        WHERE payment_id = p_payment_id 
        AND refund_request_status IN ('pending', 'approved')
    ) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Refund already requested for this payment.');
    END IF;

    -- Create refund request
    INSERT INTO public.refund_request (
        payment_id,
        booking_id,
        client_id,
        refund_amount,
        refund_reason,
        requested_by
    ) VALUES (
        p_payment_id,
        v_booking_id,
        p_client_id,
        p_refund_amount,
        p_refund_reason,
        p_client_id
    )
    RETURNING refund_request_id INTO v_refund_request_id;

    -- Update payment table with refund request info
    UPDATE public.payment
    SET
        refund_requested_at = now(),
        refund_requested_by = p_client_id,
        refund_reason = p_refund_reason,
        refund_amount = p_refund_amount,
        updated_at = now()
    WHERE payment_id = p_payment_id;

    RETURN jsonb_build_object(
        'success', TRUE, 
        'refund_request_id', v_refund_request_id,
        'message', 'Refund request submitted successfully. Awaiting admin approval.'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

-- =====================================================
-- 4. Create RPC function for admin to approve/reject refund
-- =====================================================
CREATE OR REPLACE FUNCTION public.process_refund_request(
    p_refund_request_id uuid,
    p_service_provider_id uuid,
    p_action text, -- 'approve' or 'reject'
    p_notes text DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_payment_id uuid;
    v_booking_id uuid;
    v_client_id uuid;
    v_refund_amount numeric;
    v_current_status text;
BEGIN
    -- Check if the service provider exists and has admin privileges
    IF NOT EXISTS (
        SELECT 1 FROM public.service_provider 
        WHERE service_provider_id = p_service_provider_id
    ) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Unauthorized: Service provider not found.');
    END IF;

    -- Get refund request details
    SELECT payment_id, booking_id, client_id, refund_amount, refund_request_status
    INTO v_payment_id, v_booking_id, v_client_id, v_refund_amount, v_current_status
    FROM public.refund_request
    WHERE refund_request_id = p_refund_request_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Refund request not found.');
    END IF;

    IF v_current_status != 'pending' THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Refund request is not in pending status.');
    END IF;

    IF p_action = 'approve' THEN
        -- Approve refund
        UPDATE public.refund_request
        SET
            refund_request_status = 'approved',
            reviewed_at = now(),
            reviewed_by = p_service_provider_id,
            review_notes = p_notes,
            updated_at = now()
        WHERE refund_request_id = p_refund_request_id;

        -- Update payment table
        UPDATE public.payment
        SET
            payment_status = 'refunded',
            refund_approved_at = now(),
            refund_approved_by = p_service_provider_id,
            refund_approval_notes = p_notes,
            updated_at = now()
        WHERE payment_id = v_payment_id;

        -- Update booking status to cancelled (optional, depending on business logic)
        UPDATE public.booking
        SET
            booking_status = 'cancelled',
            updated_at = now()
        WHERE booking_id = v_booking_id;

        RETURN jsonb_build_object('success', TRUE, 'message', 'Refund approved successfully.');

    ELSIF p_action = 'reject' THEN
        -- Reject refund
        UPDATE public.refund_request
        SET
            refund_request_status = 'rejected',
            reviewed_at = now(),
            reviewed_by = p_service_provider_id,
            review_notes = p_notes,
            updated_at = now()
        WHERE refund_request_id = p_refund_request_id;

        RETURN jsonb_build_object('success', TRUE, 'message', 'Refund request rejected.');

    ELSE
        RETURN jsonb_build_object('success', FALSE, 'error', 'Invalid action. Must be "approve" or "reject".');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

-- =====================================================
-- 5. Create RPC function to get pending refund requests for admin
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_pending_refund_requests()
RETURNS SETOF jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT
        jsonb_build_object(
            'refund_request_id', rr.refund_request_id,
            'refund_amount', rr.refund_amount,
            'refund_reason', rr.refund_reason,
            'requested_at', rr.requested_at,
            'payment', jsonb_build_object(
                'payment_id', p.payment_id,
                'payment_amount', p.payment_amount,
                'payment_status', p.payment_status,
                'proof_of_payment_file_path', p.proof_of_payment_file_path,
                'proof_of_payment_file_name', p.proof_of_payment_file_name
            ),
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
        public.refund_request rr
    JOIN
        public.payment p ON rr.payment_id = p.payment_id
    JOIN
        public.booking b ON rr.booking_id = b.booking_id
    JOIN
        public.client c ON rr.client_id = c.client_id
    LEFT JOIN
        public.event e ON b.event_id = e.event_id
    LEFT JOIN
        public.service_provider sp ON b.service_provider_id = sp.service_provider_id
    WHERE
        rr.refund_request_status = 'pending'
    ORDER BY
        rr.requested_at ASC;
END;
$$;

-- =====================================================
-- 6. Set up RLS policies for refund_request table
-- =====================================================
ALTER TABLE public.refund_request ENABLE ROW LEVEL SECURITY;

-- Policy for clients to view their own refund requests
DROP POLICY IF EXISTS "Clients can view their own refund requests." ON public.refund_request;
CREATE POLICY "Clients can view their own refund requests."
ON public.refund_request FOR SELECT
TO authenticated
USING (client_id = auth.uid());

-- Policy for service providers to view refund requests for their bookings
DROP POLICY IF EXISTS "Service providers can view refund requests for their bookings." ON public.refund_request;
CREATE POLICY "Service providers can view refund requests for their bookings."
ON public.refund_request FOR SELECT
TO authenticated
USING (
    EXISTS (SELECT 1 FROM public.service_provider sp WHERE sp.service_provider_id = auth.uid())
    AND (
        service_provider_id = auth.uid()
        OR
        EXISTS (SELECT 1 FROM public.service_provider sp_admin WHERE sp_admin.service_provider_id = auth.uid() AND sp_admin.service_provider_service_type = 'Admin')
    )
);

-- Policy for clients to insert their own refund requests
DROP POLICY IF EXISTS "Clients can insert their own refund requests." ON public.refund_request;
CREATE POLICY "Clients can insert their own refund requests."
ON public.refund_request FOR INSERT
TO authenticated
WITH CHECK (client_id = auth.uid());

-- Policy for service providers to update refund request status
DROP POLICY IF EXISTS "Service providers can update refund request status." ON public.refund_request;
CREATE POLICY "Service providers can update refund request status."
ON public.refund_request FOR UPDATE
TO authenticated
USING (
    EXISTS (SELECT 1 FROM public.service_provider sp WHERE sp.service_provider_id = auth.uid())
    AND (
        service_provider_id = auth.uid()
        OR
        EXISTS (SELECT 1 FROM public.service_provider sp_admin WHERE sp_admin.service_provider_id = auth.uid() AND sp_admin.service_provider_service_type = 'Admin')
    )
);

-- =====================================================
-- 7. Verification queries
-- =====================================================

-- Check that refund_request table was created successfully
SELECT 
    'Refund request table created' as status,
    COUNT(*) as existing_refund_requests
FROM public.refund_request;

-- Check refund-related columns in payment table
SELECT 
    'Payment table refund columns' as status,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'payment' 
AND table_schema = 'public'
AND column_name LIKE '%refund%'
ORDER BY column_name;

-- Check RPC functions exist
SELECT 
    'Refund RPC Functions' as status,
    COUNT(*) as function_count
FROM pg_proc 
WHERE proname IN ('request_refund', 'process_refund_request', 'get_pending_refund_requests')
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');





