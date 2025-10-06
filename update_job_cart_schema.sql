-- Update job_cart table to use service_provider_id foreign key
-- Run this in your Supabase SQL editor

-- Remove the old columns
ALTER TABLE job_cart DROP COLUMN IF EXISTS job_cart_details;
ALTER TABLE job_cart DROP COLUMN IF EXISTS job_cart_item;

-- Add service_provider_id foreign key
ALTER TABLE job_cart 
ADD COLUMN IF NOT EXISTS service_provider_id uuid REFERENCES service_provider(service_provider_id) ON DELETE CASCADE;

-- Create index for service_provider_id
CREATE INDEX IF NOT EXISTS idx_job_cart_service_provider_id ON job_cart(service_provider_id);

-- Create composite index for client and service provider
CREATE INDEX IF NOT EXISTS idx_job_cart_client_provider ON job_cart(client_id, service_provider_id);

-- Add comment for documentation
COMMENT ON COLUMN job_cart.service_provider_id IS 'Reference to the service provider who will handle this job';

-- Update the table structure to be more logical:
-- job_cart now represents: "Client X wants Service Y from Provider Z"
-- This makes it easier to track which provider is handling which service for which client
