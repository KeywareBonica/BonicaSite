-- Run all necessary migrations to fix the client_id relationship issues
-- Execute these commands in your Supabase SQL editor or database client

-- 1. First, ensure service_id column exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'service_id'
    ) THEN
        ALTER TABLE job_cart 
        ADD COLUMN service_id uuid REFERENCES service(service_id);
        
        CREATE INDEX idx_job_cart_service_id ON job_cart(service_id);
        CREATE INDEX idx_job_cart_service_status ON job_cart(service_id, job_cart_status);
        
        RAISE NOTICE 'service_id column added to job_cart table';
    ELSE
        RAISE NOTICE 'service_id column already exists in job_cart table';
    END IF;
END $$;

-- 2. Add client_id column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'client_id'
    ) THEN
        ALTER TABLE job_cart 
        ADD COLUMN client_id uuid REFERENCES client(client_id) ON DELETE CASCADE;
        
        CREATE INDEX idx_job_cart_client_id ON job_cart(client_id);
        CREATE INDEX idx_job_cart_client_service ON job_cart(client_id, service_id);
        
        RAISE NOTICE 'client_id column added to job_cart table';
    ELSE
        RAISE NOTICE 'client_id column already exists in job_cart table';
    END IF;
END $$;

-- 3. Update existing job carts with client_id (if they don't have it)
UPDATE job_cart 
SET client_id = (
    SELECT b.client_id 
    FROM booking b 
    WHERE b.event_id = job_cart.event_id 
    LIMIT 1
)
WHERE client_id IS NULL;

-- 4. Verify the changes
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'job_cart' 
AND column_name IN ('client_id', 'service_id')
ORDER BY column_name;

-- 5. Check job cart data
SELECT 
    job_cart_id,
    client_id,
    service_id,
    job_cart_item,
    job_cart_status
FROM job_cart 
LIMIT 5;
