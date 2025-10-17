-- === FIX LOOPHOLE 2: Quotation Limits ===
-- Limit quotations per job cart to prevent spam

-- Add a limit (e.g., maximum 10 quotations per job cart)
CREATE OR REPLACE FUNCTION check_quotation_limit()
RETURNS TRIGGER AS $$
DECLARE
    quotation_count INTEGER;
BEGIN
    -- Count existing quotations for this job cart
    SELECT COUNT(*) INTO quotation_count
    FROM quotation
    WHERE job_cart_id = NEW.job_cart_id;
    
    -- Check if limit exceeded (set to 10, you can change this number)
    IF quotation_count >= 10 THEN
        RAISE EXCEPTION 'Maximum quotations limit reached for this job cart (limit: 10)';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to enforce the limit
DROP TRIGGER IF EXISTS trg_check_quotation_limit ON public.quotation;
CREATE TRIGGER trg_check_quotation_limit
    BEFORE INSERT ON public.quotation
    FOR EACH ROW
    EXECUTE FUNCTION check_quotation_limit();







