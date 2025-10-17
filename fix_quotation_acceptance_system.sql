-- fix_quotation_acceptance_system.sql
-- Create the missing quotation acceptance and booking creation system

-- =====================================================
-- 1. Create RPC function to accept quotations and create bookings
-- =====================================================

CREATE OR REPLACE FUNCTION accept_quotations_and_create_bookings(
    p_client_id uuid,
    p_accepted_quotations jsonb
) RETURNS jsonb AS $$
DECLARE
    quotation_record jsonb;
    quotation_id uuid;
    service_provider_id uuid;
    service_id uuid;
    quotation_price numeric;
    booking_id uuid;
    event_id uuid;
    booking_date date;
    booking_start_time time;
    booking_end_time time;
    booking_location text;
    total_amount numeric := 0;
    created_bookings jsonb := '[]';
    result jsonb;
BEGIN
    -- Validate input
    IF p_client_id IS NULL OR p_accepted_quotations IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Missing required parameters'
        );
    END IF;

    -- Get event details from localStorage data (we'll need to pass this from frontend)
    -- For now, we'll use a default event or get it from the first quotation's job cart
    SELECT 
        e.event_id,
        e.event_date,
        e.event_start_time,
        e.event_end_time,
        e.event_location
    INTO 
        event_id,
        booking_date,
        booking_start_time,
        booking_end_time,
        booking_location
    FROM quotation q
    JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
    JOIN event e ON jc.event_id = e.event_id
    WHERE q.quotation_id = (p_accepted_quotations->0->>'quotation_id')::uuid
    LIMIT 1;

    IF event_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Could not find event details'
        );
    END IF;

    -- Process each accepted quotation
    FOR quotation_record IN SELECT * FROM jsonb_array_elements(p_accepted_quotations)
    LOOP
        quotation_id := (quotation_record->>'quotation_id')::uuid;
        
        -- Get quotation details
        SELECT 
            q.service_provider_id,
            q.service_id,
            q.quotation_price
        INTO 
            service_provider_id,
            service_id,
            quotation_price
        FROM quotation q
        WHERE q.quotation_id = quotation_id
        AND q.quotation_status = 'pending';

        IF service_provider_id IS NULL THEN
            CONTINUE; -- Skip invalid quotations
        END IF;

        -- Update quotation status to accepted
        UPDATE quotation 
        SET quotation_status = 'accepted'
        WHERE quotation_id = quotation_id;

        -- Create booking
        INSERT INTO booking (
            booking_date,
            booking_status,
            booking_location,
            booking_total_price,
            client_id,
            event_id,
            quotation_id,
            service_provider_id,
            payment_status
        ) VALUES (
            booking_date,
            'confirmed',
            booking_location,
            quotation_price,
            p_client_id,
            event_id,
            quotation_id,
            service_provider_id,
            'unpaid'
        ) RETURNING booking_id INTO booking_id;

        -- Add to total amount
        total_amount := total_amount + quotation_price;

        -- Add to created bookings array
        created_bookings := created_bookings || jsonb_build_object(
            'booking_id', booking_id,
            'quotation_id', quotation_id,
            'service_provider_id', service_provider_id,
            'amount', quotation_price
        );

    END LOOP;

    -- Update the booking total price with the sum
    UPDATE booking 
    SET booking_total_price = total_amount
    WHERE client_id = p_client_id 
    AND event_id = event_id
    AND booking_status = 'confirmed';

    -- Return success result
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Quotations accepted and bookings created successfully',
        'total_amount', total_amount,
        'bookings_created', created_bookings
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 2. Create RPC function to get client's pending quotations
-- =====================================================

CREATE OR REPLACE FUNCTION get_client_pending_quotations(p_client_id uuid)
RETURNS jsonb AS $$
DECLARE
    result jsonb;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'quotation_id', q.quotation_id,
            'quotation_price', q.quotation_price,
            'quotation_details', q.quotation_details,
            'quotation_status', q.quotation_status,
            'service_id', q.service_id,
            'service_provider_id', q.service_provider_id,
            'service_provider_name', sp.service_provider_name,
            'service_provider_surname', sp.service_provider_surname,
            'service_name', s.service_name,
            'service_type', s.service_type,
            'event_date', e.event_date,
            'event_location', e.event_location
        )
    ) INTO result
    FROM quotation q
    JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
    JOIN service s ON q.service_id = s.service_id
    JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
    JOIN event e ON jc.event_id = e.event_id
    WHERE jc.client_id = p_client_id
    AND q.quotation_status = 'pending';

    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 3. Create RPC function to get client's confirmed bookings
-- =====================================================

CREATE OR REPLACE FUNCTION get_client_confirmed_bookings(p_client_id uuid)
RETURNS jsonb AS $$
DECLARE
    result jsonb;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'booking_id', b.booking_id,
            'booking_date', b.booking_date,
            'booking_status', b.booking_status,
            'booking_location', b.booking_location,
            'booking_total_price', b.booking_total_price,
            'payment_status', b.payment_status,
            'quotation_id', b.quotation_id,
            'service_provider_id', b.service_provider_id,
            'service_provider_name', sp.service_provider_name,
            'service_provider_surname', sp.service_provider_surname,
            'event_type', e.event_type,
            'event_start_time', e.event_start_time,
            'event_end_time', e.event_end_time
        )
    ) INTO result
    FROM booking b
    JOIN quotation q ON b.quotation_id = q.quotation_id
    JOIN service_provider sp ON b.service_provider_id = sp.service_provider_id
    JOIN event e ON b.event_id = e.event_id
    WHERE b.client_id = p_client_id
    AND b.booking_status = 'confirmed';

    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 4. Create RPC function to create payment record when payment is uploaded
-- =====================================================

CREATE OR REPLACE FUNCTION create_payment_record(
    p_booking_id uuid,
    p_client_id uuid,
    p_payment_amount numeric,
    p_proof_of_payment_file_path text,
    p_proof_of_payment_file_name text,
    p_proof_of_payment_file_type text,
    p_proof_of_payment_file_size bigint
) RETURNS jsonb AS $$
DECLARE
    payment_id uuid;
    service_provider_id uuid;
    result jsonb;
BEGIN
    -- Get service provider from booking
    SELECT b.service_provider_id INTO service_provider_id
    FROM booking b
    WHERE b.booking_id = p_booking_id
    AND b.client_id = p_client_id;

    IF service_provider_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Booking not found or access denied'
        );
    END IF;

    -- Create payment record
    INSERT INTO payment (
        booking_id,
        client_id,
        service_provider_id,
        payment_amount,
        payment_method,
        payment_status,
        proof_of_payment_file_path,
        proof_of_payment_file_name,
        proof_of_payment_file_type,
        proof_of_payment_file_size
    ) VALUES (
        p_booking_id,
        p_client_id,
        service_provider_id,
        p_payment_amount,
        'bank_transfer',
        'pending_verification',
        p_proof_of_payment_file_path,
        p_proof_of_payment_file_name,
        p_proof_of_payment_file_type,
        p_proof_of_payment_file_size
    ) RETURNING payment_id INTO payment_id;

    -- Update booking payment status
    UPDATE booking 
    SET payment_status = 'pending_verification'
    WHERE booking_id = p_booking_id;

    -- Return success result
    RETURN jsonb_build_object(
        'success', true,
        'payment_id', payment_id,
        'message', 'Payment record created successfully'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. Grant permissions
-- =====================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION accept_quotations_and_create_bookings(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION get_client_pending_quotations(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_client_confirmed_bookings(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION create_payment_record(uuid, uuid, numeric, text, text, text, bigint) TO authenticated;

-- =====================================================
-- 6. Test the functions (optional - remove in production)
-- =====================================================

-- You can test these functions like this:
-- SELECT accept_quotations_and_create_bookings(
--     'your-client-id'::uuid,
--     '[{"quotation_id": "your-quotation-id"}]'::jsonb
-- );

COMMENT ON FUNCTION accept_quotations_and_create_bookings IS 'Accepts selected quotations and creates confirmed bookings';
COMMENT ON FUNCTION get_client_pending_quotations IS 'Gets all pending quotations for a client';
COMMENT ON FUNCTION get_client_confirmed_bookings IS 'Gets all confirmed bookings for a client';
COMMENT ON FUNCTION create_payment_record IS 'Creates a payment record when client uploads proof of payment';





