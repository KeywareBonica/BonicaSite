-- Add declined_by field to job_cart table to track which service provider declined it
-- This allows us to show declined job carts to other service providers but hide them from the one who declined

-- Add the declined_by column
ALTER TABLE job_cart ADD COLUMN IF NOT EXISTS declined_by uuid REFERENCES service_provider(service_provider_id);

-- Add comment for documentation
COMMENT ON COLUMN job_cart.declined_by IS 'Service provider who declined this job cart - used to filter out declined jobs for that specific provider';

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_job_cart_declined_by ON job_cart(declined_by);

