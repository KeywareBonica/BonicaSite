-- Fix job_cart table schema - add missing columns
-- This migration adds the missing columns that the application expects

-- Add quantity column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'quantity'
    ) THEN
        ALTER TABLE job_cart 
        ADD COLUMN quantity integer DEFAULT 1;
        
        RAISE NOTICE 'quantity column added to job_cart table';
    ELSE
        RAISE NOTICE 'quantity column already exists in job_cart table';
    END IF;
END $$;

-- Add service_id column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'service_id'
    ) THEN
        ALTER TABLE job_cart 
        ADD COLUMN service_id uuid REFERENCES service(service_id);
        
        CREATE INDEX idx_job_cart_service_id ON job_cart(service_id);
        
        RAISE NOTICE 'service_id column added to job_cart table';
    ELSE
        RAISE NOTICE 'service_id column already exists in job_cart table';
    END IF;
END $$;

-- Add client_id column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'client_id'
    ) THEN
        ALTER TABLE job_cart 
        ADD COLUMN client_id uuid REFERENCES client(client_id) ON DELETE CASCADE;
        
        CREATE INDEX idx_job_cart_client_id ON job_cart(client_id);
        
        RAISE NOTICE 'client_id column added to job_cart table';
    ELSE
        RAISE NOTICE 'client_id column already exists in job_cart table';
    END IF;
END $$;

-- Make event_id nullable since we're adding client_id as the primary relationship
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'event_id' AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE job_cart 
        ALTER COLUMN event_id DROP NOT NULL;
        
        RAISE NOTICE 'event_id column made nullable in job_cart table';
    ELSE
        RAISE NOTICE 'event_id column is already nullable in job_cart table';
    END IF;
END $$;

-- Add composite indexes for better performance
CREATE INDEX IF NOT EXISTS idx_job_cart_client_service ON job_cart(client_id, service_id);
CREATE INDEX IF NOT EXISTS idx_job_cart_status ON job_cart(job_cart_status);
CREATE INDEX IF NOT EXISTS idx_job_cart_created_at ON job_cart(created_at);
