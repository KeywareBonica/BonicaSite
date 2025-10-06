-- Complete fix for job_cart table to work with text service IDs
-- Run this in your Supabase SQL editor

-- Step 1: Check if service_id column exists, if not create it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'service_id'
    ) THEN
        -- Add service_id as text column
        ALTER TABLE job_cart ADD COLUMN service_id text;
        RAISE NOTICE 'service_id column added as text';
    ELSE
        RAISE NOTICE 'service_id column already exists';
    END IF;
END $$;

-- Step 2: Drop any existing foreign key constraints
ALTER TABLE job_cart DROP CONSTRAINT IF EXISTS job_cart_service_id_fkey;

-- Step 3: Change service_id to text type (if it exists and is not already text)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' 
        AND column_name = 'service_id' 
        AND data_type = 'uuid'
    ) THEN
        ALTER TABLE job_cart ALTER COLUMN service_id TYPE text;
        RAISE NOTICE 'service_id column changed from uuid to text';
    ELSE
        RAISE NOTICE 'service_id column is already text or does not exist';
    END IF;
END $$;

-- Step 4: Remove old columns that we don't need
ALTER TABLE job_cart DROP COLUMN IF EXISTS job_cart_details;
ALTER TABLE job_cart DROP COLUMN IF EXISTS job_cart_item;
ALTER TABLE job_cart DROP COLUMN IF EXISTS quantity;

-- Step 5: Ensure client_id column exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'client_id'
    ) THEN
        ALTER TABLE job_cart ADD COLUMN client_id uuid REFERENCES client(client_id) ON DELETE CASCADE;
        RAISE NOTICE 'client_id column added';
    ELSE
        RAISE NOTICE 'client_id column already exists';
    END IF;
END $$;

-- Step 6: Make event_id nullable
ALTER TABLE job_cart ALTER COLUMN event_id DROP NOT NULL;

-- Step 7: Create indexes
DROP INDEX IF EXISTS idx_job_cart_service_id;
CREATE INDEX idx_job_cart_service_id ON job_cart(service_id);

DROP INDEX IF EXISTS idx_job_cart_client_id;
CREATE INDEX idx_job_cart_client_id ON job_cart(client_id);

DROP INDEX IF EXISTS idx_job_cart_client_service;
CREATE INDEX idx_job_cart_client_service ON job_cart(client_id, service_id);

-- Step 8: Add comments
COMMENT ON COLUMN job_cart.service_id IS 'Service identifier (text like fb-photo, fb-catering)';
COMMENT ON COLUMN job_cart.client_id IS 'Client who added this service to cart';

-- Final verification
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'job_cart' 
ORDER BY ordinal_position;
