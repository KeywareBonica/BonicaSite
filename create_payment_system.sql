-- =====================================================
-- PAYMENT SYSTEM IMPLEMENTATION
-- =====================================================
-- This migration creates a comprehensive payment tracking system
-- with proof of payment upload and admin verification workflow
-- =====================================================

-- =====================================================
-- Step 1: Create the payment table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.payment (
    payment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id uuid NOT NULL REFERENCES public.booking(booking_id) ON DELETE CASCADE,
    client_id uuid NOT NULL REFERENCES public.client(client_id) ON DELETE CASCADE,
    service_provider_id uuid REFERENCES public.service_provider(service_provider_id),
    
    -- Payment details
    payment_amount numeric NOT NULL CHECK (payment_amount > 0),
    payment_method text DEFAULT 'bank_transfer' CHECK (payment_method IN ('bank_transfer', 'eft', 'cash', 'card', 'other')),
    payment_status text DEFAULT 'pending' CHECK (payment_status IN ('pending', 'verified', 'rejected', 'refunded')),
    payment_reference text, -- Client's payment reference number
    
    -- Proof of payment file details
    proof_of_payment_file_path text,
    proof_of_payment_file_name text,
    proof_of_payment_file_type text CHECK (proof_of_payment_file_type IS NULL OR proof_of_payment_file_type IN ('image/jpeg', 'image/jpg', 'image/png', 'application/pdf')),
    proof_of_payment_file_size bigint CHECK (proof_of_payment_file_size IS NULL OR proof_of_payment_file_size > 0),
    
    -- Admin verification details
    verified_by uuid REFERENCES public.service_provider(service_provider_id), -- Admin who verified
    verification_date timestamp without time zone,
    verification_notes text,
    rejection_reason text,
    
    -- Timestamps
    uploaded_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);

-- =====================================================
-- Step 2: Add indexes for performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_payment_booking_id ON public.payment(booking_id);
CREATE INDEX IF NOT EXISTS idx_payment_client_id ON public.payment(client_id);
CREATE INDEX IF NOT EXISTS idx_payment_status ON public.payment(payment_status);
CREATE INDEX IF NOT EXISTS idx_payment_uploaded_at ON public.payment(uploaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_service_provider ON public.payment(service_provider_id);

-- =====================================================
-- Step 3: Update booking table to reference payment
-- =====================================================
-- Add payment_id column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'booking' 
        AND column_name = 'payment_id'
    ) THEN
        ALTER TABLE public.booking ADD COLUMN payment_id uuid REFERENCES public.payment(payment_id);
    END IF;
END $$;

-- Update payment_status column to use proper check constraint
DO $$ 
BEGIN
    -- Drop existing constraint if it exists
    ALTER TABLE public.booking DROP CONSTRAINT IF EXISTS booking_payment_status_check;
    
    -- Add new constraint with proper values
    ALTER TABLE public.booking ADD CONSTRAINT booking_payment_status_check 
    CHECK (payment_status IN ('unpaid', 'pending_verification', 'paid', 'refunded', 'partial'));
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Set default payment_status if not already set
DO $$ 
BEGIN
    ALTER TABLE public.booking ALTER COLUMN payment_status SET DEFAULT 'unpaid';
EXCEPTION
    WHEN others THEN NULL;
END $$;

-- =====================================================
-- Step 4: Create payment status history table (audit trail)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.payment_status_history (
    history_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id uuid NOT NULL REFERENCES public.payment(payment_id) ON DELETE CASCADE,
    old_status text,
    new_status text NOT NULL,
    changed_by uuid,
    changed_by_type text CHECK (changed_by_type IN ('client', 'service_provider', 'admin', 'system')),
    change_reason text,
    changed_at timestamp without time zone DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payment_history_payment_id ON public.payment_status_history(payment_id);
CREATE INDEX IF NOT EXISTS idx_payment_history_changed_at ON public.payment_status_history(changed_at DESC);

-- =====================================================
-- Step 5: Create trigger to update payment.updated_at
-- =====================================================
CREATE OR REPLACE FUNCTION update_payment_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_payment_timestamp ON public.payment;
CREATE TRIGGER trigger_update_payment_timestamp
    BEFORE UPDATE ON public.payment
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_updated_at();

-- =====================================================
-- Step 6: Create trigger to log payment status changes
-- =====================================================
CREATE OR REPLACE FUNCTION log_payment_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE' AND OLD.payment_status IS DISTINCT FROM NEW.payment_status) THEN
        INSERT INTO public.payment_status_history (
            payment_id,
            old_status,
            new_status,
            changed_by,
            changed_by_type,
            change_reason
        ) VALUES (
            NEW.payment_id,
            OLD.payment_status,
            NEW.payment_status,
            NEW.verified_by,
            CASE 
                WHEN NEW.verified_by IS NOT NULL THEN 'service_provider'
                ELSE 'system'
            END,
            COALESCE(NEW.verification_notes, NEW.rejection_reason)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_log_payment_status ON public.payment;
CREATE TRIGGER trigger_log_payment_status
    AFTER UPDATE ON public.payment
    FOR EACH ROW
    EXECUTE FUNCTION log_payment_status_change();

-- =====================================================
-- Step 7: Create RPC function to submit payment
-- =====================================================
CREATE OR REPLACE FUNCTION submit_payment(
    p_booking_id uuid,
    p_client_id uuid,
    p_payment_amount numeric,
    p_payment_reference text,
    p_file_path text,
    p_file_name text,
    p_file_type text,
    p_file_size bigint
)
RETURNS json AS $$
DECLARE
    v_payment_id uuid;
    v_service_provider_id uuid;
BEGIN
    -- Verify client owns the booking
    IF NOT EXISTS (
        SELECT 1 FROM public.booking 
        WHERE booking_id = p_booking_id AND client_id = p_client_id
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Booking not found or you do not have permission to submit payment for this booking'
        );
    END IF;
    
    -- Get service provider ID from booking
    SELECT service_provider_id INTO v_service_provider_id
    FROM public.booking
    WHERE booking_id = p_booking_id;
    
    -- Create payment record
    INSERT INTO public.payment (
        booking_id,
        client_id,
        service_provider_id,
        payment_amount,
        payment_reference,
        payment_status,
        proof_of_payment_file_path,
        proof_of_payment_file_name,
        proof_of_payment_file_type,
        proof_of_payment_file_size
    ) VALUES (
        p_booking_id,
        p_client_id,
        v_service_provider_id,
        p_payment_amount,
        p_payment_reference,
        'pending',
        p_file_path,
        p_file_name,
        p_file_type,
        p_file_size
    ) RETURNING payment_id INTO v_payment_id;
    
    -- Update booking status
    UPDATE public.booking
    SET 
        payment_id = v_payment_id,
        payment_status = 'pending_verification',
        booking_status = 'payment_submitted'
    WHERE booking_id = p_booking_id;
    
    RETURN json_build_object(
        'success', true,
        'payment_id', v_payment_id,
        'message', 'Payment submitted successfully for verification'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Step 8: Create RPC function to get pending payments (for admin)
-- =====================================================
CREATE OR REPLACE FUNCTION get_pending_payments()
RETURNS TABLE (
    payment_id uuid,
    booking_id uuid,
    client_id uuid,
    client_name text,
    client_surname text,
    client_email text,
    client_contact text,
    service_provider_id uuid,
    payment_amount numeric,
    payment_reference text,
    payment_status text,
    proof_of_payment_file_path text,
    proof_of_payment_file_name text,
    uploaded_at timestamp without time zone,
    event_type text,
    event_date date,
    event_location text,
    booking_date date,
    booking_status text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.payment_id,
        p.booking_id,
        p.client_id,
        c.client_name,
        c.client_surname,
        c.client_email,
        c.client_contact,
        p.service_provider_id,
        p.payment_amount,
        p.payment_reference,
        p.payment_status,
        p.proof_of_payment_file_path,
        p.proof_of_payment_file_name,
        p.uploaded_at,
        e.event_type,
        e.event_date,
        e.event_location,
        b.booking_date,
        b.booking_status
    FROM public.payment p
    INNER JOIN public.booking b ON p.booking_id = b.booking_id
    INNER JOIN public.client c ON p.client_id = c.client_id
    LEFT JOIN public.event e ON b.event_id = e.event_id
    WHERE p.payment_status = 'pending'
    ORDER BY p.uploaded_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Step 9: Create RPC function to verify payment (for admin)
-- =====================================================
CREATE OR REPLACE FUNCTION verify_payment(
    p_payment_id uuid,
    p_admin_id uuid,
    p_verification_notes text
)
RETURNS json AS $$
DECLARE
    v_booking_id uuid;
    v_client_id uuid;
BEGIN
    -- Verify admin is a service provider (admin)
    IF NOT EXISTS (
        SELECT 1 FROM public.service_provider WHERE service_provider_id = p_admin_id
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Only administrators can verify payments'
        );
    END IF;
    
    -- Get booking and client info
    SELECT booking_id, client_id INTO v_booking_id, v_client_id
    FROM public.payment
    WHERE payment_id = p_payment_id;
    
    IF v_booking_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Payment not found'
        );
    END IF;
    
    -- Update payment record
    UPDATE public.payment
    SET 
        payment_status = 'verified',
        verified_by = p_admin_id,
        verification_date = now(),
        verification_notes = p_verification_notes
    WHERE payment_id = p_payment_id;
    
    -- Update booking status
    UPDATE public.booking
    SET 
        payment_status = 'paid',
        booking_status = 'confirmed'
    WHERE booking_id = v_booking_id;
    
    -- Create notification for client
    INSERT INTO public.notification (
        user_id,
        user_type,
        title,
        message,
        type
    ) VALUES (
        v_client_id,
        'client',
        'Payment Verified ✅',
        'Your payment has been verified successfully! Your booking is now confirmed.',
        'success'
    );
    
    RETURN json_build_object(
        'success', true,
        'message', 'Payment verified successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Step 10: Create RPC function to reject payment (for admin)
-- =====================================================
CREATE OR REPLACE FUNCTION reject_payment(
    p_payment_id uuid,
    p_admin_id uuid,
    p_rejection_reason text
)
RETURNS json AS $$
DECLARE
    v_booking_id uuid;
    v_client_id uuid;
BEGIN
    -- Verify admin is a service provider (admin)
    IF NOT EXISTS (
        SELECT 1 FROM public.service_provider WHERE service_provider_id = p_admin_id
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Only administrators can reject payments'
        );
    END IF;
    
    -- Get booking and client info
    SELECT booking_id, client_id INTO v_booking_id, v_client_id
    FROM public.payment
    WHERE payment_id = p_payment_id;
    
    IF v_booking_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Payment not found'
        );
    END IF;
    
    -- Update payment record
    UPDATE public.payment
    SET 
        payment_status = 'rejected',
        verified_by = p_admin_id,
        verification_date = now(),
        rejection_reason = p_rejection_reason
    WHERE payment_id = p_payment_id;
    
    -- Update booking status back to pending payment
    UPDATE public.booking
    SET 
        payment_status = 'unpaid',
        booking_status = 'pending_payment'
    WHERE booking_id = v_booking_id;
    
    -- Create notification for client
    INSERT INTO public.notification (
        user_id,
        user_type,
        title,
        message,
        type
    ) VALUES (
        v_client_id,
        'client',
        'Payment Rejected ⚠️',
        'Your proof of payment was rejected. Reason: ' || p_rejection_reason || '. Please upload a new proof of payment.',
        'warning'
    );
    
    RETURN json_build_object(
        'success', true,
        'message', 'Payment rejected - client will be notified to re-upload'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Step 11: Create RPC function to get client payment history
-- =====================================================
CREATE OR REPLACE FUNCTION get_client_payment_history(
    p_client_id uuid
)
RETURNS TABLE (
    payment_id uuid,
    booking_id uuid,
    payment_amount numeric,
    payment_reference text,
    payment_status text,
    uploaded_at timestamp without time zone,
    verification_date timestamp without time zone,
    verification_notes text,
    rejection_reason text,
    event_type text,
    event_date date
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.payment_id,
        p.booking_id,
        p.payment_amount,
        p.payment_reference,
        p.payment_status,
        p.uploaded_at,
        p.verification_date,
        p.verification_notes,
        p.rejection_reason,
        e.event_type,
        e.event_date
    FROM public.payment p
    INNER JOIN public.booking b ON p.booking_id = b.booking_id
    LEFT JOIN public.event e ON b.event_id = e.event_id
    WHERE p.client_id = p_client_id
    ORDER BY p.uploaded_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Step 12: Verification queries
-- =====================================================
-- Check if payment table was created
SELECT 'Payment table created' as status, COUNT(*) as count FROM public.payment;

-- Check if indexes were created
SELECT 'Indexes on payment table' as status, COUNT(*) as count 
FROM pg_indexes 
WHERE tablename = 'payment';

-- Check if RPC functions were created
SELECT 'RPC functions created' as status, COUNT(*) as count 
FROM pg_proc 
WHERE proname IN ('submit_payment', 'get_pending_payments', 'verify_payment', 'reject_payment', 'get_client_payment_history');

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- Summary:
-- ✅ payment table created with full audit trail
-- ✅ payment_status_history table for tracking all changes
-- ✅ Indexes added for performance
-- ✅ Triggers for auto-updating timestamps and logging
-- ✅ RPC functions for submit, verify, reject, and history
-- ✅ Integration with booking table
-- ✅ Notification system integrated
-- =====================================================






