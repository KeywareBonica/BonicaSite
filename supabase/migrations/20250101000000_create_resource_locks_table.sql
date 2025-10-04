-- Create resource_locks table for managing concurrent access
CREATE TABLE resource_locks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id TEXT NOT NULL, -- Format: "table:record_id"
    resource_type TEXT NOT NULL, -- quotation, booking, job_cart, etc.
    resource_record_id UUID NOT NULL, -- The actual record ID being locked
    user_id UUID NOT NULL, -- Client or Service Provider ID
    user_type TEXT NOT NULL CHECK (user_type IN ('client', 'service_provider')),
    operation TEXT NOT NULL DEFAULT 'edit' CHECK (operation IN ('edit', 'delete', 'approve', 'reject', 'cancel')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_heartbeat TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_by_ip INET, -- Track IP for security
    session_id TEXT, -- Track session for cleanup
    CONSTRAINT unique_resource_lock UNIQUE (resource_id)
);

-- Indexes for performance
CREATE INDEX idx_resource_locks_resource_id ON resource_locks(resource_id);
CREATE INDEX idx_resource_locks_user_id ON resource_locks(user_id);
CREATE INDEX idx_resource_locks_expires_at ON resource_locks(expires_at);
CREATE INDEX idx_resource_locks_created_at ON resource_locks(created_at);

-- Function to clean up expired locks
CREATE OR REPLACE FUNCTION cleanup_expired_locks()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM resource_locks 
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to check if resource is locked
CREATE OR REPLACE FUNCTION is_resource_locked(
    p_resource_id TEXT,
    p_user_id UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    lock_record RECORD;
    user_name TEXT;
BEGIN
    SELECT * INTO lock_record
    FROM resource_locks
    WHERE resource_id = p_resource_id
    AND expires_at > NOW();
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'locked', false,
            'message', 'Resource is available'
        );
    END IF;
    
    -- Get user name based on user type
    IF lock_record.user_type = 'client' THEN
        SELECT CONCAT(client_name, ' ', client_surname) INTO user_name
        FROM client
        WHERE client_id = lock_record.user_id;
    ELSE
        SELECT CONCAT(service_provider_name, ' ', service_provider_surname) INTO user_name
        FROM service_provider
        WHERE service_provider_id = lock_record.user_id;
    END IF;
    
    RETURN json_build_object(
        'locked', true,
        'locked_by', COALESCE(user_name, 'Unknown User'),
        'locked_at', lock_record.created_at,
        'expires_at', lock_record.expires_at,
        'operation', lock_record.operation,
        'user_id', lock_record.user_id,
        'is_own_lock', (lock_record.user_id = p_user_id)
    );
END;
$$ LANGUAGE plpgsql;

-- Function to acquire lock with conflict detection
CREATE OR REPLACE FUNCTION acquire_resource_lock(
    p_resource_id TEXT,
    p_resource_type TEXT,
    p_resource_record_id UUID,
    p_user_id UUID,
    p_user_type TEXT,
    p_operation TEXT DEFAULT 'edit',
    p_lock_duration_seconds INTEGER DEFAULT 300
)
RETURNS JSON AS $$
DECLARE
    lock_record RECORD;
    result JSON;
    user_name TEXT;
BEGIN
    -- Check if resource is already locked
    SELECT * INTO lock_record
    FROM resource_locks
    WHERE resource_id = p_resource_id
    AND expires_at > NOW();
    
    IF FOUND THEN
        -- Resource is locked, get user name
        IF lock_record.user_type = 'client' THEN
            SELECT CONCAT(client_name, ' ', client_surname) INTO user_name
            FROM client
            WHERE client_id = lock_record.user_id;
        ELSE
            SELECT CONCAT(service_provider_name, ' ', service_provider_surname) INTO user_name
            FROM service_provider
            WHERE service_provider_id = lock_record.user_id;
        END IF;
        
        RETURN json_build_object(
            'success', false,
            'locked', true,
            'locked_by', COALESCE(user_name, 'Unknown User'),
            'locked_at', lock_record.created_at,
            'expires_at', lock_record.expires_at,
            'message', 'Resource is currently locked by ' || COALESCE(user_name, 'another user')
        );
    END IF;
    
    -- Try to acquire lock
    BEGIN
        INSERT INTO resource_locks (
            resource_id,
            resource_type,
            resource_record_id,
            user_id,
            user_type,
            operation,
            expires_at
        ) VALUES (
            p_resource_id,
            p_resource_type,
            p_resource_record_id,
            p_user_id,
            p_user_type,
            p_operation,
            NOW() + (p_lock_duration_seconds || ' seconds')::INTERVAL
        ) RETURNING * INTO lock_record;
        
        RETURN json_build_object(
            'success', true,
            'locked', false,
            'lock_id', lock_record.id,
            'expires_at', lock_record.expires_at,
            'message', 'Lock acquired successfully'
        );
        
    EXCEPTION WHEN unique_violation THEN
        -- Lock was acquired by another user between check and insert
        SELECT * INTO lock_record
        FROM resource_locks
        WHERE resource_id = p_resource_id
        AND expires_at > NOW();
        
        IF lock_record.user_type = 'client' THEN
            SELECT CONCAT(client_name, ' ', client_surname) INTO user_name
            FROM client
            WHERE client_id = lock_record.user_id;
        ELSE
            SELECT CONCAT(service_provider_name, ' ', service_provider_surname) INTO user_name
            FROM service_provider
            WHERE service_provider_id = lock_record.user_id;
        END IF;
        
        RETURN json_build_object(
            'success', false,
            'locked', true,
            'locked_by', COALESCE(user_name, 'Unknown User'),
            'locked_at', lock_record.created_at,
            'expires_at', lock_record.expires_at,
            'message', 'Resource was locked by another user'
        );
    END;
END;
$$ LANGUAGE plpgsql;

-- Function to release lock
CREATE OR REPLACE FUNCTION release_resource_lock(
    p_resource_id TEXT,
    p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM resource_locks
    WHERE resource_id = p_resource_id
    AND user_id = p_user_id;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    IF deleted_count > 0 THEN
        RETURN json_build_object(
            'success', true,
            'message', 'Lock released successfully'
        );
    ELSE
        RETURN json_build_object(
            'success', false,
            'message', 'No lock found or not owned by user'
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to extend lock duration
CREATE OR REPLACE FUNCTION extend_resource_lock(
    p_resource_id TEXT,
    p_user_id UUID,
    p_additional_seconds INTEGER DEFAULT 300
)
RETURNS JSON AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE resource_locks
    SET 
        last_heartbeat = NOW(),
        expires_at = NOW() + (p_additional_seconds || ' seconds')::INTERVAL
    WHERE resource_id = p_resource_id
    AND user_id = p_user_id
    AND expires_at > NOW();
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    IF updated_count > 0 THEN
        RETURN json_build_object(
            'success', true,
            'message', 'Lock extended successfully'
        );
    ELSE
        RETURN json_build_object(
            'success', false,
            'message', 'Lock not found or expired'
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to clean up expired locks (if pg_cron is available)
-- SELECT cron.schedule('cleanup-expired-locks', '*/5 * * * *', 'SELECT cleanup_expired_locks();');

-- RLS Policies
ALTER TABLE resource_locks ENABLE ROW LEVEL SECURITY;

-- Policy: Users can see all locks but only modify their own
CREATE POLICY "Users can view all locks" ON resource_locks
    FOR SELECT USING (true);

-- Policy: Users can insert their own locks
CREATE POLICY "Users can create their own locks" ON resource_locks
    FOR INSERT WITH CHECK (user_id = auth.uid() OR user_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- Policy: Users can update their own locks (for heartbeat)
CREATE POLICY "Users can update their own locks" ON resource_locks
    FOR UPDATE USING (user_id = auth.uid() OR user_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- Policy: Users can delete their own locks
CREATE POLICY "Users can delete their own locks" ON resource_locks
    FOR DELETE USING (user_id = auth.uid() OR user_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- Comments for documentation
COMMENT ON TABLE resource_locks IS 'Manages concurrent access to resources to prevent data conflicts';
COMMENT ON COLUMN resource_locks.resource_id IS 'Unique identifier for the locked resource (format: table:record_id)';
COMMENT ON COLUMN resource_locks.resource_type IS 'Type of resource being locked (quotation, booking, etc.)';
COMMENT ON COLUMN resource_locks.resource_record_id IS 'The actual UUID of the record being locked';
COMMENT ON COLUMN resource_locks.user_id IS 'ID of the user holding the lock';
COMMENT ON COLUMN resource_locks.user_type IS 'Type of user (client or service_provider)';
COMMENT ON COLUMN resource_locks.operation IS 'Type of operation being performed (edit, delete, etc.)';
COMMENT ON COLUMN resource_locks.last_heartbeat IS 'Last time the lock was refreshed by the user';
COMMENT ON COLUMN resource_locks.expires_at IS 'When the lock will automatically expire';
