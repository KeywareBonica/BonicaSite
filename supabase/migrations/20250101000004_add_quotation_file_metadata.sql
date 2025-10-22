-- Add additional file metadata fields to quotation table
ALTER TABLE quotation 
ADD COLUMN quotation_file_size bigint,
ADD COLUMN quotation_file_type text,
ADD COLUMN quotation_file_hash text,
ADD COLUMN quotation_file_validated boolean DEFAULT false;

-- Add index for better performance on file queries
CREATE INDEX idx_quotation_file_validated ON quotation(quotation_file_validated);
CREATE INDEX idx_quotation_file_path ON quotation(quotation_file_path);
