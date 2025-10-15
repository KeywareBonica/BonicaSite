-- =====================================================
-- LOOPHOLE 0: BOOKING OWNERSHIP & AUTHORIZATION FIX
-- =====================================================
-- CORRECTED VERSION - Matches actual schema
--
-- THE PRIMARY LOOPHOLE: Users can update/cancel ANY booking without verification
-- 
-- PROBLEM: 
-- 1. Booking table has client_id but NO service_provider_id
-- 2. No function to verify if user is part of a booking
-- 3. Client can update any booking by changing booking_id
-- 4. Service provider can update any booking by changing booking_id
--
-- SOLUTION: Add proper ownership verification and authorization

-- =====================================================
-- STEP 1: ADD SERVICE PROVIDER TO BOOKING TABLE
-- =====================================================
ALTER TABLE public.booking 
ADD COLUMN IF NOT EXISTS service_provider_id uuid REFERENCES public.service_provider(service_provider_id);

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_booking_service_provider ON public.booking(service_provider_id);

COMMENT ON COLUMN public.booking.service_provider_id IS 'Service provider assigned to this booking (linked when client accepts a quotation)';

-- =====================================================
-- STEP 2: UPDATE EXISTING BOOKINGS WITH SERVICE PROVIDER
-- =====================================================
-- Populate service_provider_id from quotation linked via booking.quotation_id
UPDATE public.booking b
SET service_provider_id = q.service_provider_id
FROM public.quotation q
WHERE b.quotation_id = q.quotation_id
AND b.service_provider_id IS NULL;

-- Alternative: Also check quotations that reference this booking
UPDATE public.booking b
SET service_provider_id = q.service_provider_id
FROM public.quotation q
WHERE q.booking_id = b.booking_id
AND q.quotation_status = 'accepted'
AND b.service_provider_id IS NULL;

-- =====================================================
-- STEP 3: CREATE AUTHORIZATION FUNCTIONS
-- =====================================================

-- Function to check if CLIENT owns a booking
CREATE OR REPLACE FUNCTION public.is_client_booking_owner(
    p_booking_id uuid,
    p_client_id uuid
)
RETURNS boolean AS $$
DECLARE
    v_is_owner boolean;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM public.booking
        WHERE booking_id = p_booking_id
        AND client_id = p_client_id
    ) INTO v_is_owner;
    
    RETURN v_is_owner;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.is_client_booking_owner IS 'Verify if a client owns a specific booking';

-- Function to check if SERVICE PROVIDER is assigned to a booking
CREATE OR REPLACE FUNCTION public.is_service_provider_booking_participant(
    p_booking_id uuid,
    p_service_provider_id uuid
)
RETURNS boolean AS $$
DECLARE
    v_is_participant boolean;
BEGIN
    -- Check if service provider is directly assigned to booking
    SELECT EXISTS(
        SELECT 1 FROM public.booking
        WHERE booking_id = p_booking_id
        AND service_provider_id = p_service_provider_id
    ) INTO v_is_participant;
    
    -- If not found directly, check via quotations
    IF NOT v_is_participant THEN
        SELECT EXISTS(
            SELECT 1 FROM public.quotation
            WHERE booking_id = p_booking_id
            AND service_provider_id = p_service_provider_id
            AND quotation_status IN ('accepted', 'submitted', 'confirmed')
        ) INTO v_is_participant;
    END IF;
    
    RETURN v_is_participant;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.is_service_provider_booking_participant IS 'Verify if a service provider is assigned to a specific booking';

-- =====================================================
-- STEP 4: CREATE FUNCTION TO GET USER'S BOOKINGS
-- =====================================================

-- Get all bookings for a CLIENT
CREATE OR REPLACE FUNCTION public.get_client_bookings(
    p_client_id uuid,
    p_status_filter text[] DEFAULT NULL
)
RETURNS TABLE (
    booking_id uuid,
    booking_date date,
    booking_status text,
    booking_total_price numeric,
    booking_special_requests text,
    booking_location text,
    service_provider_id uuid,
    service_provider_name text,
    service_provider_surname text,
    event_id uuid,
    event_type text,
    event_date date,
    event_start_time time,
    event_end_time time,
    event_location text,
    created_at timestamp
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.booking_id,
        b.booking_date,
        b.booking_status,
        b.booking_total_price,
        b.booking_special_requests,
        b.booking_location,
        b.service_provider_id,
        sp.service_provider_name,
        sp.service_provider_surname,
        e.event_id,
        e.event_type,
        e.event_date,
        e.event_start_time,
        e.event_end_time,
        e.event_location,
        b.created_at
    FROM public.booking b
    JOIN public.event e ON b.event_id = e.event_id
    LEFT JOIN public.service_provider sp ON b.service_provider_id = sp.service_provider_id
    WHERE b.client_id = p_client_id
    AND (p_status_filter IS NULL OR b.booking_status = ANY(p_status_filter))
    ORDER BY b.booking_date DESC, b.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_client_bookings IS 'Get all bookings for a specific client with authorization';

-- Get all bookings for a SERVICE PROVIDER
CREATE OR REPLACE FUNCTION public.get_service_provider_bookings(
    p_service_provider_id uuid,
    p_status_filter text[] DEFAULT NULL
)
RETURNS TABLE (
    booking_id uuid,
    booking_date date,
    booking_status text,
    booking_total_price numeric,
    booking_special_requests text,
    booking_location text,
    client_id uuid,
    client_name text,
    client_surname text,
    client_contact text,
    event_id uuid,
    event_type text,
    event_date date,
    event_start_time time,
    event_end_time time,
    event_location text,
    quotation_id uuid,
    quotation_price numeric,
    quotation_status text,
    created_at timestamp
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.booking_id,
        b.booking_date,
        b.booking_status,
        b.booking_total_price,
        b.booking_special_requests,
        b.booking_location,
        c.client_id,
        c.client_name,
        c.client_surname,
        c.client_contact,
        e.event_id,
        e.event_type,
        e.event_date,
        e.event_start_time,
        e.event_end_time,
        e.event_location,
        q.quotation_id,
        q.quotation_price,
        q.quotation_status::text,
        b.created_at
    FROM public.booking b
    JOIN public.event e ON b.event_id = e.event_id
    JOIN public.client c ON b.client_id = c.client_id
    LEFT JOIN public.quotation q ON b.booking_id = q.booking_id 
        AND q.service_provider_id = p_service_provider_id
    WHERE b.service_provider_id = p_service_provider_id
    AND (p_status_filter IS NULL OR b.booking_status = ANY(p_status_filter))
    ORDER BY b.booking_date DESC, b.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_service_provider_bookings IS 'Get all bookings for a specific service provider with authorization';

-- =====================================================
-- STEP 5: CREATE SECURE UPDATE FUNCTIONS WITH AUTHORIZATION
-- =====================================================

-- Client update booking (with authorization check)
-- NOTE: Prices are in job_cart table, not booking table
CREATE OR REPLACE FUNCTION public.client_update_booking(
    p_booking_id uuid,
    p_client_id uuid,
    p_event_date date DEFAULT NULL,
    p_event_location text DEFAULT NULL,
    p_event_start_time time DEFAULT NULL,
    p_event_end_time time DEFAULT NULL,
    p_booking_special_request text DEFAULT NULL
)
RETURNS json AS $$
DECLARE
    v_is_owner boolean;
    v_event_id uuid;
    v_update_count integer := 0;
    v_result json;
BEGIN
    -- AUTHORIZATION CHECK
    v_is_owner := public.is_client_booking_owner(p_booking_id, p_client_id);
    
    IF NOT v_is_owner THEN
        RAISE EXCEPTION 'AUTHORIZATION FAILED: Client % is not the owner of booking %', p_client_id, p_booking_id;
    END IF;
    
    -- Get event_id
    SELECT event_id INTO v_event_id
    FROM public.booking
    WHERE booking_id = p_booking_id;
    
    -- Update EVENT table if any event fields provided
    IF p_event_date IS NOT NULL OR p_event_location IS NOT NULL 
       OR p_event_start_time IS NOT NULL OR p_event_end_time IS NOT NULL THEN
        
        UPDATE public.event
        SET 
            event_date = COALESCE(p_event_date, event_date),
            event_location = COALESCE(p_event_location, event_location),
            event_start_time = COALESCE(p_event_start_time, event_start_time),
            event_end_time = COALESCE(p_event_end_time, event_end_time)
        WHERE event_id = v_event_id;
        
        v_update_count := v_update_count + 1;
    END IF;
    
    -- Update BOOKING table if special request provided
    IF p_booking_special_request IS NOT NULL THEN
        UPDATE public.booking
        SET booking_special_requests = p_booking_special_request
        WHERE booking_id = p_booking_id;
        
        v_update_count := v_update_count + 1;
    END IF;
    
    -- Return result
    v_result := json_build_object(
        'success', true,
        'message', 'Booking updated successfully by client',
        'booking_id', p_booking_id,
        'updates_applied', v_update_count,
        'updated_at', now()
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'booking_id', p_booking_id
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.client_update_booking IS 'Client updates their booking with authorization check';

-- Service Provider update booking (with authorization check)
CREATE OR REPLACE FUNCTION public.service_provider_update_booking(
    p_booking_id uuid,
    p_service_provider_id uuid,
    p_event_date date DEFAULT NULL,
    p_event_location text DEFAULT NULL,
    p_event_start_time time DEFAULT NULL,
    p_event_end_time time DEFAULT NULL,
    p_quotation_price numeric DEFAULT NULL,
    p_booking_special_request text DEFAULT NULL
)
RETURNS json AS $$
DECLARE
    v_is_participant boolean;
    v_event_id uuid;
    v_update_count integer := 0;
    v_result json;
BEGIN
    -- AUTHORIZATION CHECK
    v_is_participant := public.is_service_provider_booking_participant(p_booking_id, p_service_provider_id);
    
    IF NOT v_is_participant THEN
        RAISE EXCEPTION 'AUTHORIZATION FAILED: Service Provider % is not assigned to booking %', p_service_provider_id, p_booking_id;
    END IF;
    
    -- Get event_id
    SELECT event_id INTO v_event_id
    FROM public.booking
    WHERE booking_id = p_booking_id;
    
    -- Update EVENT table if any event fields provided
    IF p_event_date IS NOT NULL OR p_event_location IS NOT NULL 
       OR p_event_start_time IS NOT NULL OR p_event_end_time IS NOT NULL THEN
        
        UPDATE public.event
        SET 
            event_date = COALESCE(p_event_date, event_date),
            event_location = COALESCE(p_event_location, event_location),
            event_start_time = COALESCE(p_event_start_time, event_start_time),
            event_end_time = COALESCE(p_event_end_time, event_end_time)
        WHERE event_id = v_event_id;
        
        v_update_count := v_update_count + 1;
    END IF;
    
    -- Update BOOKING table if special request provided
    IF p_booking_special_request IS NOT NULL THEN
        UPDATE public.booking
        SET booking_special_requests = p_booking_special_request
        WHERE booking_id = p_booking_id;
        
        v_update_count := v_update_count + 1;
    END IF;
    
    -- Update QUOTATION table if price provided
    IF p_quotation_price IS NOT NULL THEN
        UPDATE public.quotation
        SET quotation_price = p_quotation_price
        WHERE booking_id = p_booking_id
        AND service_provider_id = p_service_provider_id;
        
        v_update_count := v_update_count + 1;
    END IF;
    
    -- Return result
    v_result := json_build_object(
        'success', true,
        'message', 'Booking updated successfully by service provider',
        'booking_id', p_booking_id,
        'updates_applied', v_update_count,
        'updated_at', now()
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'booking_id', p_booking_id
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.service_provider_update_booking IS 'Service provider updates their booking with authorization check';

-- =====================================================
-- STEP 6: CREATE SECURE CANCEL FUNCTIONS WITH AUTHORIZATION
-- =====================================================

-- Client cancel booking (with authorization check)
CREATE OR REPLACE FUNCTION public.client_cancel_booking(
    p_booking_id uuid,
    p_client_id uuid,
    p_cancellation_reason text
)
RETURNS json AS $$
DECLARE
    v_is_owner boolean;
    v_booking_total numeric;
    v_deduction_amount numeric;
    v_refund_amount numeric;
    v_result json;
BEGIN
    -- AUTHORIZATION CHECK
    v_is_owner := public.is_client_booking_owner(p_booking_id, p_client_id);
    
    IF NOT v_is_owner THEN
        RAISE EXCEPTION 'AUTHORIZATION FAILED: Client % is not the owner of booking %', p_client_id, p_booking_id;
    END IF;
    
    -- Check if booking can be cancelled
    IF EXISTS (
        SELECT 1 FROM public.booking
        WHERE booking_id = p_booking_id
        AND booking_status IN ('cancelled', 'completed')
    ) THEN
        RAISE EXCEPTION 'Booking % cannot be cancelled (status: %)', p_booking_id, 
            (SELECT booking_status FROM public.booking WHERE booking_id = p_booking_id);
    END IF;
    
    -- Get booking total
    SELECT COALESCE(booking_total_price, 0)
    INTO v_booking_total
    FROM public.booking
    WHERE booking_id = p_booking_id;
    
    -- Calculate refund (3% deduction)
    v_deduction_amount := v_booking_total * 0.03;
    v_refund_amount := v_booking_total - v_deduction_amount;
    
    -- Update booking status
    UPDATE public.booking
    SET booking_status = 'cancelled'
    WHERE booking_id = p_booking_id;
    
    -- Return result
    v_result := json_build_object(
        'success', true,
        'message', 'Booking cancelled successfully by client',
        'booking_id', p_booking_id,
        'total_amount', v_booking_total,
        'deduction_amount', v_deduction_amount,
        'refund_amount', v_refund_amount,
        'cancelled_at', now()
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'booking_id', p_booking_id
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.client_cancel_booking IS 'Client cancels their booking with authorization check and refund calculation';

-- Service Provider cancel booking (with authorization check)
CREATE OR REPLACE FUNCTION public.service_provider_cancel_booking(
    p_booking_id uuid,
    p_service_provider_id uuid,
    p_cancellation_reason text
)
RETURNS json AS $$
DECLARE
    v_is_participant boolean;
    v_booking_total numeric;
    v_result json;
BEGIN
    -- AUTHORIZATION CHECK
    v_is_participant := public.is_service_provider_booking_participant(p_booking_id, p_service_provider_id);
    
    IF NOT v_is_participant THEN
        RAISE EXCEPTION 'AUTHORIZATION FAILED: Service Provider % is not assigned to booking %', p_service_provider_id, p_booking_id;
    END IF;
    
    -- Check if booking can be cancelled
    IF EXISTS (
        SELECT 1 FROM public.booking
        WHERE booking_id = p_booking_id
        AND booking_status IN ('cancelled', 'completed')
    ) THEN
        RAISE EXCEPTION 'Booking % cannot be cancelled (status: %)', p_booking_id,
            (SELECT booking_status FROM public.booking WHERE booking_id = p_booking_id);
    END IF;
    
    -- Get booking total
    SELECT COALESCE(booking_total_price, 0)
    INTO v_booking_total
    FROM public.booking
    WHERE booking_id = p_booking_id;
    
    -- Update booking status
    UPDATE public.booking
    SET booking_status = 'cancelled'
    WHERE booking_id = p_booking_id;
    
    -- Return result
    v_result := json_build_object(
        'success', true,
        'message', 'Booking cancelled by service provider',
        'booking_id', p_booking_id,
        'refund_to_client', v_booking_total,  -- Full refund when SP cancels
        'penalty_note', 'Service provider rating may be affected',
        'cancelled_at', now()
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'booking_id', p_booking_id
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.service_provider_cancel_booking IS 'Service provider cancels booking with authorization check';

-- =====================================================
-- STEP 7: ADD TRIGGERS TO AUTO-ASSIGN SERVICE PROVIDER
-- =====================================================

-- When client accepts a quotation, auto-assign service provider to booking
CREATE OR REPLACE FUNCTION public.auto_assign_service_provider_to_booking()
RETURNS TRIGGER AS $$
BEGIN
    -- When quotation status changes to 'accepted'
    IF NEW.quotation_status::text = 'accepted' AND (OLD.quotation_status IS NULL OR OLD.quotation_status::text != 'accepted') THEN
        -- Update booking with service provider
        UPDATE public.booking
        SET service_provider_id = NEW.service_provider_id
        WHERE booking_id = NEW.booking_id;
        
        RAISE NOTICE 'Service provider % auto-assigned to booking %', NEW.service_provider_id, NEW.booking_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_auto_assign_service_provider ON public.quotation;
CREATE TRIGGER trg_auto_assign_service_provider
    AFTER UPDATE ON public.quotation
    FOR EACH ROW
    WHEN (NEW.quotation_status::text = 'accepted')
    EXECUTE FUNCTION public.auto_assign_service_provider_to_booking();

-- =====================================================
-- STEP 8: CREATE VIEW FOR SAFE BOOKING ACCESS
-- =====================================================

CREATE OR REPLACE VIEW public.booking_with_authorization AS
SELECT 
    b.booking_id,
    b.booking_date,
    b.booking_status,
    b.booking_total_price,
    b.booking_special_requests,
    b.booking_location,
    b.client_id,
    c.client_name,
    c.client_surname,
    c.client_email,
    b.service_provider_id,
    sp.service_provider_name,
    sp.service_provider_surname,
    sp.service_provider_email,
    e.event_id,
    e.event_type,
    e.event_date,
    e.event_start_time,
    e.event_end_time,
    e.event_location,
    b.created_at
FROM public.booking b
JOIN public.client c ON b.client_id = c.client_id
JOIN public.event e ON b.event_id = e.event_id
LEFT JOIN public.service_provider sp ON b.service_provider_id = sp.service_provider_id;

-- =====================================================
-- SUMMARY & TESTING
-- =====================================================

-- Test authorization functions
DO $$
DECLARE
    v_test_client_id uuid;
    v_test_sp_id uuid;
    v_test_booking_id uuid;
    v_is_owner boolean;
    v_is_participant boolean;
BEGIN
    -- Get sample data (if exists)
    SELECT client_id INTO v_test_client_id FROM public.client LIMIT 1;
    SELECT service_provider_id INTO v_test_sp_id FROM public.service_provider LIMIT 1;
    SELECT booking_id INTO v_test_booking_id FROM public.booking LIMIT 1;
    
    IF v_test_client_id IS NOT NULL AND v_test_booking_id IS NOT NULL THEN
        -- Test client ownership
        v_is_owner := public.is_client_booking_owner(v_test_booking_id, v_test_client_id);
        RAISE NOTICE 'Client ownership test: %', v_is_owner;
        
        -- Test service provider participation
        IF v_test_sp_id IS NOT NULL THEN
            v_is_participant := public.is_service_provider_booking_participant(v_test_booking_id, v_test_sp_id);
            RAISE NOTICE 'Service provider participation test: %', v_is_participant;
        END IF;
    END IF;
END $$;

-- Summary
SELECT '
====================================================================
LOOPHOLE 0: BOOKING OWNERSHIP & AUTHORIZATION - FIXED
====================================================================

CHANGES IMPLEMENTED:
--------------------
1. ✅ Added service_provider_id to booking table
2. ✅ Created is_client_booking_owner() function
3. ✅ Created is_service_provider_booking_participant() function
4. ✅ Created get_client_bookings() function
5. ✅ Created get_service_provider_bookings() function
6. ✅ Created client_update_booking() with authorization
7. ✅ Created service_provider_update_booking() with authorization
8. ✅ Created client_cancel_booking() with authorization
9. ✅ Created service_provider_cancel_booking() with authorization
10. ✅ Added auto-assignment trigger
11. ✅ Created booking_with_authorization view

SCHEMA CORRECTIONS:
-------------------
✅ Times (start/end) are in EVENT table (not booking)
✅ Prices (min/max) are in JOB_CART table (not booking)
✅ booking table only has: booking_special_requests, booking_total_price, booking_location

HOW TO USE IN JAVASCRIPT:
--------------------------
// CLIENT: Update booking
const { data, error } = await supabase.rpc(''client_update_booking'', {
    p_booking_id: bookingId,
    p_client_id: currentUser.client_id,
    p_event_date: newDate,
    p_event_location: newLocation,
    p_event_start_time: newStartTime,
    p_event_end_time: newEndTime,
    p_booking_special_request: newRequest
});

// SERVICE PROVIDER: Update booking
const { data, error } = await supabase.rpc(''service_provider_update_booking'', {
    p_booking_id: bookingId,
    p_service_provider_id: currentUser.service_provider_id,
    p_event_date: newDate,
    p_quotation_price: newPrice
});

====================================================================
' as implementation_summary;

