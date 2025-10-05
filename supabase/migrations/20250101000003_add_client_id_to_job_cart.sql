-- Add client_id column to job_cart table to properly link job carts to clients
-- This migration should be run after the service_id migration

-- First check if client_id column already exists
DO $$
BEGIN
    -- Add client_id column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'client_id'
    ) THEN
        ALTER TABLE job_cart 
        ADD COLUMN client_id uuid REFERENCES client(client_id) ON DELETE CASCADE;
        
        -- Create index for better performance on client-based queries
        CREATE INDEX idx_job_cart_client_id ON job_cart(client_id);
        
        -- Create composite index for efficient filtering
        CREATE INDEX idx_job_cart_client_service ON job_cart(client_id, service_id);
        
        -- Add comment for documentation
        COMMENT ON COLUMN job_cart.client_id IS 'Direct link to the client who created this job cart for efficient querying';
        
        RAISE NOTICE 'client_id column added to job_cart table successfully';
    ELSE
        RAISE NOTICE 'client_id column already exists in job_cart table';
    END IF;
END $$;
