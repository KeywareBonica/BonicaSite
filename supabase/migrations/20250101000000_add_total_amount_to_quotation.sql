-- Add total_amount field to quotation table for revenue reporting
ALTER TABLE quotation 
ADD COLUMN total_amount numeric(10,2);

-- Update existing records to set total_amount equal to quotation_price
UPDATE quotation 
SET total_amount = quotation_price 
WHERE total_amount IS NULL;

-- Make total_amount not null after updating existing records
ALTER TABLE quotation 
ALTER COLUMN total_amount SET NOT NULL;

-- Add index for better performance on revenue queries
CREATE INDEX idx_quotation_total_amount ON quotation(total_amount);
CREATE INDEX idx_quotation_submission_date ON quotation(quotation_submission_date);
