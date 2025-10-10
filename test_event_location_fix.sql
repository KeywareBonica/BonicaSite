-- Test and fix event_location issue
-- Run this in your Supabase SQL editor

-- 1. Check if event_location column exists
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'event' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. If event_location doesn't exist, add it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'event' 
        AND column_name = 'event_location'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE event ADD COLUMN event_location text;
        RAISE NOTICE 'Added event_location column to event table';
    ELSE
        RAISE NOTICE 'event_location column already exists';
    END IF;
END $$;

-- 3. Check current event data
SELECT 
    event_id,
    event_type,
    event_date,
    event_location,
    created_at
FROM event 
ORDER BY created_at DESC
LIMIT 5;

-- 4. Update any events that might have location data in a different column
-- (This is just in case the data was stored elsewhere)
UPDATE event 
SET event_location = COALESCE(event_location, 'Location not specified')
WHERE event_location IS NULL;

-- 5. Verify the fix
SELECT 
    COUNT(*) as total_events,
    COUNT(event_location) as events_with_location,
    COUNT(*) - COUNT(event_location) as events_without_location
FROM event;





