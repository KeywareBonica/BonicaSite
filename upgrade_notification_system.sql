-- upgrade_notification_system.sql
-- Upgrade existing notification system with new features (non-breaking)

-- =====================================================
-- 1. Add new columns to existing notification table
-- =====================================================

-- Add notification type categories
ALTER TABLE public.notification
ADD COLUMN IF NOT EXISTS notification_category text CHECK (notification_category IN (
    'booking', 'quotation', 'payment', 'refund', 'rating', 'job_cart', 'system', 'general'
)),
ADD COLUMN IF NOT EXISTS related_booking_id uuid REFERENCES public.booking(booking_id),
ADD COLUMN IF NOT EXISTS related_quotation_id uuid REFERENCES public.quotation(quotation_id),
ADD COLUMN IF NOT EXISTS related_job_cart_id uuid REFERENCES public.job_cart(job_cart_id),
ADD COLUMN IF NOT EXISTS priority text DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
ADD COLUMN IF NOT EXISTS action_url text, -- Deep link to relevant page
ADD COLUMN IF NOT EXISTS action_label text, -- Button text like "View Booking", "Accept Quotation"
ADD COLUMN IF NOT EXISTS metadata jsonb, -- Additional structured data
ADD COLUMN IF NOT EXISTS expires_at timestamp with time zone, -- For time-sensitive notifications
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- Add indexes for new columns
CREATE INDEX IF NOT EXISTS idx_notification_category ON public.notification(notification_category);
CREATE INDEX IF NOT EXISTS idx_notification_priority ON public.notification(priority);
CREATE INDEX IF NOT EXISTS idx_notification_related_booking ON public.notification(related_booking_id) WHERE related_booking_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_notification_related_quotation ON public.notification(related_quotation_id) WHERE related_quotation_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_notification_expires_at ON public.notification(expires_at) WHERE expires_at IS NOT NULL;

-- Update existing notifications to have default category
UPDATE public.notification
SET notification_category = 'general'
WHERE notification_category IS NULL;

-- =====================================================
-- 2. Create notification template table
-- =====================================================

CREATE TABLE IF NOT EXISTS public.notification_template (
    template_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    template_key text NOT NULL UNIQUE, -- e.g., 'booking_created', 'quotation_received'
    template_name text NOT NULL,
    notification_category text NOT NULL CHECK (notification_category IN (
        'booking', 'quotation', 'payment', 'refund', 'rating', 'job_cart', 'system', 'general'
    )),
    
    -- Template content (supports {{variable}} substitution)
    title_template text NOT NULL,
    message_template text NOT NULL,
    
    -- Default settings
    default_type text DEFAULT 'info' CHECK (default_type IN ('info', 'success', 'warning', 'error')),
    default_priority text DEFAULT 'normal' CHECK (default_priority IN ('low', 'normal', 'high', 'urgent')),
    action_url_template text, -- Can include variables like {{booking_id}}
    action_label text,
    
    -- Configuration
    is_active boolean DEFAULT true,
    send_email boolean DEFAULT false, -- Future: trigger email
    send_sms boolean DEFAULT false, -- Future: trigger SMS
    
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Insert default notification templates
INSERT INTO public.notification_template (template_key, template_name, notification_category, title_template, message_template, default_type, default_priority, action_url_template, action_label)
VALUES
    -- Booking notifications
    ('booking_created', 'Booking Created', 'booking', 
     'Booking Confirmed', 
     'Your booking for {{event_type}} on {{event_date}} has been confirmed. Booking #{{booking_id}}',
     'success', 'high', 'client-update-booking.html?booking_id={{booking_id}}', 'View Booking'),
    
    ('booking_updated', 'Booking Updated', 'booking',
     'Booking Updated',
     'Your booking #{{booking_id}} for {{event_type}} has been updated successfully.',
     'info', 'normal', 'client-update-booking.html?booking_id={{booking_id}}', 'View Changes'),
    
    ('booking_cancelled', 'Booking Cancelled', 'booking',
     'Booking Cancelled',
     'Booking #{{booking_id}} has been cancelled. Refund: R{{refund_amount}}',
     'warning', 'high', 'dashboard.html', 'View Dashboard'),
    
    -- Quotation notifications  
    ('quotation_received', 'Quotation Received', 'quotation',
     'New Quotation Available',
     'You received a quotation for {{service_type}} from {{provider_name}}. Amount: R{{quotation_price}}',
     'success', 'high', 'quotation.html?quotation_id={{quotation_id}}', 'View Quotation'),
    
    ('quotation_accepted', 'Quotation Accepted', 'quotation',
     'Your Quotation Was Accepted!',
     '{{client_name}} accepted your quotation #{{quotation_id}} for R{{quotation_price}}',
     'success', 'high', 'service-provider-dashboard.html', 'View Details'),
    
    ('quotation_expiring_soon', 'Quotation Expiring', 'quotation',
     'Quotation Expiring Soon',
     'Your quotation for {{service_type}} expires in {{hours_remaining}} hours. Total: R{{quotation_price}}',
     'warning', 'urgent', 'quotation.html?quotation_id={{quotation_id}}', 'Review Now'),
    
    -- Payment notifications
    ('payment_uploaded', 'Payment Uploaded', 'payment',
     'Payment Proof Uploaded',
     'Payment proof has been uploaded for booking #{{booking_id}}. Awaiting verification.',
     'info', 'high', 'admin-verify-payments.html', 'Verify Payment'),
    
    ('payment_verified', 'Payment Verified', 'payment',
     'Payment Verified',
     'Your payment for booking #{{booking_id}} has been verified. Amount: R{{payment_amount}}',
     'success', 'high', 'dashboard.html', 'View Booking'),
    
    ('payment_rejected', 'Payment Rejected', 'payment',
     'Payment Needs Attention',
     'Your payment proof for booking #{{booking_id}} needs to be re-uploaded. Reason: {{rejection_reason}}',
     'error', 'urgent', 'payment.html?booking_id={{booking_id}}', 'Reupload Payment'),
    
    -- Refund notifications
    ('refund_requested', 'Refund Requested', 'refund',
     'Refund Request Received',
     'Client {{client_name}} requested a refund of R{{refund_amount}} for booking #{{booking_id}}',
     'warning', 'high', 'refund-management.html', 'Review Request'),
    
    ('refund_approved', 'Refund Approved', 'refund',
     'Refund Approved',
     'Your refund of R{{refund_amount}} has been approved. Processing time: 3-5 business days.',
     'success', 'high', 'dashboard.html', 'View Details'),
    
    -- Rating notifications
    ('rating_received', 'New Rating Received', 'rating',
     'New {{rating_stars}}-Star Review',
     '{{client_name}} left you a {{rating_stars}}-star review for booking #{{booking_id}}',
     'success', 'normal', 'service-provider-dashboard.html', 'View Review'),
    
    -- Job cart notifications
    ('job_cart_created', 'New Job Request', 'job_cart',
     'New Job Request - {{service_type}}',
     'You have a new job request for {{event_type}} on {{event_date}}. Submit quotation by {{deadline}}',
     'info', 'urgent', 'service-provider-dashboard.html', 'Submit Quotation'),
    
    -- System notifications
    ('system_alert', 'System Alert', 'system',
     '{{alert_title}}',
     '{{alert_message}}',
     'warning', 'normal', NULL, NULL)
ON CONFLICT (template_key) DO NOTHING;

-- =====================================================
-- 3. Create helper function to replace template variables
-- =====================================================

CREATE OR REPLACE FUNCTION public.replace_template_variables(
    template text,
    variables jsonb
)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE
    result text := template;
    key text;
    value text;
BEGIN
    FOR key, value IN SELECT * FROM jsonb_each_text(variables) LOOP
        result := REPLACE(result, '{{' || key || '}}', COALESCE(value, ''));
    END LOOP;
    RETURN result;
END;
$$;

-- =====================================================
-- 4. Create enhanced notification creation function
-- =====================================================

CREATE OR REPLACE FUNCTION public.create_notification_enhanced(
    p_user_id uuid,
    p_user_type text,
    p_template_key text,
    p_variables jsonb DEFAULT '{}'::jsonb,
    p_related_booking_id uuid DEFAULT NULL,
    p_related_quotation_id uuid DEFAULT NULL,
    p_related_job_cart_id uuid DEFAULT NULL
)
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
    v_template RECORD;
    v_title text;
    v_message text;
    v_action_url text;
    v_notification_id uuid;
BEGIN
    -- Get template
    SELECT * INTO v_template 
    FROM public.notification_template 
    WHERE template_key = p_template_key AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Template % not found or inactive', p_template_key;
    END IF;
    
    -- Replace variables in templates
    v_title := public.replace_template_variables(v_template.title_template, p_variables);
    v_message := public.replace_template_variables(v_template.message_template, p_variables);
    v_action_url := public.replace_template_variables(COALESCE(v_template.action_url_template, ''), p_variables);
    
    -- Insert notification
    INSERT INTO public.notification (
        user_id,
        user_type,
        title,
        message,
        type,
        notification_category,
        priority,
        action_url,
        action_label,
        metadata,
        related_booking_id,
        related_quotation_id,
        related_job_cart_id
    ) VALUES (
        p_user_id,
        p_user_type,
        v_title,
        v_message,
        v_template.default_type,
        v_template.notification_category,
        v_template.default_priority,
        NULLIF(v_action_url, ''),
        v_template.action_label,
        p_variables,
        p_related_booking_id,
        p_related_quotation_id,
        p_related_job_cart_id
    )
    RETURNING notification_id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$;

-- =====================================================
-- 5. Create bulk notification creation function
-- =====================================================

CREATE OR REPLACE FUNCTION public.create_bulk_notifications(
    p_user_ids uuid[],
    p_user_type text,
    p_template_key text,
    p_variables jsonb DEFAULT '{}'::jsonb
)
RETURNS integer LANGUAGE plpgsql AS $$
DECLARE
    v_user_id uuid;
    v_count integer := 0;
BEGIN
    FOREACH v_user_id IN ARRAY p_user_ids LOOP
        PERFORM public.create_notification_enhanced(
            v_user_id,
            p_user_type,
            p_template_key,
            p_variables
        );
        v_count := v_count + 1;
    END LOOP;
    
    RETURN v_count;
END;
$$;

-- =====================================================
-- 6. Create RPC function to get user notifications (enhanced)
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_user_notifications_enhanced(
    p_user_id uuid,
    p_user_type text,
    p_unread_only boolean DEFAULT false,
    p_category text DEFAULT NULL,
    p_limit integer DEFAULT 50
)
RETURNS SETOF jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT
        jsonb_build_object(
            'notification_id', n.notification_id,
            'title', n.title,
            'message', n.message,
            'type', n.type,
            'category', n.notification_category,
            'priority', n.priority,
            'action_url', n.action_url,
            'action_label', n.action_label,
            'metadata', n.metadata,
            'is_read', n.is_read,
            'read_at', n.read_at,
            'created_at', n.created_at,
            'related_booking_id', n.related_booking_id,
            'related_quotation_id', n.related_quotation_id,
            'related_job_cart_id', n.related_job_cart_id
        )
    FROM
        public.notification n
    WHERE
        n.user_id = p_user_id
        AND n.user_type = p_user_type
        AND (p_unread_only = false OR n.is_read = false)
        AND (p_category IS NULL OR n.notification_category = p_category)
        AND (n.expires_at IS NULL OR n.expires_at > now())
    ORDER BY
        CASE n.priority
            WHEN 'urgent' THEN 1
            WHEN 'high' THEN 2
            WHEN 'normal' THEN 3
            WHEN 'low' THEN 4
        END,
        n.created_at DESC
    LIMIT p_limit;
END;
$$;

-- =====================================================
-- 7. Create RPC function to mark notification as read
-- =====================================================

CREATE OR REPLACE FUNCTION public.mark_notification_as_read(
    p_notification_id uuid,
    p_user_id uuid
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- Check if notification belongs to user
    IF NOT EXISTS (
        SELECT 1 FROM public.notification 
        WHERE notification_id = p_notification_id 
        AND user_id = p_user_id
    ) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Notification not found or unauthorized');
    END IF;
    
    UPDATE public.notification
    SET
        is_read = true,
        read_at = now(),
        updated_at = now()
    WHERE notification_id = p_notification_id;
    
    RETURN jsonb_build_object('success', TRUE, 'message', 'Notification marked as read');
END;
$$;

-- =====================================================
-- 8. Create RPC function to get unread count by category
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_unread_count_by_category(
    p_user_id uuid,
    p_user_type text
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_result jsonb;
BEGIN
    SELECT jsonb_object_agg(
        COALESCE(notification_category, 'general'),
        count
    ) INTO v_result
    FROM (
        SELECT 
            notification_category,
            COUNT(*) as count
        FROM public.notification
        WHERE user_id = p_user_id
        AND user_type = p_user_type
        AND is_read = false
        AND (expires_at IS NULL OR expires_at > now())
        GROUP BY notification_category
    ) counts;
    
    RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

-- =====================================================
-- 9. Create RPC function to mark all notifications as read
-- =====================================================

CREATE OR REPLACE FUNCTION public.mark_all_notifications_as_read(
    p_user_id uuid,
    p_user_type text,
    p_category text DEFAULT NULL
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
    WHERE user_id = p_user_id
    AND user_type = p_user_type
    AND is_read = false
    AND (p_category IS NULL OR notification_category = p_category);
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN jsonb_build_object(
        'success', TRUE,
        'message', 'All notifications marked as read',
        'updated_count', v_updated_count
    );
END;
$$;

-- =====================================================
-- 10. Create RPC function to delete old notifications
-- =====================================================

CREATE OR REPLACE FUNCTION public.cleanup_old_notifications(
    p_days_old integer DEFAULT 90
)
RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE
    v_deleted_count integer;
BEGIN
    DELETE FROM public.notification
    WHERE created_at < now() - (p_days_old || ' days')::interval
    AND is_read = true;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN jsonb_build_object(
        'success', TRUE,
        'deleted_count', v_deleted_count,
        'message', v_deleted_count || ' old notifications cleaned up'
    );
END;
$$;

-- =====================================================
-- 11. Create trigger to auto-expire old notifications
-- =====================================================

CREATE OR REPLACE FUNCTION public.auto_update_notification_timestamp()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_update_notification_timestamp
    BEFORE UPDATE ON public.notification
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_update_notification_timestamp();

-- =====================================================
-- 12. Verification queries
-- =====================================================

-- Check new columns added
SELECT 
    'Notification table columns' as status,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'notification' 
AND table_schema = 'public'
AND column_name IN ('notification_category', 'priority', 'action_url', 'metadata', 'expires_at')
ORDER BY column_name;

-- Check notification templates
SELECT 
    'Notification templates' as status,
    COUNT(*) as template_count
FROM public.notification_template;

-- List all templates
SELECT
    template_key,
    template_name,
    notification_category,
    default_priority,
    is_active
FROM public.notification_template
ORDER BY notification_category, template_key;

-- Check RPC functions exist
SELECT 
    'Notification RPC Functions' as status,
    COUNT(*) as function_count
FROM pg_proc 
WHERE proname IN (
    'create_notification_enhanced',
    'create_bulk_notifications',
    'get_user_notifications_enhanced',
    'mark_notification_as_read',
    'get_unread_count_by_category',
    'mark_all_notifications_as_read',
    'cleanup_old_notifications'
)
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- Show sample of existing notifications
SELECT 
    'Sample existing notifications' as status,
    notification_id,
    user_type,
    title,
    notification_category,
    is_read,
    created_at
FROM public.notification
ORDER BY created_at DESC
LIMIT 5;





