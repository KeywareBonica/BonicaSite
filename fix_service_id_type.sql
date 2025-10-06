-- Fix service_id column type to accept text instead of UUID
-- Run this in your Supabase SQL editor

-- First, drop the foreign key constraint
ALTER TABLE job_cart DROP CONSTRAINT IF EXISTS job_cart_service_id_fkey;

-- Change service_id from uuid to text to allow simple IDs like "fb-photo"
ALTER TABLE job_cart ALTER COLUMN service_id TYPE text;

-- Recreate the index for the text column
DROP INDEX IF EXISTS idx_job_cart_service_id;
CREATE INDEX idx_job_cart_service_id ON job_cart(service_id);

-- Update the composite index
DROP INDEX IF EXISTS idx_job_cart_client_service;
CREATE INDEX idx_job_cart_client_service ON job_cart(client_id, service_id);

-- Add comment for documentation
COMMENT ON COLUMN job_cart.service_id IS 'Reference to the service being added to cart (text ID like fb-photo)';

-- Now the job_cart table can accept service IDs like "fb-photo", "fb-catering", etc.
