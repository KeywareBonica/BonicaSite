-- Make event_id nullable in job_cart table temporarily
-- This allows job cart entries to be created before events
-- Run this in your Supabase SQL editor

-- Make event_id nullable in job_cart table
ALTER TABLE job_cart ALTER COLUMN event_id DROP NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN job_cart.event_id IS 'Foreign key to event table - can be null until event is created, then updated';

-- Verify the change
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'job_cart' 
AND column_name = 'event_id';
