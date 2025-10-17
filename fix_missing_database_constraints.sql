-- ============================================================================
-- FIX MISSING DATABASE CONSTRAINTS
-- ============================================================================
-- This script adds critical constraints that are missing from the production
-- database to enforce business rules and data integrity.
--
-- RUN THIS ON YOUR SUPABASE DATABASE!
-- ============================================================================

-- ============================================================================
-- CONSTRAINT #1: Add Foreign Key for job_cart.accepted_quotation_id
-- ============================================================================
-- PROBLEM: job_cart.accepted_quotation_id exists but has NO foreign key constraint
-- IMPACT: Database could have invalid quotation IDs that don't exist
-- FIX: Add foreign key constraint

DO $$ 
BEGIN
    -- Check if constraint already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'job_cart_accepted_quotation_fkey'
    ) THEN
        RAISE NOTICE 'Adding foreign key constraint: job_cart.accepted_quotation_id → quotation.quotation_id';
        
        ALTER TABLE public.job_cart
        ADD CONSTRAINT job_cart_accepted_quotation_fkey
        FOREIGN KEY (accepted_quotation_id)
        REFERENCES public.quotation(quotation_id)
        ON DELETE SET NULL;  -- If quotation deleted, set field to NULL
        
        RAISE NOTICE '✅ Foreign key constraint added successfully';
    ELSE
        RAISE NOTICE '✓ Foreign key constraint already exists';
    END IF;
END $$;


-- ============================================================================
-- CONSTRAINT #2: Prevent Multiple Accepted Quotations per Job Cart
-- ============================================================================
-- PROBLEM: Multiple quotations can have status='accepted' for same job_cart_id
-- BUSINESS RULE: Only ONE quotation per job_cart can be accepted
-- FIX: Add unique partial index

DO $$ 
BEGIN
    -- Check if index already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'uq_one_accepted_per_job_cart'
    ) THEN
        RAISE NOTICE 'Creating unique index: Only one accepted quotation per job_cart';
        
        -- This allows:
        --   - Multiple 'pending' quotations per job_cart ✅
        --   - Multiple 'rejected' quotations per job_cart ✅
        --   - Only ONE 'accepted' quotation per job_cart ✅
        CREATE UNIQUE INDEX uq_one_accepted_per_job_cart
        ON public.quotation (job_cart_id)
        WHERE quotation_status = 'accepted';
        
        RAISE NOTICE '✅ Unique index created successfully';
    ELSE
        RAISE NOTICE '✓ Unique index already exists';
    END IF;
END $$;


-- ============================================================================
-- CONSTRAINT #3: Ensure job_cart price range is valid
-- ============================================================================
-- PROBLEM: job_cart_max_price could be less than job_cart_min_price
-- BUSINESS RULE: Max price must be >= Min price
-- FIX: Add check constraint

DO $$ 
BEGIN
    -- Check if constraint already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'job_cart_price_range_check'
    ) THEN
        RAISE NOTICE 'Adding check constraint: max_price >= min_price';
        
        ALTER TABLE public.job_cart
        ADD CONSTRAINT job_cart_price_range_check
        CHECK (
            job_cart_max_price IS NULL 
            OR job_cart_min_price IS NULL 
            OR job_cart_max_price >= job_cart_min_price
        );
        
        RAISE NOTICE '✅ Check constraint added successfully';
    ELSE
        RAISE NOTICE '✓ Check constraint already exists';
    END IF;
END $$;


-- ============================================================================
-- CONSTRAINT #4: Ensure quotation price is within job_cart budget range
-- ============================================================================
-- PROBLEM: Service providers could submit quotations outside client's budget
-- BUSINESS RULE: Quotation price should be within job_cart min/max range
-- FIX: Add trigger function to validate prices

-- First, create the validation function
CREATE OR REPLACE FUNCTION validate_quotation_price()
RETURNS TRIGGER AS $$
DECLARE
    v_min_price NUMERIC;
    v_max_price NUMERIC;
    v_service_name TEXT;
BEGIN
    -- Get the job_cart budget range
    SELECT 
        job_cart_min_price, 
        job_cart_max_price,
        s.service_name
    INTO v_min_price, v_max_price, v_service_name
    FROM public.job_cart jc
    LEFT JOIN public.service s ON jc.service_id = s.service_id
    WHERE jc.job_cart_id = NEW.job_cart_id;
    
    -- Log the validation attempt
    RAISE NOTICE 'Validating quotation price R% for service "%" (Budget: R% - R%)', 
        NEW.quotation_price, 
        v_service_name,
        v_min_price, 
        v_max_price;
    
    -- Allow quotation if no budget range specified
    IF v_min_price IS NULL AND v_max_price IS NULL THEN
        RAISE NOTICE '✓ No budget range specified - quotation accepted';
        RETURN NEW;
    END IF;
    
    -- Warn if price is below minimum (but allow it)
    IF v_min_price IS NOT NULL AND NEW.quotation_price < v_min_price THEN
        RAISE WARNING '⚠️ Quotation price (R%) is below client minimum (R%) - quotation allowed but may not be competitive', 
            NEW.quotation_price, v_min_price;
    END IF;
    
    -- Warn if price is above maximum (but allow it)
    IF v_max_price IS NOT NULL AND NEW.quotation_price > v_max_price THEN
        RAISE WARNING '⚠️ Quotation price (R%) exceeds client maximum (R%) - quotation allowed but may be rejected by client', 
            NEW.quotation_price, v_max_price;
    END IF;
    
    -- Allow the quotation (just warn, don't block)
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger (if doesn't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trg_validate_quotation_price'
    ) THEN
        RAISE NOTICE 'Creating trigger: validate_quotation_price';
        
        CREATE TRIGGER trg_validate_quotation_price
        BEFORE INSERT OR UPDATE ON public.quotation
        FOR EACH ROW
        EXECUTE FUNCTION validate_quotation_price();
        
        RAISE NOTICE '✅ Trigger created successfully';
    ELSE
        RAISE NOTICE '✓ Trigger already exists';
    END IF;
END $$;


-- ============================================================================
-- CONSTRAINT #5: Ensure accepted_quotation_id matches quotation_status
-- ============================================================================
-- PROBLEM: job_cart.accepted_quotation_id might point to quotation that isn't 'accepted'
-- FIX: Add trigger to keep them in sync

CREATE OR REPLACE FUNCTION sync_accepted_quotation()
RETURNS TRIGGER AS $$
BEGIN
    -- When quotation is accepted, update job_cart
    IF NEW.quotation_status = 'accepted' AND (OLD.quotation_status IS NULL OR OLD.quotation_status != 'accepted') THEN
        RAISE NOTICE 'Quotation % accepted - updating job_cart %', NEW.quotation_id, NEW.job_cart_id;
        
        UPDATE public.job_cart
        SET accepted_quotation_id = NEW.quotation_id,
            job_cart_status = 'quotation_accepted'
        WHERE job_cart_id = NEW.job_cart_id;
        
        RAISE NOTICE '✅ job_cart updated with accepted quotation';
    END IF;
    
    -- When quotation is rejected/withdrawn, clear job_cart if it pointed to this one
    IF NEW.quotation_status IN ('rejected', 'withdrawn') AND OLD.quotation_status = 'accepted' THEN
        RAISE NOTICE 'Quotation % status changed from accepted to % - clearing job_cart', NEW.quotation_id, NEW.quotation_status;
        
        UPDATE public.job_cart
        SET accepted_quotation_id = NULL,
            job_cart_status = 'pending'
        WHERE job_cart_id = NEW.job_cart_id
        AND accepted_quotation_id = NEW.quotation_id;
        
        RAISE NOTICE '✅ job_cart cleared';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger (if doesn't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trg_sync_accepted_quotation'
    ) THEN
        RAISE NOTICE 'Creating trigger: sync_accepted_quotation';
        
        CREATE TRIGGER trg_sync_accepted_quotation
        AFTER UPDATE ON public.quotation
        FOR EACH ROW
        WHEN (OLD.quotation_status IS DISTINCT FROM NEW.quotation_status)
        EXECUTE FUNCTION sync_accepted_quotation();
        
        RAISE NOTICE '✅ Trigger created successfully';
    ELSE
        RAISE NOTICE '✓ Trigger already exists';
    END IF;
END $$;


-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if all constraints were added
SELECT 
    '✅ All constraints verification:' as status;

-- 1. Check foreign key
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_constraint 
            WHERE conname = 'job_cart_accepted_quotation_fkey'
        ) THEN '✅ Foreign key exists'
        ELSE '❌ Foreign key missing'
    END as "FK: accepted_quotation_id";

-- 2. Check unique index
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE indexname = 'uq_one_accepted_per_job_cart'
        ) THEN '✅ Unique index exists'
        ELSE '❌ Unique index missing'
    END as "Index: one_accepted_per_job_cart";

-- 3. Check price range constraint
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_constraint 
            WHERE conname = 'job_cart_price_range_check'
        ) THEN '✅ Check constraint exists'
        ELSE '❌ Check constraint missing'
    END as "Check: price_range";

-- 4. Check triggers
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_trigger 
            WHERE tgname = 'trg_validate_quotation_price'
        ) THEN '✅ Price validation trigger exists'
        ELSE '❌ Price validation trigger missing'
    END as "Trigger: validate_price";

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_trigger 
            WHERE tgname = 'trg_sync_accepted_quotation'
        ) THEN '✅ Sync trigger exists'
        ELSE '❌ Sync trigger missing'
    END as "Trigger: sync_accepted";


-- ============================================================================
-- TEST QUERIES (Optional - for verification)
-- ============================================================================

-- Show all job_carts with their accepted quotations
SELECT 
    jc.job_cart_id,
    jc.job_cart_status,
    jc.accepted_quotation_id,
    q.quotation_status,
    q.quotation_price
FROM public.job_cart jc
LEFT JOIN public.quotation q ON jc.accepted_quotation_id = q.quotation_id
WHERE jc.accepted_quotation_id IS NOT NULL
LIMIT 10;

-- Show any job_carts with multiple accepted quotations (should be 0!)
SELECT 
    job_cart_id,
    COUNT(*) as accepted_count
FROM public.quotation
WHERE quotation_status = 'accepted'
GROUP BY job_cart_id
HAVING COUNT(*) > 1;

-- If the above query returns any rows, you have data integrity issues!


-- ============================================================================
-- CLEANUP (if you need to remove everything and start fresh)
-- ============================================================================
/*
-- Uncomment to remove all constraints (USE WITH CAUTION!)

-- Drop triggers
DROP TRIGGER IF EXISTS trg_validate_quotation_price ON public.quotation;
DROP TRIGGER IF EXISTS trg_sync_accepted_quotation ON public.quotation;

-- Drop functions
DROP FUNCTION IF EXISTS validate_quotation_price();
DROP FUNCTION IF EXISTS sync_accepted_quotation();

-- Drop unique index
DROP INDEX IF EXISTS uq_one_accepted_per_job_cart;

-- Drop check constraint
ALTER TABLE public.job_cart DROP CONSTRAINT IF EXISTS job_cart_price_range_check;

-- Drop foreign key
ALTER TABLE public.job_cart DROP CONSTRAINT IF EXISTS job_cart_accepted_quotation_fkey;
*/

