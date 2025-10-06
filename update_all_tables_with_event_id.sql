-- Update all tables to properly use event_id as foreign key
-- Run this in your Supabase SQL editor

-- 1. Ensure job_cart has proper event_id foreign key
DO $$
BEGIN
    -- Add event_id column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_cart' AND column_name = 'event_id'
    ) THEN
        ALTER TABLE job_cart ADD COLUMN event_id uuid;
        RAISE NOTICE 'event_id column added to job_cart table';
    ELSE
        RAISE NOTICE 'event_id column already exists in job_cart table';
    END IF;
END $$;

-- Add foreign key constraint for job_cart.event_id
ALTER TABLE job_cart DROP CONSTRAINT IF EXISTS job_cart_event_id_fkey;
ALTER TABLE job_cart ADD CONSTRAINT job_cart_event_id_fkey 
    FOREIGN KEY (event_id) REFERENCES event(event_id) ON DELETE CASCADE;

-- 2. Ensure booking table has proper event_id foreign key (should already exist)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'booking' AND column_name = 'event_id'
    ) THEN
        RAISE NOTICE 'booking.event_id already exists';
    ELSE
        ALTER TABLE booking ADD COLUMN event_id uuid REFERENCES event(event_id) ON DELETE CASCADE;
        RAISE NOTICE 'event_id column added to booking table';
    END IF;
END $$;

-- 3. Add event_id and booking_id to quotation table (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'quotation' AND column_name = 'event_id'
    ) THEN
        ALTER TABLE quotation ADD COLUMN event_id uuid REFERENCES event(event_id) ON DELETE CASCADE;
        RAISE NOTICE 'event_id column added to quotation table';
    ELSE
        RAISE NOTICE 'event_id column already exists in quotation table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'quotation' AND column_name = 'booking_id'
    ) THEN
        ALTER TABLE quotation ADD COLUMN booking_id uuid REFERENCES booking(booking_id) ON DELETE CASCADE;
        RAISE NOTICE 'booking_id column added to quotation table';
    ELSE
        RAISE NOTICE 'booking_id column already exists in quotation table';
    END IF;
END $$;

-- 4. Payment table removed - no longer needed

-- 4. Create event_service junction table for many-to-many relationship
CREATE TABLE IF NOT EXISTS event_service (
    event_service_id uuid primary key default gen_random_uuid(),
    event_id uuid not null references event(event_id) on delete cascade,
    service_id uuid not null references service(service_id) on delete cascade,
    event_service_notes text,
    created_at timestamp default now(),
    unique(event_id, service_id)
);

-- 5. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_job_cart_event_id ON job_cart(event_id);
CREATE INDEX IF NOT EXISTS idx_booking_event_id ON booking(event_id);
CREATE INDEX IF NOT EXISTS idx_quotation_event_id ON quotation(event_id);
CREATE INDEX IF NOT EXISTS idx_quotation_booking_id ON quotation(booking_id);
CREATE INDEX IF NOT EXISTS idx_event_service_event_id ON event_service(event_id);
CREATE INDEX IF NOT EXISTS idx_event_service_service_id ON event_service(service_id);

-- 6. Add comments for documentation
COMMENT ON COLUMN job_cart.event_id IS 'Foreign key to event table - links job cart items to specific events';
COMMENT ON COLUMN booking.event_id IS 'Foreign key to event table - links bookings to specific events';
COMMENT ON COLUMN quotation.event_id IS 'Foreign key to event table - links quotations to specific events';
COMMENT ON COLUMN quotation.booking_id IS 'Foreign key to booking table - links quotations to specific bookings';
COMMENT ON TABLE event_service IS 'Junction table for many-to-many relationship between events and services';

-- 7. Verify all foreign key relationships
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND ccu.table_name = 'event'
ORDER BY tc.table_name, kcu.column_name;
