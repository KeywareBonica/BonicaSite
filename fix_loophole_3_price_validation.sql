-- === FIX LOOPHOLE 3: Price Validation ===
-- Validate quotation price against event budget (min/max price)

CREATE OR REPLACE FUNCTION check_quotation_price()
RETURNS TRIGGER AS $$
DECLARE
    event_min_price NUMERIC;
    event_max_price NUMERIC;
BEGIN
    -- Get event min/max price for this job cart
    SELECT e.booking_min_price, e.booking_max_price 
    INTO event_min_price, event_max_price
    FROM job_cart jc
    JOIN event e ON jc.event_id = e.event_id
    WHERE jc.job_cart_id = NEW.job_cart_id;
    
    -- Only validate if event has price limits set
    IF event_min_price IS NOT NULL AND event_max_price IS NOT NULL THEN
        -- Check if quotation price is within event budget
        IF NEW.quotation_price < event_min_price THEN
            RAISE EXCEPTION 'Quotation price (%.2f) is below event minimum budget (%.2f)', 
                NEW.quotation_price, event_min_price;
        END IF;
        
        IF NEW.quotation_price > event_max_price THEN
            RAISE EXCEPTION 'Quotation price (%.2f) exceeds event maximum budget (%.2f)', 
                NEW.quotation_price, event_max_price;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to enforce price validation
DROP TRIGGER IF EXISTS trg_check_quotation_price ON public.quotation;
CREATE TRIGGER trg_check_quotation_price
    BEFORE INSERT OR UPDATE ON public.quotation
    FOR EACH ROW
    EXECUTE FUNCTION check_quotation_price();


