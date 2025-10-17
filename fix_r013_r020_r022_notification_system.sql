-- fix_r013_r020_r022_notification_system.sql
-- R013: Implement notification service (email/SMS API integration)
-- R020: Implement notification system for service providers
-- R022: Implement notification handling system (for all user roles)

-- =====================================================
-- 1. Create notification_type enum
-- =====================================================
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type_enum') THEN
        CREATE TYPE public.notification_type_enum AS ENUM (
            'booking_created',
            'booking_updated',
            'booking_cancelled',
            'booking_confirmed',
            'booking_completed',
            'quotation_received',
            'quotation_accepted',
            'quotation_rejected',
            'quotation_expiring_soon',
            'payment_received',
            'payment_verified',
            'payment_rejected',
            'refund_requested',
            'refund_approved',
            'refund_processed',
            'rating_received',
            'service_provider_response',
            'job_cart_created',
            'general_message',
            'system_alert'
        );
    END IF;
END $$;

-- =====================================================
-- 2. Create notification_channel enum
-- =====================================================
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_channel_enum') THEN
        CREATE TYPE public.notification_channel_enum AS ENUM ('email', 'sms', 'in_app', 'push');
    END IF;
END $$;

-- =====================================================
-- 3. Create notification table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.notification (
    notification_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Recipient information
    recipient_type text NOT NULL CHECK (recipient_type IN ('client', 'service_provider', 'admin')),
    recipient_id uuid NOT NULL, -- client_id or service_provider_id
    
    -- Notification details
    notification_type public.notification_type_enum NOT NULL,
    notification_channel public.notification_channel_enum NOT NULL,
    notification_title text NOT NULL,
    notification_message text NOT NULL,
    notification_data jsonb, -- Additional structured data
    
    -- Related entities
    booking_id uuid REFERENCES public.booking(booking_id),
    quotation_id uuid REFERENCES public.quotation(quotation_id),
    payment_id uuid REFERENCES public.payment(payment_id),
    rating_id uuid REFERENCES public.rating(rating_id),
    
    -- Delivery status
    is_sent boolean DEFAULT false,
    sent_at timestamp with time zone,
    delivery_status text CHECK (delivery_status IN ('pending', 'sent', 'delivered', 'failed', 'bounced')),
    delivery_error text,
    delivery_attempts integer DEFAULT 0,
    next_retry_at timestamp with time zone,
    
    -- Read status (for in-app notifications)
    is_read boolean DEFAULT false,
    read_at timestamp with time zone,
    
    -- Priority
    priority text DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    
    -- Timestamps
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    
    -- External service tracking (for email/SMS)
    external_id text, -- ID from email/SMS provider
    external_provider text -- 'sendgrid', 'twilio', etc.
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_notification_recipient ON public.notification(recipient_type, recipient_id);
CREATE INDEX IF NOT EXISTS idx_notification_type ON public.notification(notification_type);
CREATE INDEX IF NOT EXISTS idx_notification_channel ON public.notification(notification_channel);
CREATE INDEX IF NOT EXISTS idx_notification_sent ON public.notification(is_sent, sent_at);
CREATE INDEX IF NOT EXISTS idx_notification_read ON public.notification(is_read) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_notification_created_at ON public.notification(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_booking_id ON public.notification(booking_id) WHERE booking_id IS NOT NULL;

-- =====================================================
-- 4. Create notification_template table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.notification_template (
    template_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    template_name text NOT NULL UNIQUE,
    notification_type public.notification_type_enum NOT NULL,
    notification_channel public.notification_channel_enum NOT NULL,
    
    -- Template content
    subject_template text, -- For email
    body_template text NOT NULL, -- Supports variable substitution {{variable_name}}
    
    -- Configuration
    is_active boolean DEFAULT true,
    priority text DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    
    -- Timestamps
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Insert default templates
INSERT INTO public.notification_template (template_name, notification_type, notification_channel, subject_template, body_template, priority)
VALUES
    -- Booking notifications
    ('booking_created_email', 'booking_created', 'email', 
     'Booking Confirmation - {{event_type}}',
     'Hi {{client_name}}, Your booking for {{event_type}} on {{event_date}} has been created successfully. Booking ID: {{booking_id}}',
     'high'),
    
    ('booking_created_sms', 'booking_created', 'sms',
     NULL,
     'Bonica: Your booking for {{event_type}} on {{event_date}} is confirmed. Booking #{{booking_id}}',
     'high'),
    
    ('booking_cancelled_email', 'booking_cancelled', 'email',
     'Booking Cancellation - {{event_type}}',
     'Hi {{client_name}}, Your booking #{{booking_id}} for {{event_type}} has been cancelled. Refund: R{{refund_amount}}. Cancellation fee: R{{cancellation_fee}}.',
     'high'),
    
    -- Quotation notifications
    ('quotation_received_email', 'quotation_received', 'email',
     'New Quotation Received - {{service_type}}',
     'Hi {{client_name}}, You have received a quotation for {{service_type}} from {{service_provider_name}}. Amount: R{{quotation_price}}. View it now!',
     'high'),
    
    ('quotation_accepted_sp_email', 'quotation_accepted', 'email',
     'Your Quotation Was Accepted!',
     'Hi {{service_provider_name}}, Great news! Your quotation #{{quotation_id}} for R{{quotation_price}} has been accepted by {{client_name}}.',
     'high'),
    
    -- Payment notifications
    ('payment_received_email', 'payment_received', 'email',
     'Payment Received - Booking {{booking_id}}',
     'Hi {{service_provider_name}}, Payment proof has been uploaded for booking #{{booking_id}}. Please verify it in your dashboard.',
     'high'),
    
    ('payment_verified_email', 'payment_verified', 'email',
     'Payment Verified - Booking {{booking_id}}',
     'Hi {{client_name}}, Your payment for booking #{{booking_id}} has been verified. Thank you!',
     'high'),
    
    -- Refund notifications
    ('refund_approved_email', 'refund_approved', 'email',
     'Refund Approved - R{{refund_amount}}',
     'Hi {{client_name}}, Your refund request for R{{refund_amount}} has been approved. Processing time: 3-5 business days.',
     'high'),
    
    -- Rating notifications
    ('rating_received_email', 'rating_received', 'email',
     'New Review Received - {{overall_rating}} Stars',
     'Hi {{service_provider_name}}, You received a {{overall_rating}}-star review from {{client_name}}. View it in your dashboard.',
     'normal'),
    
    -- Job cart notifications
    ('job_cart_created_sp_email', 'job_cart_created', 'email',
     'New Job Request - {{service_type}}',
     'Hi {{service_provider_name}}, You have a new job request for {{service_type}} on {{event_date}}. Submit your quotation before {{quotation_deadline}}.',
     'urgent')
ON CONFLICT (template_name) DO NOTHING;

-- =====================================================
-- 5. Create function to create notification
-- =====================================================
CREATE OR REPLACE FUNCTION public.create_notification(
    p_recipient_type text,
    p_recipient_id uuid,
    p_notification_type public.notification_type_enum,
    p_notification_channel public.notification_channel_enum,
    p_title text,
    p_message text,
    p_data jsonb DEFAULT NULL,
    p_booking_id uuid DEFAULT NULL,
    p_quotation_id uuid DEFAULT NULL,
    p_payment_id uuid DEFAULT NULL,
    p_rating_id uuid DEFAULT NULL,
    p_priority text DEFAULT 'normal'
)
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
    v_notification_id uuid;
BEGIN
    INSERT INTO public.notification (
        recipient_type,
        recipient_id,
        notification_type,
        notification_channel,
        notification_title,
        notification_message,
        notification_data,
        booking_id,
        quotation_id,
        payment_id,
        rating_id,
        priority,
        delivery_status
    ) VALUES (
        p_recipient_type,
        p_recipient_id,
        p_notification_type,
        p_notification_channel,
        p_title,
        p_message,
        p_data,
        p_booking_id,
        p_quotation_id,
        p_payment_id,
        p_rating_id,
        p_priority,
        'pending'
    )
    RETURNING notification_id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$;

-- =====================================================
-- 6. Create function to send notification using template
-- =====================================================
CREATE OR REPLACE FUNCTION public.send_notification_from_template(
    p_template_name text,
    p_recipient_type text,
    p_recipient_id uuid,
    p_variables jsonb,
    p_booking_id uuid DEFAULT NULL,
    p_quotation_id uuid DEFAULT NULL,
    p_payment_id uuid DEFAULT NULL,
    p_rating_id uuid DEFAULT NULL
)
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
    v_template RECORD;
    v_subject text;
    v_body text;
    v_notification_id uuid;
    v_key text;
    v_value text;
BEGIN
    -- Get template
    SELECT * INTO v_template FROM public.notification_template 
    WHERE template_name = p_template_name AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Template % not found or inactive', p_template_name;
    END IF;
    
    -- Replace variables in subject and body
    v_subject := v_template.subject_template;
    v_body := v_template.body_template;
    
    -- Replace all variables in the format {{variable_name}}
    FOR v_key, v_value IN SELECT * FROM jsonb_each_text(p_variables) LOOP
        v_subject := REPLACE(v_subject, '{{' || v_key || '}}', COALESCE(v_value, ''));
        v_body := REPLACE(v_body, '{{' || v_key || '}}', COALESCE(v_value, ''));
    END LOOP;
    
    -- Create notification
    v_notification_id := public.create_notification(
        p_recipient_type,
        p_recipient_id,
        v_template.notification_type,
        v_template.notification_channel,
        COALESCE(v_subject, 'Bonica Notification'),
        v_body,
        p_variables,
        p_booking_id,
        p_quotation_id,
        p_payment_id,
        p_rating_id,
        v_template.priority
    );
    
    RETURN v_notification_id;
END;
$$;

-- =====================================================
-- 7. Create function to mark notification as sent
-- =====================================================
CREATE OR REPLACE FUNCTION public.mark_notification_sent(
    p_notification_id uuid,
    p_external_id text DEFAULT NULL,
    p_external_provider text DEFAULT NULL
)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.notification
    SET
        is_sent = true,
        sent_at = now(),
        delivery_status = 'sent',
        external_id = p_external_id,
        external_provider = p_external_provider,
        delivery_attempts = delivery_attempts + 1,
        updated_at = now()
    WHERE notification_id = p_notification_id;
END;
$$;

-- =====================================================
-- 8. Create function to mark notification as read
-- =====================================================
CREATE OR REPLACE FUNCTION public.mark_notification_read(
    p_notification_id uuid,
    p_recipient_id uuid
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- Check if notification belongs to recipient
    IF NOT EXISTS (
        SELECT 1 FROM public.notification 
        WHERE notification_id = p_notification_id 
        AND recipient_id = p_recipient_id
    ) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Notification not found or unauthorized.');
    END IF;
    
    UPDATE public.notification
    SET
        is_read = true,
        read_at = now(),
        updated_at = now()
    WHERE notification_id = p_notification_id;
    
    RETURN jsonb_build_object('success', TRUE, 'message', 'Notification marked as read.');
END;
$$;

-- =====================================================
-- 9. Create RPC function to get user notifications
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_user_notifications(
    p_recipient_type text,
    p_recipient_id uuid,
    p_unread_only boolean DEFAULT false,
    p_limit integer DEFAULT 50
)
RETURNS SETOF jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT
        jsonb_build_object(
            'notification_id', n.notification_id,
            'notification_type', n.notification_type,
            'notification_channel', n.notification_channel,
            'notification_title', n.notification_title,
            'notification_message', n.notification_message,
            'notification_data', n.notification_data,
            'booking_id', n.booking_id,
            'quotation_id', n.quotation_id,
            'payment_id', n.payment_id,
            'rating_id', n.rating_id,
            'is_read', n.is_read,
            'read_at', n.read_at,
            'priority', n.priority,
            'created_at', n.created_at
        )
    FROM
        public.notification n
    WHERE
        n.recipient_type = p_recipient_type
        AND n.recipient_id = p_recipient_id
        AND (p_unread_only = false OR n.is_read = false)
        AND n.notification_channel = 'in_app'
    ORDER BY
        n.created_at DESC
    LIMIT p_limit;
END;
$$;

-- =====================================================
-- 10. Create RPC function to get unread notification count
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_unread_notification_count(
    p_recipient_type text,
    p_recipient_id uuid
)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_count integer;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM public.notification
    WHERE recipient_type = p_recipient_type
    AND recipient_id = p_recipient_id
    AND is_read = false
    AND notification_channel = 'in_app';
    
    RETURN COALESCE(v_count, 0);
END;
$$;

-- =====================================================
-- 11. Create RPC function to mark all notifications as read
-- =====================================================
CREATE OR REPLACE FUNCTION public.mark_all_notifications_read(
    p_recipient_type text,
    p_recipient_id uuid
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_updated_count integer;
BEGIN
    UPDATE public.notification
    SET
        is_read = true,
        read_at = now(),
        updated_at = now()
    WHERE recipient_type = p_recipient_type
    AND recipient_id = p_recipient_id
    AND is_read = false
    AND notification_channel = 'in_app';
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN jsonb_build_object(
        'success', TRUE,
        'message', 'All notifications marked as read.',
        'updated_count', v_updated_count
    );
END;
$$;

-- =====================================================
-- 12. Create function to get pending notifications for sending
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_pending_notifications(
    p_channel public.notification_channel_enum DEFAULT NULL,
    p_limit integer DEFAULT 100
)
RETURNS SETOF public.notification LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.notification
    WHERE delivery_status = 'pending'
    AND is_sent = false
    AND (p_channel IS NULL OR notification_channel = p_channel)
    AND (next_retry_at IS NULL OR next_retry_at <= now())
    AND delivery_attempts < 3
    ORDER BY priority DESC, created_at ASC
    LIMIT p_limit;
END;
$$;

-- =====================================================
-- 13. Set up RLS policies for notification table
-- =====================================================
ALTER TABLE public.notification ENABLE ROW LEVEL SECURITY;

-- Policy for users to view their own notifications
DROP POLICY IF EXISTS "Users can view their own notifications." ON public.notification;
CREATE POLICY "Users can view their own notifications."
ON public.notification FOR SELECT
TO authenticated
USING (recipient_id = auth.uid());

-- Policy for users to update their own notifications (mark as read)
DROP POLICY IF EXISTS "Users can update their own notifications." ON public.notification;
CREATE POLICY "Users can update their own notifications."
ON public.notification FOR UPDATE
TO authenticated
USING (recipient_id = auth.uid())
WITH CHECK (recipient_id = auth.uid());

-- =====================================================
-- 14. Verification queries
-- =====================================================

-- Check that notification table was created
SELECT 
    'Notification table created' as status,
    COUNT(*) as existing_notifications
FROM public.notification;

-- Check notification templates
SELECT 
    'Notification templates' as status,
    COUNT(*) as template_count
FROM public.notification_template;

-- List all notification templates
SELECT
    template_name,
    notification_type,
    notification_channel,
    priority,
    is_active
FROM public.notification_template
ORDER BY notification_type, notification_channel;

-- Check RPC functions exist
SELECT 
    'Notification RPC Functions' as status,
    COUNT(*) as function_count
FROM pg_proc 
WHERE proname IN (
    'create_notification',
    'send_notification_from_template',
    'mark_notification_sent',
    'mark_notification_read',
    'get_user_notifications',
    'get_unread_notification_count',
    'mark_all_notifications_read',
    'get_pending_notifications'
)
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');





