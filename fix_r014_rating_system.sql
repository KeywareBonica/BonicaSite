-- fix_r014_rating_system.sql
-- R014: Implement rating feature and link ratings to completed bookings

-- =====================================================
-- 1. Create rating table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.rating (
    rating_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id uuid NOT NULL REFERENCES public.booking(booking_id),
    client_id uuid NOT NULL REFERENCES public.client(client_id),
    service_provider_id uuid NOT NULL REFERENCES public.service_provider(service_provider_id),
    
    -- Rating scores (1-5 stars)
    overall_rating integer NOT NULL CHECK (overall_rating >= 1 AND overall_rating <= 5),
    quality_rating integer CHECK (quality_rating >= 1 AND quality_rating <= 5),
    professionalism_rating integer CHECK (professionalism_rating >= 1 AND professionalism_rating <= 5),
    communication_rating integer CHECK (communication_rating >= 1 AND communication_rating <= 5),
    value_for_money_rating integer CHECK (value_for_money_rating >= 1 AND value_for_money_rating <= 5),
    
    -- Review text
    review_title text,
    review_text text,
    review_pros text, -- What the client liked
    review_cons text, -- What could be improved
    
    -- Recommendation
    would_recommend boolean DEFAULT true,
    
    -- Service provider response
    service_provider_response text,
    service_provider_response_date timestamp with time zone,
    
    -- Moderation
    is_verified boolean DEFAULT false, -- Admin verified
    is_published boolean DEFAULT true, -- Visible to public
    is_flagged boolean DEFAULT false, -- Flagged for review
    flag_reason text,
    
    -- Helpful votes
    helpful_count integer DEFAULT 0,
    not_helpful_count integer DEFAULT 0,
    
    -- Timestamps
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    
    -- Ensure one rating per booking
    UNIQUE(booking_id, client_id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_rating_booking_id ON public.rating(booking_id);
CREATE INDEX IF NOT EXISTS idx_rating_client_id ON public.rating(client_id);
CREATE INDEX IF NOT EXISTS idx_rating_service_provider_id ON public.rating(service_provider_id);
CREATE INDEX IF NOT EXISTS idx_rating_overall_rating ON public.rating(overall_rating);
CREATE INDEX IF NOT EXISTS idx_rating_created_at ON public.rating(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rating_published ON public.rating(is_published) WHERE is_published = true;

-- =====================================================
-- 2. Add rating fields to service_provider table
-- =====================================================
ALTER TABLE public.service_provider 
ADD COLUMN IF NOT EXISTS average_rating numeric(3,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS total_ratings integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_reviews integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS recommendation_percentage numeric(5,2) DEFAULT 0.00;

-- =====================================================
-- 3. Create RPC function to submit a rating
-- =====================================================
CREATE OR REPLACE FUNCTION public.submit_rating(
    p_booking_id uuid,
    p_client_id uuid,
    p_overall_rating integer,
    p_quality_rating integer DEFAULT NULL,
    p_professionalism_rating integer DEFAULT NULL,
    p_communication_rating integer DEFAULT NULL,
    p_value_for_money_rating integer DEFAULT NULL,
    p_review_title text DEFAULT NULL,
    p_review_text text DEFAULT NULL,
    p_review_pros text DEFAULT NULL,
    p_review_cons text DEFAULT NULL,
    p_would_recommend boolean DEFAULT true
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_booking RECORD;
    v_rating_id uuid;
    v_service_provider_id uuid;
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

    -- Check if booking is completed
    IF v_booking.booking_status != 'completed' THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Only completed bookings can be rated.');
    END IF;

    -- Get service provider ID
    v_service_provider_id := v_booking.service_provider_id;

    IF v_service_provider_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'No service provider associated with this booking.');
    END IF;

    -- Check if rating already exists
    IF EXISTS (SELECT 1 FROM public.rating WHERE booking_id = p_booking_id AND client_id = p_client_id) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'You have already rated this booking. Use update_rating to modify your review.');
    END IF;

    -- Validate rating values
    IF p_overall_rating < 1 OR p_overall_rating > 5 THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Overall rating must be between 1 and 5.');
    END IF;

    -- Insert rating
    INSERT INTO public.rating (
        booking_id,
        client_id,
        service_provider_id,
        overall_rating,
        quality_rating,
        professionalism_rating,
        communication_rating,
        value_for_money_rating,
        review_title,
        review_text,
        review_pros,
        review_cons,
        would_recommend
    ) VALUES (
        p_booking_id,
        p_client_id,
        v_service_provider_id,
        p_overall_rating,
        p_quality_rating,
        p_professionalism_rating,
        p_communication_rating,
        p_value_for_money_rating,
        p_review_title,
        p_review_text,
        p_review_pros,
        p_review_cons,
        p_would_recommend
    )
    RETURNING rating_id INTO v_rating_id;

    -- Update service provider ratings
    PERFORM public.update_service_provider_ratings(v_service_provider_id);

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', 'Rating submitted successfully. Thank you for your feedback!',
        'rating_id', v_rating_id
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

-- =====================================================
-- 4. Create function to update service provider ratings
-- =====================================================
CREATE OR REPLACE FUNCTION public.update_service_provider_ratings(p_service_provider_id uuid)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    v_avg_rating numeric;
    v_total_ratings integer;
    v_total_reviews integer;
    v_recommendation_count integer;
    v_recommendation_percentage numeric;
BEGIN
    -- Calculate average rating
    SELECT
        ROUND(AVG(overall_rating), 2),
        COUNT(*),
        COUNT(*) FILTER (WHERE review_text IS NOT NULL AND review_text != ''),
        COUNT(*) FILTER (WHERE would_recommend = true)
    INTO
        v_avg_rating,
        v_total_ratings,
        v_total_reviews,
        v_recommendation_count
    FROM public.rating
    WHERE service_provider_id = p_service_provider_id
    AND is_published = true;

    -- Calculate recommendation percentage
    IF v_total_ratings > 0 THEN
        v_recommendation_percentage := ROUND((v_recommendation_count::numeric / v_total_ratings::numeric) * 100, 2);
    ELSE
        v_recommendation_percentage := 0;
    END IF;

    -- Update service provider
    UPDATE public.service_provider
    SET
        average_rating = COALESCE(v_avg_rating, 0),
        total_ratings = COALESCE(v_total_ratings, 0),
        total_reviews = COALESCE(v_total_reviews, 0),
        recommendation_percentage = COALESCE(v_recommendation_percentage, 0)
    WHERE service_provider_id = p_service_provider_id;
END;
$$;

-- =====================================================
-- 5. Create RPC function to update a rating
-- =====================================================
CREATE OR REPLACE FUNCTION public.update_rating(
    p_rating_id uuid,
    p_client_id uuid,
    p_overall_rating integer DEFAULT NULL,
    p_quality_rating integer DEFAULT NULL,
    p_professionalism_rating integer DEFAULT NULL,
    p_communication_rating integer DEFAULT NULL,
    p_value_for_money_rating integer DEFAULT NULL,
    p_review_title text DEFAULT NULL,
    p_review_text text DEFAULT NULL,
    p_review_pros text DEFAULT NULL,
    p_review_cons text DEFAULT NULL,
    p_would_recommend boolean DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_rating RECORD;
    v_service_provider_id uuid;
BEGIN
    -- Check if the client owns this rating
    SELECT * INTO v_rating FROM public.rating WHERE rating_id = p_rating_id AND client_id = p_client_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Rating not found or unauthorized.');
    END IF;

    v_service_provider_id := v_rating.service_provider_id;

    -- Update rating (only update provided fields)
    UPDATE public.rating
    SET
        overall_rating = COALESCE(p_overall_rating, overall_rating),
        quality_rating = COALESCE(p_quality_rating, quality_rating),
        professionalism_rating = COALESCE(p_professionalism_rating, professionalism_rating),
        communication_rating = COALESCE(p_communication_rating, communication_rating),
        value_for_money_rating = COALESCE(p_value_for_money_rating, value_for_money_rating),
        review_title = COALESCE(p_review_title, review_title),
        review_text = COALESCE(p_review_text, review_text),
        review_pros = COALESCE(p_review_pros, review_pros),
        review_cons = COALESCE(p_review_cons, review_cons),
        would_recommend = COALESCE(p_would_recommend, would_recommend),
        updated_at = now()
    WHERE rating_id = p_rating_id;

    -- Update service provider ratings
    PERFORM public.update_service_provider_ratings(v_service_provider_id);

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', 'Rating updated successfully.'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', FALSE, 'error', SQLERRM);
END;
$$;

-- =====================================================
-- 6. Create RPC function to get ratings for a service provider
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_service_provider_ratings(p_service_provider_id uuid)
RETURNS SETOF jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT
        jsonb_build_object(
            'rating_id', r.rating_id,
            'overall_rating', r.overall_rating,
            'quality_rating', r.quality_rating,
            'professionalism_rating', r.professionalism_rating,
            'communication_rating', r.communication_rating,
            'value_for_money_rating', r.value_for_money_rating,
            'review_title', r.review_title,
            'review_text', r.review_text,
            'review_pros', r.review_pros,
            'review_cons', r.review_cons,
            'would_recommend', r.would_recommend,
            'helpful_count', r.helpful_count,
            'not_helpful_count', r.not_helpful_count,
            'created_at', r.created_at,
            'service_provider_response', r.service_provider_response,
            'service_provider_response_date', r.service_provider_response_date,
            'client', jsonb_build_object(
                'client_name', c.client_name,
                'client_surname', c.client_surname
            ),
            'booking', jsonb_build_object(
                'booking_id', b.booking_id,
                'event_type', e.event_type,
                'event_date', e.event_date
            )
        )
    FROM
        public.rating r
    JOIN
        public.client c ON r.client_id = c.client_id
    JOIN
        public.booking b ON r.booking_id = b.booking_id
    LEFT JOIN
        public.event e ON b.event_id = e.event_id
    WHERE
        r.service_provider_id = p_service_provider_id
        AND r.is_published = true
    ORDER BY
        r.created_at DESC;
END;
$$;

-- =====================================================
-- 7. Create RPC function to get client's ratings
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_client_ratings(p_client_id uuid)
RETURNS SETOF jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT
        jsonb_build_object(
            'rating_id', r.rating_id,
            'overall_rating', r.overall_rating,
            'quality_rating', r.quality_rating,
            'professionalism_rating', r.professionalism_rating,
            'communication_rating', r.communication_rating,
            'value_for_money_rating', r.value_for_money_rating,
            'review_title', r.review_title,
            'review_text', r.review_text,
            'review_pros', r.review_pros,
            'review_cons', r.review_cons,
            'would_recommend', r.would_recommend,
            'created_at', r.created_at,
            'updated_at', r.updated_at,
            'service_provider_response', r.service_provider_response,
            'service_provider', jsonb_build_object(
                'service_provider_id', sp.service_provider_id,
                'service_provider_name', sp.service_provider_name,
                'service_provider_surname', sp.service_provider_surname,
                'service_provider_service_type', sp.service_provider_service_type
            ),
            'booking', jsonb_build_object(
                'booking_id', b.booking_id,
                'event_type', e.event_type,
                'event_date', e.event_date
            )
        )
    FROM
        public.rating r
    JOIN
        public.service_provider sp ON r.service_provider_id = sp.service_provider_id
    JOIN
        public.booking b ON r.booking_id = b.booking_id
    LEFT JOIN
        public.event e ON b.event_id = e.event_id
    WHERE
        r.client_id = p_client_id
    ORDER BY
        r.created_at DESC;
END;
$$;

-- =====================================================
-- 8. Create RPC function to get eligible bookings for rating
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_bookings_eligible_for_rating(p_client_id uuid)
RETURNS SETOF jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT
        jsonb_build_object(
            'booking_id', b.booking_id,
            'booking_status', b.booking_status,
            'booking_date', b.booking_date,
            'event', jsonb_build_object(
                'event_id', e.event_id,
                'event_type', e.event_type,
                'event_date', e.event_date,
                'event_location', e.event_location
            ),
            'service_provider', jsonb_build_object(
                'service_provider_id', sp.service_provider_id,
                'service_provider_name', sp.service_provider_name,
                'service_provider_surname', sp.service_provider_surname,
                'service_provider_service_type', sp.service_provider_service_type
            ),
            'already_rated', EXISTS (
                SELECT 1 FROM public.rating r 
                WHERE r.booking_id = b.booking_id 
                AND r.client_id = p_client_id
            )
        )
    FROM
        public.booking b
    JOIN
        public.service_provider sp ON b.service_provider_id = sp.service_provider_id
    LEFT JOIN
        public.event e ON b.event_id = e.event_id
    WHERE
        b.client_id = p_client_id
        AND b.booking_status = 'completed'
    ORDER BY
        e.event_date DESC NULLS LAST;
END;
$$;

-- =====================================================
-- 9. Set up RLS policies for rating table
-- =====================================================
ALTER TABLE public.rating ENABLE ROW LEVEL SECURITY;

-- Policy for clients to view their own ratings
DROP POLICY IF EXISTS "Clients can view their own ratings." ON public.rating;
CREATE POLICY "Clients can view their own ratings."
ON public.rating FOR SELECT
TO authenticated
USING (client_id = auth.uid());

-- Policy for clients to insert their own ratings
DROP POLICY IF EXISTS "Clients can insert their own ratings." ON public.rating;
CREATE POLICY "Clients can insert their own ratings."
ON public.rating FOR INSERT
TO authenticated
WITH CHECK (client_id = auth.uid());

-- Policy for clients to update their own ratings
DROP POLICY IF EXISTS "Clients can update their own ratings." ON public.rating;
CREATE POLICY "Clients can update their own ratings."
ON public.rating FOR UPDATE
TO authenticated
USING (client_id = auth.uid())
WITH CHECK (client_id = auth.uid());

-- Policy for service providers to view ratings for their services
DROP POLICY IF EXISTS "Service providers can view their ratings." ON public.rating;
CREATE POLICY "Service providers can view their ratings."
ON public.rating FOR SELECT
TO authenticated
USING (service_provider_id = auth.uid() OR is_published = true);

-- =====================================================
-- 10. Verification queries
-- =====================================================

-- Check that rating table was created
SELECT 
    'Rating table created' as status,
    COUNT(*) as existing_ratings
FROM public.rating;

-- Check rating columns in service_provider table
SELECT 
    'Service provider rating columns' as status,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'service_provider' 
AND table_schema = 'public'
AND column_name LIKE '%rating%'
ORDER BY column_name;

-- Check RPC functions exist
SELECT 
    'Rating RPC Functions' as status,
    COUNT(*) as function_count
FROM pg_proc 
WHERE proname IN ('submit_rating', 'update_rating', 'get_service_provider_ratings', 'get_client_ratings', 'get_bookings_eligible_for_rating')
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');





