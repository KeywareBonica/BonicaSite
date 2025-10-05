-- Create function to automatically notify service providers when job carts are created
CREATE OR REPLACE FUNCTION notify_service_providers_on_job_cart()
RETURNS TRIGGER AS $$
DECLARE
    provider_record RECORD;
    notification_record RECORD;
    client_record RECORD;
BEGIN
    -- Get client information for the notification message using direct client_id relationship
    SELECT 
        c.client_name,
        c.client_surname,
        e.event_type,
        e.event_date,
        e.event_location
    INTO client_record
    FROM client c
    JOIN event e ON e.event_id = NEW.event_id
    WHERE c.client_id = NEW.client_id;
    
    -- Get all verified service providers who offer this service
    -- Match by service_id for more accurate matching
    FOR provider_record IN
        SELECT 
            sp.service_provider_id,
            sp.service_provider_name,
            sp.service_provider_surname,
            s.service_name,
            s.service_type
        FROM service_provider sp
        JOIN service s ON sp.service_id = s.service_id
        WHERE sp.service_id = NEW.service_id  -- ✅ Match by service_id instead of service name
        AND sp.service_provider_verification = true
    LOOP
        -- Create notification for this service provider
        INSERT INTO notification (
            notification_type,
            notification_title,
            notification_message,
            notification_date,
            notification_time,
            notification_status,
            user_type,
            user_id,
            job_cart_id,
            event_id
        ) VALUES (
            'new_job_cart',
            'New Job Available',
            'New "' || NEW.job_cart_item || '" job available from ' || COALESCE(client_record.client_name, 'Client') || ' for "' || COALESCE(client_record.event_type, 'Event') || '" on ' || COALESCE(client_record.event_date::text, 'TBD') || ' at ' || COALESCE(client_record.event_location, 'TBD') || '. Click to view details and submit your quotation.',
            CURRENT_DATE,
            CURRENT_TIME,
            'unread',
            'service_provider',
            provider_record.service_provider_id,
            NEW.job_cart_id,
            NEW.event_id
        );
        
        RAISE NOTICE 'Notification created for service provider: % % (Service: %)', 
            provider_record.service_provider_name, 
            provider_record.service_provider_surname,
            provider_record.service_name;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger that fires when a new job cart is inserted
CREATE OR REPLACE TRIGGER trigger_notify_providers_on_job_cart
    AFTER INSERT ON job_cart
    FOR EACH ROW
    EXECUTE FUNCTION notify_service_providers_on_job_cart();

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_job_cart_item ON job_cart(job_cart_item);
CREATE INDEX IF NOT EXISTS idx_service_provider_verification ON service_provider(service_provider_verification);
CREATE INDEX IF NOT EXISTS idx_notification_user_type ON notification(user_type);

-- Add comment for documentation
COMMENT ON FUNCTION notify_service_providers_on_job_cart() IS 'Automatically notifies relevant service providers when new job carts are created';
COMMENT ON TRIGGER trigger_notify_providers_on_job_cart ON job_cart IS 'Triggers automatic notifications to service providers when job carts are created';
