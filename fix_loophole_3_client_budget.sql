-- === FIX LOOPHOLE 3: Client-Specific Budget Validation ===
-- Validate quotation price against client's specific service budget in job_cart

CREATE OR REPLACE FUNCTION check_quotation_price_client_budget()
RETURNS TRIGGER AS $$
DECLARE
    job_cart_min_price NUMERIC;
    job_cart_max_price NUMERIC;
BEGIN
    -- Get client's min/max price for this specific job cart
    SELECT jc.job_cart_min_price, jc.job_cart_max_price
    INTO job_cart_min_price, job_cart_max_price
    FROM job_cart jc
    WHERE jc.job_cart_id = NEW.job_cart_id;
    
    -- Only validate if client has set price limits for this service
    IF job_cart_min_price IS NOT NULL AND job_cart_max_price IS NOT NULL THEN
        -- Check if quotation price is within client's budget for this service
        IF NEW.quotation_price < job_cart_min_price THEN
            RAISE EXCEPTION 'Quotation price (%.2f) is below client minimum budget (%.2f) for this service', 
                NEW.quotation_price, job_cart_min_price;
        END IF;
        
        IF NEW.quotation_price > job_cart_max_price THEN
            RAISE EXCEPTION 'Quotation price (%.2f) exceeds client maximum budget (%.2f) for this service', 
                NEW.quotation_price, job_cart_max_price;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop old trigger and create new client-budget one
DROP TRIGGER IF EXISTS trg_check_quotation_price_improved ON public.quotation;
CREATE TRIGGER trg_check_quotation_price_client_budget
    BEFORE INSERT OR UPDATE ON public.quotation
    FOR EACH ROW
    EXECUTE FUNCTION check_quotation_price_client_budget();


