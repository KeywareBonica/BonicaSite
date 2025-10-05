-- Add service_id column to job_cart table to properly link job carts to services
ALTER TABLE job_cart 
ADD COLUMN service_id uuid REFERENCES service(service_id);

-- Create index for better performance on service-based queries
CREATE INDEX idx_job_cart_service_id ON job_cart(service_id);

-- Create composite index for efficient filtering
CREATE INDEX idx_job_cart_service_status ON job_cart(service_id, job_cart_status);

-- Add comment for documentation
COMMENT ON COLUMN job_cart.service_id IS 'Links job cart to the specific service type for proper service provider matching';
