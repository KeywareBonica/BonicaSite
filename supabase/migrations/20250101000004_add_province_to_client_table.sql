-- Add province column to client table to match use case requirements
-- This migration should be run to align with the use case document

-- First check if province column already exists
DO $$
BEGIN
    -- Add province column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'client' AND column_name = 'client_province'
    ) THEN
        ALTER TABLE client 
        ADD COLUMN client_province text;
        
        -- Add comment for documentation
        COMMENT ON COLUMN client.client_province IS 'Province where the client is located - added to match use case requirements';
        
        RAISE NOTICE 'client_province column added to client table successfully';
    ELSE
        RAISE NOTICE 'client_province column already exists in client table';
    END IF;
END $$;

-- Also add province to service_provider table for consistency
DO $$
BEGIN
    -- Add province column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'service_provider' AND column_name = 'service_provider_province'
    ) THEN
        ALTER TABLE service_provider 
        ADD COLUMN service_provider_province text;
        
        -- Add comment for documentation
        COMMENT ON COLUMN service_provider.service_provider_province IS 'Province where the service provider is located - added to match use case requirements';
        
        RAISE NOTICE 'service_provider_province column added to service_provider table successfully';
    ELSE
        RAISE NOTICE 'service_provider_province column already exists in service_provider table';
    END IF;
END $$;
