-- Fix job_cart table schema - add missing columns
-- Run this in your Supabase SQL editor to fix the job_cart table

-- Add quantity column
ALTER TABLE job_cart 
ADD COLUMN IF NOT EXISTS quantity integer DEFAULT 1;

-- Add service_id column
ALTER TABLE job_cart 
ADD COLUMN IF NOT EXISTS service_id uuid REFERENCES service(service_id);

-- Add client_id column
ALTER TABLE job_cart 
ADD COLUMN IF NOT EXISTS client_id uuid REFERENCES client(client_id) ON DELETE CASCADE;

-- Make event_id nullable (since we're using client_id as primary relationship)
ALTER TABLE job_cart 
ALTER COLUMN event_id DROP NOT NULL;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_job_cart_quantity ON job_cart(quantity);
CREATE INDEX IF NOT EXISTS idx_job_cart_service_id ON job_cart(service_id);
CREATE INDEX IF NOT EXISTS idx_job_cart_client_id ON job_cart(client_id);
CREATE INDEX IF NOT EXISTS idx_job_cart_client_service ON job_cart(client_id, service_id);
CREATE INDEX IF NOT EXISTS idx_job_cart_status ON job_cart(job_cart_status);
CREATE INDEX IF NOT EXISTS idx_job_cart_created_at ON job_cart(created_at);

-- Add comments for documentation
COMMENT ON COLUMN job_cart.quantity IS 'Number of items for this service in the cart';
COMMENT ON COLUMN job_cart.service_id IS 'Reference to the service being added to cart';
COMMENT ON COLUMN job_cart.client_id IS 'Reference to the client who owns this cart item';
