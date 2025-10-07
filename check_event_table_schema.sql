-- Check the actual schema of the event table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'event' 
ORDER BY ordinal_position;

