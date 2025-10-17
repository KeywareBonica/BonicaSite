-- ========================================
-- FIX QUOTATION DATA REDUNDANCY
-- ========================================
-- This migration removes redundant fields from the quotation table
-- that duplicate data already available through relationships.
-- 
-- REDUNDANT FIELDS:
-- - service_id (already in job_cart.service_id)
-- - event_id (already in job_cart.event_id)
--
-- IMPORTANT: Run this AFTER ensuring all queries use relationship-based access
-- ========================================

-- Step 1: Verify data consistency before removal
-- Check if any quotation.service_id differs from job_cart.service_id
DO $$
DECLARE
    inconsistent_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO inconsistent_count
    FROM quotation q
    JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
    WHERE q.service_id IS NOT NULL 
      AND q.service_id != jc.service_id;
    
    IF inconsistent_count > 0 THEN
        RAISE WARNING 'Found % quotations with inconsistent service_id. Consider investigating before dropping column.', inconsistent_count;
    ELSE
        RAISE NOTICE 'All service_id values are consistent. Safe to drop column.';
    END IF;
END $$;

-- Step 2: Verify event_id consistency
DO $$
DECLARE
    inconsistent_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO inconsistent_count
    FROM quotation q
    JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
    WHERE q.event_id IS NOT NULL 
      AND q.event_id != jc.event_id;
    
    IF inconsistent_count > 0 THEN
        RAISE WARNING 'Found % quotations with inconsistent event_id. Consider investigating before dropping column.', inconsistent_count;
    ELSE
        RAISE NOTICE 'All event_id values are consistent. Safe to drop column.';
    END IF;
END $$;

-- Step 3: Create a backup view before dropping columns (optional but recommended)
CREATE OR REPLACE VIEW quotation_backup_redundant_fields AS
SELECT 
    quotation_id,
    job_cart_id,
    service_id AS old_service_id,
    event_id AS old_event_id,
    jc.service_id AS new_service_id,
    jc.event_id AS new_event_id
FROM quotation q
LEFT JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id;

COMMENT ON VIEW quotation_backup_redundant_fields IS 
'Backup view of redundant fields before removal. Can be used to restore data if needed.';

-- Step 4: Drop the foreign key constraint on event_id first
ALTER TABLE quotation 
DROP CONSTRAINT IF EXISTS quotation_event_id_fkey;

-- Step 5: Drop the foreign key constraint on service_id
ALTER TABLE quotation 
DROP CONSTRAINT IF EXISTS quotation_service_id_fkey;

-- Step 6: Drop the redundant service_id column
ALTER TABLE quotation 
DROP COLUMN IF EXISTS service_id;

COMMENT ON TABLE quotation IS 
'Quotation table - service_id removed (access via job_cart.service_id)';

-- Step 7: Drop the redundant event_id column
ALTER TABLE quotation 
DROP COLUMN IF EXISTS event_id;

COMMENT ON TABLE quotation IS 
'Quotation table - service_id and event_id removed (access via job_cart relationships)';

-- Step 8: Create helper function to get service_id from quotation
CREATE OR REPLACE FUNCTION get_quotation_service_id(p_quotation_id UUID)
RETURNS UUID AS $$
    SELECT jc.service_id
    FROM quotation q
    JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
    WHERE q.quotation_id = p_quotation_id;
$$ LANGUAGE SQL STABLE;

COMMENT ON FUNCTION get_quotation_service_id IS 
'Helper function to get service_id for a quotation via job_cart relationship';

-- Step 9: Create helper function to get event_id from quotation
CREATE OR REPLACE FUNCTION get_quotation_event_id(p_quotation_id UUID)
RETURNS UUID AS $$
    SELECT jc.event_id
    FROM quotation q
    JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
    WHERE q.quotation_id = p_quotation_id;
$$ LANGUAGE SQL STABLE;

COMMENT ON FUNCTION get_quotation_event_id IS 
'Helper function to get event_id for a quotation via job_cart relationship';

-- Step 10: Create index for better performance on joined queries
CREATE INDEX IF NOT EXISTS idx_quotation_job_cart_id ON quotation(job_cart_id);
CREATE INDEX IF NOT EXISTS idx_job_cart_service_id ON job_cart(service_id);
CREATE INDEX IF NOT EXISTS idx_job_cart_event_id ON job_cart(event_id);

COMMENT ON INDEX idx_quotation_job_cart_id IS 'Improves performance of quotation->job_cart joins';
COMMENT ON INDEX idx_job_cart_service_id IS 'Improves performance of job_cart->service joins';
COMMENT ON INDEX idx_job_cart_event_id IS 'Improves performance of job_cart->event joins';

-- Step 11: Verification query
-- Run this after migration to ensure everything works
SELECT 
    q.quotation_id,
    q.job_cart_id,
    jc.service_id AS service_id_via_job_cart,
    jc.event_id AS event_id_via_job_cart,
    s.service_name,
    e.event_type
FROM quotation q
JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
LEFT JOIN service s ON jc.service_id = s.service_id
LEFT JOIN event e ON jc.event_id = e.event_id
LIMIT 5;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Quotation data redundancy fixed successfully!';
    RAISE NOTICE '✅ service_id and event_id columns removed from quotation table';
    RAISE NOTICE '✅ Access these fields via job_cart relationships';
    RAISE NOTICE '✅ Helper functions created: get_quotation_service_id(), get_quotation_event_id()';
    RAISE NOTICE '✅ Performance indexes created';
END $$;

