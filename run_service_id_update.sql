-- Simple script to add service_id to quotation table
-- Run this in your Supabase SQL editor

-- Add service_id column to quotation table
ALTER TABLE quotation 
ADD COLUMN IF NOT EXISTS service_id uuid REFERENCES service(service_id) ON DELETE CASCADE;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_quotation_service_id ON quotation(service_id);

-- Update existing quotations to link them to services based on job_cart.service_id
UPDATE quotation 
SET service_id = jc.service_id
FROM job_cart jc
WHERE quotation.job_cart_id = jc.job_cart_id
AND quotation.service_id IS NULL;

-- Verify the updates
SELECT 
    q.quotation_id,
    q.quotation_price,
    q.service_id,
    s.service_name,
    sp.service_provider_name
FROM quotation q
LEFT JOIN service s ON q.service_id = s.service_id
LEFT JOIN service_provider sp ON q.service_provider_id = sp.service_provider_id
ORDER BY q.created_at DESC
LIMIT 10;
