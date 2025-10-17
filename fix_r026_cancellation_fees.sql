-- fix_r026_cancellation_fees.sql
-- R026: Implement cancellation fee formula and integrate with bookings module

-- =====================================================
-- 1. Create cancellation_policy table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.cancellation_policy (
    cancellation_policy_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_name text NOT NULL,
    policy_description text,
    days_before_event integer NOT NULL,
    cancellation_fee_percentage numeric NOT NULL CHECK (cancellation_fee_percentage >= 0 AND cancellation_fee_percentage <= 100),
    refund_percentage numeric NOT NULL CHECK (refund_percentage >= 0 AND refund_percentage <= 100),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT check_percentages_sum CHECK (cancellation_fee_percentage + refund_percentage = 100)
);

-- Insert default cancellation policies
INSERT INTO public.cancellation_policy (policy_name, policy_description, days_before_event, cancellation_fee_percentage, refund_percentage)
VALUES
    ('30+ Days Before Event', 'Cancellation more than 30 days before event', 30, 5, 95),
    ('14-29 Days Before Event', 'Cancellation 14-29 days before event', 14, 15, 85),
    ('7-13 Days Before Event', 'Cancellation 7-13 days before event', 7, 30, 70),
    ('3-6 Days Before Event', 'Cancellation 3-6 days before event', 3, 50, 50),
    ('0-2 Days Before Event', 'Cancellation 0-2 days before event', 0, 80, 20),
    ('Same Day Cancellation', 'Cancellation on the day of event', 0, 100, 0)
ON CONFLICT DO NOTHING;

-- =====================================================
-- 2. Add cancellation fee columns to booking table
-- =====================================================
ALTER TABLE public.booking 
ADD COLUMN IF NOT EXISTS cancellation_fee_amount numeric,
ADD COLUMN IF NOT EXISTS cancellation_refund_amount numeric,
ADD COLUMN IF NOT EXISTS cancellation_policy_id uuid REFERENCES public.cancellation_policy(cancellation_policy_id),
ADD COLUMN IF NOT EXISTS cancellation_fee_calculated_at timestamp with time zone;

-- =====================================================
-- 3. Create function to calculate cancellation fee
-- =====================================================
CREATE OR REPLACE FUNCTION public.calculate_cancellation_fee(
    p_booking_id uuid,
    p_cancellation_date timestamp with time zone DEFAULT now()
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_booking RECORD;
    v_event_date date;
    v_days_until_event integer;
    v_booking_amount numeric;
    v_policy RECORD;
    v_cancellation_fee numeric;
    v_refund_amount numeric;
BEGIN
    -- Get booking details
    SELECT 
        b.booking_id,
        b.booking_total_price,
        b.booking_status,
        e.event_date,
        p.payment_amount
    INTO v_booking
    FROM public.booking b
    LEFT JOIN public.event e ON b.event_id = e.event_id
    LEFT JOIN public.payment p ON b.booking_id = p.booking_id AND p.payment_status = 'verified'
    WHERE b.booking_id = p_booking_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Booking not found.');
    END IF;

    -- Check if booking is already cancelled
    IF v_booking.booking_status = 'cancelled' THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Booking is already cancelled.');
    END IF;

    -- Get event date
    v_event_date := v_booking.event_date;
    
    IF v_event_date IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Event date not found. Cannot calculate cancellation fee.');
    END IF;

    -- Calculate days until event
    v_days_until_event := v_event_date - p_cancellation_date::date;

    -- If event has already passed, no refund
    IF v_days_until_event < 0 THEN
        RETURN jsonb_build_object(
            'success', TRUE,
            'days_until_event', v_days_until_event,
            'cancellation_fee_percentage', 100,
            'cancellation_fee_amount', COALESCE(v_booking.payment_amount, v_booking.booking_total_price, 0),
            'refund_percentage', 0,
            'refund_amount', 0,
            'policy_name', 'Event Already Passed',
            'message', 'No refund available for cancellations after the event date.'
        );
    END IF;

    -- Determine booking amount (use payment amount if paid, otherwise booking total)
    v_booking_amount := COALESCE(v_booking.payment_amount, v_booking.booking_total_price, 0);

    -- Get applicable cancellation policy based on days until event
    SELECT * INTO v_policy
    FROM public.cancellation_policy
    WHERE days_before_event <= v_days_until_event
    AND is_active = true
    ORDER BY days_before_event DESC
    LIMIT 1;

    -- If no policy found, use the strictest policy (0 days)
    IF NOT FOUND THEN
        SELECT * INTO v_policy
        FROM public.cancellation_policy
        WHERE days_before_event = 0
        AND is_active = true
        LIMIT 1;
    END IF;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'No cancellation policy found.');
    END IF;

    -- Calculate cancellation fee and refund amount
    v_cancellation_fee := ROUND((v_booking_amount * v_policy.cancellation_fee_percentage / 100), 2);
    v_refund_amount := ROUND((v_booking_amount * v_policy.refund_percentage / 100), 2);

    -- Ensure amounts add up correctly (due to rounding)
    IF (v_cancellation_fee + v_refund_amount) > v_booking_amount THEN
        v_refund_amount := v_booking_amount - v_cancellation_fee;
    ELSIF (v_cancellation_fee + v_refund_amount) < v_booking_amount THEN
        v_refund_amount := v_booking_amount - v_cancellation_fee;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'booking_id', p_booking_id,
        'event_date', v_event_date,
        'cancellation_date', p_cancellation_date::date,
        'days_until_event', v_days_until_event,
        'booking_amount', v_booking_amount,
        'policy_id', v_policy.cancellation_policy_id,
        'policy_name', v_policy.policy_name,
        'cancellation_fee_percentage', v_policy.cancellation_fee_percentage,
        'cancellation_fee_amount', v_cancellation_fee,
        'refund_percentage', v_policy.refund_percentage,
        'refund_amount', v_refund_amount,
        'message', 'Cancellation fee calculated successfully.'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

-- =====================================================
-- 4. Update client_cancel_booking to include fee calculation
-- =====================================================
CREATE OR REPLACE FUNCTION public.client_cancel_booking(
    p_booking_id uuid,
    p_client_id uuid,
    p_cancellation_reason text DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_booking RECORD;
    v_fee_calculation jsonb;
    v_cancellation_fee numeric;
    v_refund_amount numeric;
    v_policy_id uuid;
BEGIN
    -- Check if the client owns this booking
    IF NOT EXISTS (
        SELECT 1 FROM public.booking 
        WHERE booking_id = p_booking_id 
        AND client_id = p_client_id
    ) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Unauthorized: Client does not own this booking.');
    END IF;

    -- Get booking details
    SELECT * INTO v_booking FROM public.booking WHERE booking_id = p_booking_id;

    -- Check if booking can be cancelled
    IF v_booking.booking_status = 'cancelled' THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Booking is already cancelled.');
    END IF;

    IF v_booking.booking_status = 'completed' THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Completed bookings cannot be cancelled.');
    END IF;

    -- Calculate cancellation fee
    v_fee_calculation := public.calculate_cancellation_fee(p_booking_id);

    IF NOT (v_fee_calculation->>'success')::boolean THEN
        RETURN v_fee_calculation; -- Return error from fee calculation
    END IF;

    -- Extract fee details
    v_cancellation_fee := (v_fee_calculation->>'cancellation_fee_amount')::numeric;
    v_refund_amount := (v_fee_calculation->>'refund_amount')::numeric;
    v_policy_id := (v_fee_calculation->>'policy_id')::uuid;

    -- Update booking status to cancelled and store fee information
    UPDATE public.booking
    SET
        booking_status = 'cancelled',
        cancellation_fee_amount = v_cancellation_fee,
        cancellation_refund_amount = v_refund_amount,
        cancellation_policy_id = v_policy_id,
        cancellation_fee_calculated_at = now(),
        updated_at = now()
    WHERE booking_id = p_booking_id;

    -- If there's a payment, create a refund request
    IF EXISTS (SELECT 1 FROM public.payment WHERE booking_id = p_booking_id AND payment_status = 'verified') THEN
        -- Insert refund request if payment exists
        INSERT INTO public.refund_request (
            payment_id,
            booking_id,
            client_id,
            refund_amount,
            refund_reason,
            requested_by
        )
        SELECT
            payment_id,
            p_booking_id,
            p_client_id,
            v_refund_amount,
            COALESCE(p_cancellation_reason, 'Client requested cancellation') || 
            ' (Cancellation Fee: R' || v_cancellation_fee || ', Refund: R' || v_refund_amount || ')',
            p_client_id
        FROM public.payment
        WHERE booking_id = p_booking_id
        AND payment_status = 'verified'
        LIMIT 1;
    END IF;

    -- Cancel associated quotation if exists
    IF v_booking.quotation_id IS NOT NULL THEN
        UPDATE public.quotation
        SET
            quotation_status = 'cancelled',
            updated_at = now()
        WHERE quotation_id = v_booking.quotation_id;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', 'Booking cancelled successfully.',
        'booking_id', p_booking_id,
        'cancellation_details', v_fee_calculation
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

-- =====================================================
-- 5. Update service_provider_cancel_booking to include fee calculation
-- =====================================================
CREATE OR REPLACE FUNCTION public.service_provider_cancel_booking(
    p_booking_id uuid,
    p_service_provider_id uuid,
    p_cancellation_reason text DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_booking RECORD;
    v_fee_calculation jsonb;
    v_cancellation_fee numeric;
    v_refund_amount numeric;
    v_policy_id uuid;
BEGIN
    -- Check if the service provider is associated with this booking
    IF NOT EXISTS (
        SELECT 1 FROM public.booking 
        WHERE booking_id = p_booking_id 
        AND service_provider_id = p_service_provider_id
    ) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Unauthorized: Service provider is not associated with this booking.');
    END IF;

    -- Get booking details
    SELECT * INTO v_booking FROM public.booking WHERE booking_id = p_booking_id;

    -- Check if booking can be cancelled
    IF v_booking.booking_status = 'cancelled' THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Booking is already cancelled.');
    END IF;

    IF v_booking.booking_status = 'completed' THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Completed bookings cannot be cancelled.');
    END IF;

    -- For service provider cancellations, typically offer full refund (no fee) as goodwill
    -- This is a business decision - adjust as needed
    v_cancellation_fee := 0;
    v_refund_amount := COALESCE(v_booking.booking_total_price, 0);

    -- Update booking status to cancelled
    UPDATE public.booking
    SET
        booking_status = 'cancelled',
        cancellation_fee_amount = v_cancellation_fee,
        cancellation_refund_amount = v_refund_amount,
        cancellation_fee_calculated_at = now(),
        updated_at = now()
    WHERE booking_id = p_booking_id;

    -- If there's a payment, create a full refund request
    IF EXISTS (SELECT 1 FROM public.payment WHERE booking_id = p_booking_id AND payment_status = 'verified') THEN
        INSERT INTO public.refund_request (
            payment_id,
            booking_id,
            client_id,
            service_provider_id,
            refund_amount,
            refund_reason,
            requested_by
        )
        SELECT
            p.payment_id,
            p_booking_id,
            v_booking.client_id,
            p_service_provider_id,
            v_refund_amount,
            COALESCE(p_cancellation_reason, 'Service provider cancelled booking') || 
            ' (Full Refund: R' || v_refund_amount || ' - No cancellation fee)',
            NULL -- SP cancellation, no client request
        FROM public.payment p
        WHERE p.booking_id = p_booking_id
        AND p.payment_status = 'verified'
        LIMIT 1;
    END IF;

    -- Cancel associated quotation if exists
    IF v_booking.quotation_id IS NOT NULL THEN
        UPDATE public.quotation
        SET
            quotation_status = 'cancelled',
            updated_at = now()
        WHERE quotation_id = v_booking.quotation_id;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', 'Booking cancelled by service provider. Full refund will be processed.',
        'booking_id', p_booking_id,
        'cancellation_fee', v_cancellation_fee,
        'refund_amount', v_refund_amount
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

-- =====================================================
-- 6. Create RPC function to get cancellation fee preview
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_cancellation_fee_preview(
    p_booking_id uuid,
    p_preview_date timestamp with time zone DEFAULT now()
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN public.calculate_cancellation_fee(p_booking_id, p_preview_date);
END;
$$;

-- =====================================================
-- 7. Create view for cancellation policies
-- =====================================================
CREATE OR REPLACE VIEW public.active_cancellation_policies AS
SELECT
    cancellation_policy_id,
    policy_name,
    policy_description,
    days_before_event,
    cancellation_fee_percentage,
    refund_percentage,
    created_at,
    updated_at
FROM
    public.cancellation_policy
WHERE
    is_active = true
ORDER BY
    days_before_event DESC;

-- =====================================================
-- 8. Verification queries
-- =====================================================

-- Check that cancellation_policy table was created
SELECT 
    'Cancellation policy table' as status,
    COUNT(*) as policy_count
FROM public.cancellation_policy;

-- Check cancellation fee columns in booking table
SELECT 
    'Booking table cancellation columns' as status,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'booking' 
AND table_schema = 'public'
AND column_name LIKE '%cancel%'
ORDER BY column_name;

-- Check RPC functions exist
SELECT 
    'Cancellation RPC Functions' as status,
    COUNT(*) as function_count
FROM pg_proc 
WHERE proname IN ('calculate_cancellation_fee', 'get_cancellation_fee_preview')
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- Display cancellation policies
SELECT
    policy_name,
    days_before_event,
    cancellation_fee_percentage || '%' as cancellation_fee,
    refund_percentage || '%' as refund
FROM public.cancellation_policy
WHERE is_active = true
ORDER BY days_before_event DESC;





