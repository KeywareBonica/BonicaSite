-- Email Notification System Migration
-- Creates tables and functions for email notification tracking and management

-- =====================================================
-- 1. Create email_notification_log table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.email_notification_log (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_email text NOT NULL,
    subject text NOT NULL,
    body text NOT NULL,
    type text NOT NULL CHECK (type IN (
        'profile_created', 
        'new_job_cart', 
        'new_quotation', 
        'quotation_accepted',
        'booking_confirmed',
        'payment_received',
        'booking_reminder',
        'system_notification'
    )),
    user_id uuid NOT NULL,
    user_type text NOT NULL CHECK (user_type IN ('client', 'service_provider', 'admin')),
    
    -- Email delivery tracking
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'bounced')),
    sent_at timestamp with time zone DEFAULT now(),
    delivered_at timestamp with time zone,
    failed_at timestamp with time zone,
    error_message text,
    external_message_id text, -- ID from email provider (SendGrid, etc.)
    
    -- Retry mechanism
    retry_count integer DEFAULT 0,
    max_retries integer DEFAULT 3,
    next_retry_at timestamp with time zone,
    
    -- Metadata
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- =====================================================
-- 2. Create indexes for efficient queries
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_email_notification_recipient ON public.email_notification_log(recipient_email);
CREATE INDEX IF NOT EXISTS idx_email_notification_user ON public.email_notification_log(user_id, user_type);
CREATE INDEX IF NOT EXISTS idx_email_notification_type ON public.email_notification_log(type);
CREATE INDEX IF NOT EXISTS idx_email_notification_status ON public.email_notification_log(status);
CREATE INDEX IF NOT EXISTS idx_email_notification_created_at ON public.email_notification_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_email_notification_retry ON public.email_notification_log(status, next_retry_at) WHERE status = 'pending' AND retry_count < max_retries;

-- =====================================================
-- 3. Create email_preferences table for user email settings
-- =====================================================
CREATE TABLE IF NOT EXISTS public.email_preferences (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    user_type text NOT NULL CHECK (user_type IN ('client', 'service_provider')),
    
    -- Email preference flags
    profile_updates boolean DEFAULT true,
    job_notifications boolean DEFAULT true,
    quotation_notifications boolean DEFAULT true,
    booking_notifications boolean DEFAULT true,
    payment_notifications boolean DEFAULT true,
    system_notifications boolean DEFAULT true,
    
    -- Email frequency
    frequency text DEFAULT 'immediate' CHECK (frequency IN ('immediate', 'daily_digest', 'weekly_digest', 'disabled')),
    
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    
    UNIQUE(user_id, user_type)
);

-- =====================================================
-- 4. Create function to automatically create email preferences for new users
-- =====================================================
CREATE OR REPLACE FUNCTION public.create_user_email_preferences()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert email preferences for new client
    IF TG_TABLE_NAME = 'client' THEN
        INSERT INTO public.email_preferences (user_id, user_type)
        VALUES (NEW.client_id, 'client')
        ON CONFLICT (user_id, user_type) DO NOTHING;
    END IF;
    
    -- Insert email preferences for new service provider
    IF TG_TABLE_NAME = 'service_provider' THEN
        INSERT INTO public.email_preferences (user_id, user_type)
        VALUES (NEW.service_provider_id, 'service_provider')
        ON CONFLICT (user_id, user_type) DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. Create triggers for automatic email preferences creation
-- =====================================================
DROP TRIGGER IF EXISTS trigger_create_client_email_preferences ON public.client;
CREATE TRIGGER trigger_create_client_email_preferences
    AFTER INSERT ON public.client
    FOR EACH ROW
    EXECUTE FUNCTION public.create_user_email_preferences();

DROP TRIGGER IF EXISTS trigger_create_service_provider_email_preferences ON public.service_provider;
CREATE TRIGGER trigger_create_service_provider_email_preferences
    AFTER INSERT ON public.service_provider
    FOR EACH ROW
    EXECUTE FUNCTION public.create_user_email_preferences();

-- =====================================================
-- 6. Create function to send profile created email notification
-- =====================================================
CREATE OR REPLACE FUNCTION public.send_profile_created_email()
RETURNS TRIGGER AS $$
DECLARE
    user_name text;
    user_surname text;
    user_email text;
    user_type text;
    user_id uuid;
BEGIN
    -- Get user details based on table
    IF TG_TABLE_NAME = 'client' THEN
        user_name := NEW.client_name;
        user_surname := NEW.client_surname;
        user_email := NEW.client_email;
        user_type := 'client';
        user_id := NEW.client_id;
    ELSIF TG_TABLE_NAME = 'service_provider' THEN
        user_name := NEW.service_provider_name;
        user_surname := NEW.service_provider_surname;
        user_email := NEW.service_provider_email;
        user_type := 'service_provider';
        user_id := NEW.service_provider_id;
    ELSE
        RETURN NEW;
    END IF;

    -- Insert email notification record
    INSERT INTO public.email_notification_log (
        recipient_email,
        subject,
        body,
        type,
        user_id,
        user_type,
        metadata
    ) VALUES (
        user_email,
        'Welcome to Bonica Event Management - ' || user_name || ' ' || user_surname,
        'Welcome to Bonica Event Management System! Your ' || user_type || ' account has been successfully created.',
        'profile_created',
        user_id,
        user_type,
        jsonb_build_object(
            'user_name', user_name,
            'user_surname', user_surname,
            'created_at', now()
        )
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 7. Create triggers for profile creation emails
-- =====================================================
DROP TRIGGER IF EXISTS trigger_send_client_profile_created_email ON public.client;
CREATE TRIGGER trigger_send_client_profile_created_email
    AFTER INSERT ON public.client
    FOR EACH ROW
    EXECUTE FUNCTION public.send_profile_created_email();

DROP TRIGGER IF EXISTS trigger_send_service_provider_profile_created_email ON public.service_provider;
CREATE TRIGGER trigger_send_service_provider_profile_created_email
    AFTER INSERT ON public.service_provider
    FOR EACH ROW
    EXECUTE FUNCTION public.send_profile_created_email();

-- =====================================================
-- 8. Create function to send job cart notification emails
-- =====================================================
CREATE OR REPLACE FUNCTION public.send_job_cart_notifications()
RETURNS TRIGGER AS $$
DECLARE
    service_provider RECORD;
    client_record RECORD;
    job_cart_item text;
BEGIN
    -- Get job cart and client details
    SELECT 
        jc.service_id,
        jc.client_id,
        c.client_name,
        c.client_surname,
        c.client_email,
        s.service_name as job_cart_item
    INTO client_record, job_cart_item
    FROM public.job_cart jc
    JOIN public.client c ON jc.client_id = c.client_id
    LEFT JOIN public.service s ON jc.service_id = s.service_id
    WHERE jc.job_cart_id = NEW.job_cart_id;

    -- Find relevant service providers for this service
    FOR service_provider IN 
        SELECT 
            sp.service_provider_id,
            sp.service_provider_name,
            sp.service_provider_surname,
            sp.service_provider_email,
            s.service_name
        FROM public.service_provider sp
        JOIN public.service s ON sp.service_id = s.service_id
        WHERE sp.service_id = NEW.service_id
    LOOP
        -- Check if service provider wants job notifications
        IF EXISTS (
            SELECT 1 FROM public.email_preferences ep 
            WHERE ep.user_id = service_provider.service_provider_id 
            AND ep.user_type = 'service_provider' 
            AND ep.job_notifications = true
        ) THEN
            -- Insert email notification
            INSERT INTO public.email_notification_log (
                recipient_email,
                subject,
                body,
                type,
                user_id,
                user_type,
                metadata
            ) VALUES (
                service_provider.service_provider_email,
                'New Job Available - ' || job_cart_item,
                'A new job request has been posted: ' || job_cart_item || ' for client ' || client_record.client_name || ' ' || client_record.client_surname,
                'new_job_cart',
                service_provider.service_provider_id,
                'service_provider',
                jsonb_build_object(
                    'job_cart_id', NEW.job_cart_id,
                    'client_name', client_record.client_name || ' ' || client_record.client_surname,
                    'service_name', job_cart_item
                )
            );
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 9. Create trigger for job cart notifications
-- =====================================================
DROP TRIGGER IF EXISTS trigger_send_job_cart_notifications ON public.job_cart;
CREATE TRIGGER trigger_send_job_cart_notifications
    AFTER INSERT ON public.job_cart
    FOR EACH ROW
    EXECUTE FUNCTION public.send_job_cart_notifications();

-- =====================================================
-- 10. Create function to send quotation notification emails
-- =====================================================
CREATE OR REPLACE FUNCTION public.send_quotation_notifications()
RETURNS TRIGGER AS $$
DECLARE
    client_record RECORD;
    job_cart_record RECORD;
    service_provider_record RECORD;
BEGIN
    -- Get quotation details and related client
    SELECT 
        c.client_id,
        c.client_name,
        c.client_surname,
        c.client_email,
        q.quotation_price,
        s.service_name,
        q.quotation_details
    INTO client_record
    FROM public.quotation q
    JOIN public.job_cart jc ON q.job_cart_id = jc.job_cart_id
    JOIN public.client c ON jc.client_id = c.client_id
    LEFT JOIN public.service s ON jc.service_id = s.service_id
    WHERE q.quotation_id = NEW.quotation_id;

    -- Check if client wants quotation notifications
    IF EXISTS (
        SELECT 1 FROM public.email_preferences ep 
        WHERE ep.user_id = client_record.client_id 
        AND ep.user_type = 'client' 
        AND ep.quotation_notifications = true
    ) THEN
        -- Insert email notification for client
        INSERT INTO public.email_notification_log (
            recipient_email,
            subject,
            body,
            type,
            user_id,
            user_type,
            metadata
        ) VALUES (
            client_record.client_email,
            'New Quotation Received - ' || client_record.service_name,
            'You have received a new quotation for ' || client_record.service_name || ' with a price of R' || client_record.quotation_price,
            'new_quotation',
            client_record.client_id,
            'client',
            jsonb_build_object(
                'quotation_id', NEW.quotation_id,
                'quotation_price', client_record.quotation_price,
                'service_name', client_record.service_name
            )
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 11. Create trigger for quotation notifications
-- =====================================================
DROP TRIGGER IF EXISTS trigger_send_quotation_notifications ON public.quotation;
CREATE TRIGGER trigger_send_quotation_notifications
    AFTER INSERT ON public.quotation
    FOR EACH ROW
    EXECUTE FUNCTION public.send_quotation_notifications();

-- =====================================================
-- 12. Create RLS policies for email notification tables
-- =====================================================
ALTER TABLE public.email_notification_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_preferences ENABLE ROW LEVEL SECURITY;

-- Policy for users to view their own email notifications
DROP POLICY IF EXISTS "Users can view their own email notifications" ON public.email_notification_log;
CREATE POLICY "Users can view their own email notifications" ON public.email_notification_log
    FOR SELECT USING (
        (user_type = 'client' AND user_id = (SELECT client_id FROM public.client WHERE client_email = current_setting('request.jwt.claims', true)::json->>'email'))
        OR 
        (user_type = 'service_provider' AND user_id = (SELECT service_provider_id FROM public.service_provider WHERE service_provider_email = current_setting('request.jwt.claims', true)::json->>'email'))
    );

-- Policy for users to manage their own email preferences
DROP POLICY IF EXISTS "Users can manage their own email preferences" ON public.email_preferences;
CREATE POLICY "Users can manage their own email preferences" ON public.email_preferences
    FOR ALL USING (
        (user_type = 'client' AND user_id = (SELECT client_id FROM public.client WHERE client_email = current_setting('request.jwt.claims', true)::json->>'email'))
        OR 
        (user_type = 'service_provider' AND user_id = (SELECT service_provider_id FROM public.service_provider WHERE service_provider_email = current_setting('request.jwt.claims', true)::json->>'email'))
    );

-- =====================================================
-- 13. Create view for pending email notifications (for email service)
-- =====================================================
CREATE OR REPLACE VIEW public.pending_email_notifications AS
SELECT 
    enl.*,
    ep.frequency,
    ep.job_notifications,
    ep.quotation_notifications,
    ep.booking_notifications,
    ep.payment_notifications,
    ep.system_notifications
FROM public.email_notification_log enl
LEFT JOIN public.email_preferences ep ON (
    enl.user_id = ep.user_id AND 
    enl.user_type = ep.user_type
)
WHERE enl.status = 'pending'
AND enl.retry_count < enl.max_retries
AND (enl.next_retry_at IS NULL OR enl.next_retry_at <= now());

-- =====================================================
-- 14. Verification queries
-- =====================================================

-- Check that tables were created
SELECT 'email_notification_log' as table_name, COUNT(*) as records FROM public.email_notification_log
UNION ALL
SELECT 'email_preferences' as table_name, COUNT(*) as records FROM public.email_preferences;

-- Check triggers exist
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND trigger_name LIKE '%email%';

COMMENT ON TABLE public.email_notification_log IS 'Logs all email notifications sent by the system';
COMMENT ON TABLE public.email_preferences IS 'User preferences for email notifications';
COMMENT ON VIEW public.pending_email_notifications IS 'View of pending email notifications ready to be sent';
