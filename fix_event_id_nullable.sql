-- Make event_id column nullable in job_cart table
-- Run this in your Supabase SQL editor

-- Make event_id nullable
ALTER TABLE job_cart ALTER COLUMN event_id DROP NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN job_cart.event_id IS 'Event ID - can be null until event is created';

-- Verify the change
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'job_cart' 
AND column_name = 'event_id';
