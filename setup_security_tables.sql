-- Setup Security System Tables
-- This script creates tables for OTP, login attempts, and other security features

-- 1. Create OTP codes table
CREATE TABLE IF NOT EXISTS otp_codes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text,
    phone text,
    otp_code text NOT NULL,
    otp_type text NOT NULL CHECK (otp_type IN ('registration', 'login', 'password_reset', 'verification')),
    expires_at timestamp NOT NULL,
    created_at timestamp DEFAULT now(),
    used_at timestamp,
    attempts integer DEFAULT 0
);

-- 2. Create login attempts table for account lockout
CREATE TABLE IF NOT EXISTS login_attempts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text NOT NULL,
    ip_address text,
    user_agent text,
    attempt_time timestamp DEFAULT now(),
    success boolean DEFAULT false
);

-- 3. Create login notifications table
CREATE TABLE IF NOT EXISTS login_notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text NOT NULL,
    login_time timestamp DEFAULT now(),
    ip_address text,
    user_agent text,
    location text,
    device_info text
);

-- 4. Create 2FA secrets table
CREATE TABLE IF NOT EXISTS two_factor_auth (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    user_type text NOT NULL CHECK (user_type IN ('client', 'service_provider', 'admin')),
    secret_key text NOT NULL,
    backup_codes text[],
    is_enabled boolean DEFAULT false,
    created_at timestamp DEFAULT now(),
    last_used timestamp
);

-- 5. Create security logs table
CREATE TABLE IF NOT EXISTS security_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid,
    user_type text,
    action text NOT NULL,
    ip_address text,
    user_agent text,
    details jsonb,
    created_at timestamp DEFAULT now()
);

-- 6. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_otp_codes_email ON otp_codes(email);
CREATE INDEX IF NOT EXISTS idx_otp_codes_phone ON otp_codes(phone);
CREATE INDEX IF NOT EXISTS idx_otp_codes_expires ON otp_codes(expires_at);
CREATE INDEX IF NOT EXISTS idx_login_attempts_email ON login_attempts(email);
CREATE INDEX IF NOT EXISTS idx_login_attempts_time ON login_attempts(attempt_time);
CREATE INDEX IF NOT EXISTS idx_login_notifications_email ON login_notifications(email);
CREATE INDEX IF NOT EXISTS idx_two_factor_auth_user ON two_factor_auth(user_id, user_type);
CREATE INDEX IF NOT EXISTS idx_security_logs_user ON security_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_security_logs_action ON security_logs(action);

-- 7. Create function to clean up expired OTP codes
CREATE OR REPLACE FUNCTION cleanup_expired_otp_codes()
RETURNS void AS $$
BEGIN
    DELETE FROM otp_codes 
    WHERE expires_at < now();
    
    RAISE NOTICE 'Cleaned up expired OTP codes';
END;
$$ LANGUAGE plpgsql;

-- 8. Create function to clean up old login attempts
CREATE OR REPLACE FUNCTION cleanup_old_login_attempts()
RETURNS void AS $$
BEGIN
    DELETE FROM login_attempts 
    WHERE attempt_time < now() - interval '24 hours';
    
    RAISE NOTICE 'Cleaned up old login attempts';
END;
$$ LANGUAGE plpgsql;

-- 9. Create function to clean up old security logs
CREATE OR REPLACE FUNCTION cleanup_old_security_logs()
RETURNS void AS $$
BEGIN
    DELETE FROM security_logs 
    WHERE created_at < now() - interval '90 days';
    
    RAISE NOTICE 'Cleaned up old security logs';
END;
$$ LANGUAGE plpgsql;

-- 10. Create trigger to automatically clean up expired OTP codes
CREATE OR REPLACE FUNCTION trigger_cleanup_expired_otp()
RETURNS trigger AS $$
BEGIN
    -- Clean up expired OTP codes when new ones are inserted
    PERFORM cleanup_expired_otp_codes();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS cleanup_expired_otp_trigger ON otp_codes;
CREATE TRIGGER cleanup_expired_otp_trigger
    AFTER INSERT ON otp_codes
    FOR EACH ROW
    EXECUTE FUNCTION trigger_cleanup_expired_otp();

-- 11. Add RLS policies for security tables
ALTER TABLE otp_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE login_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE login_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE two_factor_auth ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_logs ENABLE ROW LEVEL SECURITY;

-- 12. Create RLS policies for OTP codes
CREATE POLICY "Users can view their own OTP codes"
ON otp_codes FOR SELECT
TO authenticated
USING (email = auth.jwt()->>'email' OR phone = auth.jwt()->>'phone');

CREATE POLICY "System can insert OTP codes"
ON otp_codes FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Users can update their own OTP codes"
ON otp_codes FOR UPDATE
TO authenticated
USING (email = auth.jwt()->>'email' OR phone = auth.jwt()->>'phone');

-- 13. Create RLS policies for login attempts
CREATE POLICY "System can manage login attempts"
ON login_attempts FOR ALL
TO authenticated
WITH CHECK (true);

-- 14. Create RLS policies for login notifications
CREATE POLICY "Users can view their own login notifications"
ON login_notifications FOR SELECT
TO authenticated
USING (email = auth.jwt()->>'email');

CREATE POLICY "System can insert login notifications"
ON login_notifications FOR INSERT
TO authenticated
WITH CHECK (true);

-- 15. Create RLS policies for 2FA
CREATE POLICY "Users can manage their own 2FA"
ON two_factor_auth FOR ALL
TO authenticated
USING (user_id::text = auth.uid()::text);

-- 16. Create RLS policies for security logs
CREATE POLICY "Users can view their own security logs"
ON security_logs FOR SELECT
TO authenticated
USING (user_id::text = auth.uid()::text);

CREATE POLICY "System can insert security logs"
ON security_logs FOR INSERT
TO authenticated
WITH CHECK (true);

-- 17. Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON otp_codes TO authenticated;
GRANT SELECT, INSERT ON login_attempts TO authenticated;
GRANT SELECT, INSERT ON login_notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE ON two_factor_auth TO authenticated;
GRANT SELECT, INSERT ON security_logs TO authenticated;

-- 18. Add comments for documentation
COMMENT ON TABLE otp_codes IS 'Stores OTP codes for email and SMS verification';
COMMENT ON TABLE login_attempts IS 'Tracks login attempts for account lockout protection';
COMMENT ON TABLE login_notifications IS 'Stores login notifications for security monitoring';
COMMENT ON TABLE two_factor_auth IS 'Stores 2FA secrets and backup codes';
COMMENT ON TABLE security_logs IS 'Logs security-related events and actions';

COMMENT ON FUNCTION cleanup_expired_otp_codes() IS 'Removes expired OTP codes from the database';
COMMENT ON FUNCTION cleanup_old_login_attempts() IS 'Removes old login attempts older than 24 hours';
COMMENT ON FUNCTION cleanup_old_security_logs() IS 'Removes security logs older than 90 days';

-- 19. Create a view for security dashboard
CREATE OR REPLACE VIEW security_summary AS
SELECT 
    'otp_codes' as table_name,
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE expires_at > now()) as active_records,
    COUNT(*) FILTER (WHERE expires_at <= now()) as expired_records
FROM otp_codes
UNION ALL
SELECT 
    'login_attempts' as table_name,
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE success = true) as active_records,
    COUNT(*) FILTER (WHERE success = false) as expired_records
FROM login_attempts
WHERE attempt_time > now() - interval '24 hours'
UNION ALL
SELECT 
    'login_notifications' as table_name,
    COUNT(*) as total_records,
    COUNT(*) as active_records,
    0 as expired_records
FROM login_notifications
WHERE login_time > now() - interval '7 days';

SELECT 'Security system tables setup completed successfully!' as status;
