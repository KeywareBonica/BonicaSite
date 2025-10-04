-- Fix service_id reference in service_provider table
-- Remove the foreign key constraint and change service_id to text

-- First, drop the foreign key constraint
ALTER TABLE service_provider DROP CONSTRAINT IF EXISTS service_provider_service_id_fkey;

-- Change service_id from uuid to text to allow simple IDs like "s1", "s2"
ALTER TABLE service_provider ALTER COLUMN service_id TYPE text;

-- Remove the reference to service table since we're using simple text IDs
-- This allows the service_provider to have any text value for service_id
