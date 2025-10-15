-- Fix NULL event locations in your database
-- This will populate missing event_location data

-- First, let's see how many events have NULL locations
SELECT 'Events with NULL location:' as info, COUNT(*) as count 
FROM event 
WHERE event_location IS NULL;

-- Show some examples
SELECT 'Sample events with NULL location:' as info, event_id, event_type, event_date 
FROM event 
WHERE event_location IS NULL 
LIMIT 5;

-- Update NULL locations with placeholder text (you can customize these)
UPDATE event 
SET event_location = 'Location to be confirmed'
WHERE event_location IS NULL;

-- Verify the fix
SELECT 'After fix - Events with NULL location:' as info, COUNT(*) as count 
FROM event 
WHERE event_location IS NULL;

-- Show updated examples
SELECT 'Updated events:' as info, event_id, event_type, event_date, event_location 
FROM event 
WHERE event_location = 'Location to be confirmed'
LIMIT 3;
