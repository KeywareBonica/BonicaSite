-- Populate booking_total_price for all existing booking records
-- This script updates every booking record with a realistic total price
-- based on the booking_min_price and booking_max_price ranges

-- First, let's see what we're working with
SELECT 
    COUNT(*) as total_bookings,
    COUNT(booking_total_price) as bookings_with_price,
    COUNT(*) - COUNT(booking_total_price) as bookings_without_price
FROM booking;

-- Update booking_total_price for records that don't have it set
-- Use a realistic price between min and max, or generate based on event type
UPDATE booking 
SET booking_total_price = CASE 
    -- If we have both min and max prices, use a value in between
    WHEN booking_min_price IS NOT NULL AND booking_max_price IS NOT NULL 
    THEN ROUND(
        (booking_min_price::numeric + (booking_max_price::numeric - booking_min_price::numeric) * (0.3 + RANDOM() * 0.4))::numeric,
        2
    )
    
    -- If we only have min price, add 20-50% to it
    WHEN booking_min_price IS NOT NULL AND booking_max_price IS NULL
    THEN ROUND((booking_min_price::numeric * (1.2 + RANDOM() * 0.3))::numeric, 2)
    
    -- If we only have max price, use 60-90% of it
    WHEN booking_min_price IS NULL AND booking_max_price IS NOT NULL
    THEN ROUND((booking_max_price::numeric * (0.6 + RANDOM() * 0.3))::numeric, 2)
    
    -- If we have neither, generate based on event type (if available)
    WHEN booking_min_price IS NULL AND booking_max_price IS NULL
    THEN CASE 
        -- Get event type from event table and set realistic prices
        WHEN EXISTS (
            SELECT 1 FROM event e 
            WHERE e.event_id = booking.event_id 
            AND e.event_type ILIKE '%wedding%'
        ) THEN ROUND((15000 + RANDOM() * 35000)::numeric, 2) -- R15,000 - R50,000
        
        WHEN EXISTS (
            SELECT 1 FROM event e 
            WHERE e.event_id = booking.event_id 
            AND e.event_type ILIKE '%corporate%'
        ) THEN ROUND((8000 + RANDOM() * 22000)::numeric, 2) -- R8,000 - R30,000
        
        WHEN EXISTS (
            SELECT 1 FROM event e 
            WHERE e.event_id = booking.event_id 
            AND e.event_type ILIKE '%birthday%'
        ) THEN ROUND((3000 + RANDOM() * 12000)::numeric, 2) -- R3,000 - R15,000
        
        WHEN EXISTS (
            SELECT 1 FROM event e 
            WHERE e.event_id = booking.event_id 
            AND e.event_type ILIKE '%party%'
        ) THEN ROUND((2000 + RANDOM() * 8000)::numeric, 2) -- R2,000 - R10,000
        
        ELSE ROUND((5000 + RANDOM() * 15000)::numeric, 2) -- R5,000 - R20,000 default
    END
    
    ELSE booking_total_price -- Keep existing value if it exists
END
WHERE booking_total_price IS NULL;

-- Verify the update
SELECT 
    COUNT(*) as total_bookings,
    COUNT(booking_total_price) as bookings_with_price,
    COUNT(*) - COUNT(booking_total_price) as bookings_without_price,
    ROUND(AVG(booking_total_price)::numeric, 2) as avg_total_price,
    ROUND(MIN(booking_total_price)::numeric, 2) as min_total_price,
    ROUND(MAX(booking_total_price)::numeric, 2) as max_total_price
FROM booking;

-- Show some sample records with their prices
SELECT 
    booking_id,
    booking_date,
    booking_status,
    booking_min_price,
    booking_max_price,
    booking_total_price,
    e.event_type
FROM booking b
LEFT JOIN event e ON e.event_id = b.event_id
ORDER BY booking_total_price DESC
LIMIT 10;

-- Show price distribution by event type
SELECT 
    e.event_type,
    COUNT(*) as booking_count,
    ROUND(AVG(b.booking_total_price)::numeric, 2) as avg_price,
    ROUND(MIN(b.booking_total_price)::numeric, 2) as min_price,
    ROUND(MAX(b.booking_total_price)::numeric, 2) as max_price,
    ROUND(SUM(b.booking_total_price)::numeric, 2) as total_revenue
FROM booking b
LEFT JOIN event e ON e.event_id = b.event_id
WHERE b.booking_total_price IS NOT NULL
GROUP BY e.event_type
ORDER BY total_revenue DESC;

-- Show revenue by booking status
SELECT 
    booking_status,
    COUNT(*) as booking_count,
    ROUND(AVG(booking_total_price)::numeric, 2) as avg_price,
    ROUND(SUM(booking_total_price)::numeric, 2) as total_revenue
FROM booking
WHERE booking_total_price IS NOT NULL
GROUP BY booking_status
ORDER BY total_revenue DESC;

-- Show monthly revenue trend
SELECT 
    DATE_TRUNC('month', booking_date) as month,
    COUNT(*) as booking_count,
    ROUND(SUM(booking_total_price)::numeric, 2) as monthly_revenue
FROM booking
WHERE booking_total_price IS NOT NULL
GROUP BY DATE_TRUNC('month', booking_date)
ORDER BY month DESC
LIMIT 12;
