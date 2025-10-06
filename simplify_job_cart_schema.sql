-- Simplify job_cart table to use only service_id foreign key
-- Run this in your Supabase SQL editor

-- Remove the old columns
ALTER TABLE job_cart DROP COLUMN IF EXISTS job_cart_details;
ALTER TABLE job_cart DROP COLUMN IF EXISTS job_cart_item;

-- Remove quantity column since each service creates a separate job cart entry
ALTER TABLE job_cart DROP COLUMN IF EXISTS quantity;

-- Ensure service_id column exists and has proper foreign key
ALTER TABLE job_cart 
ADD COLUMN IF NOT EXISTS service_id uuid REFERENCES service(service_id);

-- Create index for service_id
CREATE INDEX IF NOT EXISTS idx_job_cart_service_id ON job_cart(service_id);

-- Create composite index for client and service
CREATE INDEX IF NOT EXISTS idx_job_cart_client_service ON job_cart(client_id, service_id);

-- Add comment for documentation
COMMENT ON COLUMN job_cart.service_id IS 'Reference to the service being added to cart';

-- The job_cart table now represents: "Client X wants Service Y" (one entry per service)
-- Each service selection creates a separate job cart entry - no quantity needed
