-- Add file metadata fields to payment table for better file management
ALTER TABLE payment 
ADD COLUMN proof_of_payment_file_path text,
ADD COLUMN proof_of_payment_file_name text,
ADD COLUMN proof_of_payment_file_size bigint,
ADD COLUMN proof_of_payment_file_type text,
ADD COLUMN proof_of_payment_file_hash text,
ADD COLUMN proof_of_payment_file_validated boolean DEFAULT false,
ADD COLUMN uploaded_at timestamp DEFAULT now(),
ADD COLUMN verification_date timestamp,
ADD COLUMN verification_notes text,
ADD COLUMN rejection_reason text,
ADD COLUMN payment_reference text;

-- Add indexes for better performance on payment queries
CREATE INDEX idx_payment_status ON payment(payment_status);
CREATE INDEX idx_payment_verification_date ON payment(verification_date);
CREATE INDEX idx_payment_file_validated ON payment(proof_of_payment_file_validated);
CREATE INDEX idx_payment_file_path ON payment(proof_of_payment_file_path);

-- Update existing records to migrate payment_proof to new structure
UPDATE payment 
SET proof_of_payment_file_path = payment_proof,
    proof_of_payment_file_validated = CASE 
        WHEN payment_proof IS NOT NULL AND payment_proof != '' THEN true 
        ELSE false 
    END
WHERE payment_proof IS NOT NULL AND payment_proof != '';
