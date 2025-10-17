-- =====================================================
-- PAYMENT SYSTEM - COMMON QUERIES & UTILITIES
-- =====================================================
-- Useful queries for monitoring and managing the payment system
-- =====================================================

-- =====================================================
-- MONITORING QUERIES
-- =====================================================

-- 1. Get all pending payments (for admin dashboard)
SELECT 
    p.payment_id,
    p.payment_amount,
    p.payment_reference,
    p.uploaded_at,
    c.client_name || ' ' || c.client_surname as client_name,
    c.client_email,
    c.client_contact,
    e.event_type,
    e.event_date,
    b.booking_id
FROM payment p
JOIN booking b ON p.booking_id = b.booking_id
JOIN client c ON p.client_id = c.client_id
LEFT JOIN event e ON b.event_id = e.event_id
WHERE p.payment_status = 'pending'
ORDER BY p.uploaded_at DESC;

-- 2. Get today's verified payments
SELECT 
    COUNT(*) as verified_count,
    SUM(payment_amount) as total_amount
FROM payment
WHERE payment_status = 'verified'
AND DATE(verification_date) = CURRENT_DATE;

-- 3. Get today's rejected payments
SELECT 
    COUNT(*) as rejected_count,
    p.rejection_reason,
    c.client_email
FROM payment p
JOIN client c ON p.client_id = c.client_id
WHERE p.payment_status = 'rejected'
AND DATE(verification_date) = CURRENT_DATE
GROUP BY p.rejection_reason, c.client_email;

-- 4. Get payment statistics by status
SELECT 
    payment_status,
    COUNT(*) as count,
    SUM(payment_amount) as total_amount,
    AVG(payment_amount) as avg_amount
FROM payment
GROUP BY payment_status
ORDER BY payment_status;

-- 5. Get payment processing time (upload to verification)
SELECT 
    p.payment_id,
    p.uploaded_at,
    p.verification_date,
    AGE(p.verification_date, p.uploaded_at) as processing_time,
    p.payment_status
FROM payment p
WHERE p.verification_date IS NOT NULL
ORDER BY processing_time DESC
LIMIT 20;

-- =====================================================
-- CLIENT QUERIES
-- =====================================================

-- 6. Get all payments for a specific client
SELECT 
    p.payment_id,
    p.payment_amount,
    p.payment_status,
    p.uploaded_at,
    p.verification_date,
    p.rejection_reason,
    b.booking_id,
    e.event_type,
    e.event_date
FROM payment p
JOIN booking b ON p.booking_id = b.booking_id
LEFT JOIN event e ON b.event_id = e.event_id
WHERE p.client_id = 'CLIENT_ID_HERE'
ORDER BY p.uploaded_at DESC;

-- 7. Get unpaid bookings for a client
SELECT 
    b.booking_id,
    b.booking_date,
    b.booking_total_price,
    b.payment_status,
    e.event_type,
    e.event_date,
    e.event_location
FROM booking b
LEFT JOIN event e ON b.event_id = e.event_id
WHERE b.client_id = 'CLIENT_ID_HERE'
AND b.payment_status IN ('unpaid', 'pending_verification')
ORDER BY e.event_date ASC;

-- =====================================================
-- ADMIN QUERIES
-- =====================================================

-- 8. Get all payments verified by a specific admin
SELECT 
    COUNT(*) as total_verified,
    SUM(payment_amount) as total_amount,
    sp.service_provider_name || ' ' || sp.service_provider_surname as admin_name
FROM payment p
JOIN service_provider sp ON p.verified_by = sp.service_provider_id
WHERE p.verified_by = 'ADMIN_ID_HERE'
AND p.payment_status = 'verified'
GROUP BY admin_name;

-- 9. Get admin performance (verifications per day)
SELECT 
    DATE(verification_date) as date,
    COUNT(*) as verifications,
    SUM(CASE WHEN payment_status = 'verified' THEN 1 ELSE 0 END) as approved,
    SUM(CASE WHEN payment_status = 'rejected' THEN 1 ELSE 0 END) as rejected
FROM payment
WHERE verified_by IS NOT NULL
GROUP BY DATE(verification_date)
ORDER BY date DESC
LIMIT 30;

-- =====================================================
-- AUDIT & HISTORY QUERIES
-- =====================================================

-- 10. Get complete payment history for a booking
SELECT 
    h.history_id,
    h.old_status,
    h.new_status,
    h.change_reason,
    h.changed_at,
    h.changed_by_type,
    sp.service_provider_name || ' ' || sp.service_provider_surname as changed_by_name
FROM payment_status_history h
JOIN payment p ON h.payment_id = p.payment_id
LEFT JOIN service_provider sp ON h.changed_by = sp.service_provider_id
WHERE p.booking_id = 'BOOKING_ID_HERE'
ORDER BY h.changed_at DESC;

-- 11. Get all status changes in the last 24 hours
SELECT 
    p.payment_id,
    h.old_status,
    h.new_status,
    h.changed_at,
    c.client_name || ' ' || c.client_surname as client_name
FROM payment_status_history h
JOIN payment p ON h.payment_id = p.payment_id
JOIN client c ON p.client_id = c.client_id
WHERE h.changed_at >= NOW() - INTERVAL '24 hours'
ORDER BY h.changed_at DESC;

-- =====================================================
-- REPORTING QUERIES
-- =====================================================

-- 12. Monthly payment report
SELECT 
    TO_CHAR(uploaded_at, 'YYYY-MM') as month,
    COUNT(*) as total_payments,
    SUM(CASE WHEN payment_status = 'verified' THEN 1 ELSE 0 END) as verified,
    SUM(CASE WHEN payment_status = 'rejected' THEN 1 ELSE 0 END) as rejected,
    SUM(CASE WHEN payment_status = 'pending' THEN 1 ELSE 0 END) as pending,
    SUM(CASE WHEN payment_status = 'verified' THEN payment_amount ELSE 0 END) as total_revenue
FROM payment
GROUP BY TO_CHAR(uploaded_at, 'YYYY-MM')
ORDER BY month DESC;

-- 13. Payment method breakdown
SELECT 
    payment_method,
    COUNT(*) as count,
    SUM(payment_amount) as total_amount,
    AVG(payment_amount) as avg_amount
FROM payment
WHERE payment_status = 'verified'
GROUP BY payment_method
ORDER BY count DESC;

-- 14. Average processing time by admin
SELECT 
    sp.service_provider_name || ' ' || sp.service_provider_surname as admin_name,
    COUNT(*) as payments_processed,
    AVG(AGE(p.verification_date, p.uploaded_at)) as avg_processing_time
FROM payment p
JOIN service_provider sp ON p.verified_by = sp.service_provider_id
WHERE p.verification_date IS NOT NULL
GROUP BY admin_name
ORDER BY avg_processing_time ASC;

-- =====================================================
-- CLEANUP & MAINTENANCE QUERIES
-- =====================================================

-- 15. Find payments stuck in pending for more than 7 days
SELECT 
    p.payment_id,
    p.uploaded_at,
    AGE(NOW(), p.uploaded_at) as time_pending,
    c.client_name || ' ' || c.client_surname as client_name,
    c.client_email,
    p.payment_amount
FROM payment p
JOIN client c ON p.client_id = c.client_id
WHERE p.payment_status = 'pending'
AND p.uploaded_at < NOW() - INTERVAL '7 days'
ORDER BY p.uploaded_at ASC;

-- 16. Find duplicate payment submissions for same booking
SELECT 
    booking_id,
    COUNT(*) as payment_count,
    ARRAY_AGG(payment_id) as payment_ids,
    ARRAY_AGG(payment_status) as statuses
FROM payment
GROUP BY booking_id
HAVING COUNT(*) > 1
ORDER BY payment_count DESC;

-- 17. Delete old rejected payments (older than 30 days)
-- CAUTION: Only run after backing up data
DELETE FROM payment
WHERE payment_status = 'rejected'
AND verification_date < NOW() - INTERVAL '30 days';

-- =====================================================
-- DATA INTEGRITY CHECKS
-- =====================================================

-- 18. Check for payments without proof of payment file
SELECT 
    payment_id,
    booking_id,
    client_id,
    payment_status,
    uploaded_at
FROM payment
WHERE proof_of_payment_file_path IS NULL
OR proof_of_payment_file_name IS NULL;

-- 19. Check for bookings with payment but still showing unpaid
SELECT 
    b.booking_id,
    b.payment_status as booking_payment_status,
    p.payment_status as actual_payment_status,
    p.payment_amount
FROM booking b
JOIN payment p ON b.payment_id = p.payment_id
WHERE b.payment_status != 'paid'
AND p.payment_status = 'verified';

-- 20. Check for orphaned payment records (no matching booking)
SELECT 
    p.payment_id,
    p.booking_id,
    p.payment_status
FROM payment p
LEFT JOIN booking b ON p.booking_id = b.booking_id
WHERE b.booking_id IS NULL;

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================

-- 21. Manually update payment status (use with caution)
-- UPDATE payment
-- SET payment_status = 'verified',
--     verified_by = 'ADMIN_ID',
--     verification_date = NOW(),
--     verification_notes = 'Manually verified'
-- WHERE payment_id = 'PAYMENT_ID_HERE';

-- 22. Manually trigger notification for payment status
-- INSERT INTO notification (user_id, user_type, title, message, type)
-- SELECT 
--     client_id,
--     'client',
--     'Payment Status Update',
--     'Your payment has been ' || payment_status,
--     CASE payment_status 
--         WHEN 'verified' THEN 'success'
--         WHEN 'rejected' THEN 'warning'
--         ELSE 'info'
--     END
-- FROM payment
-- WHERE payment_id = 'PAYMENT_ID_HERE';

-- =====================================================
-- PERFORMANCE OPTIMIZATION
-- =====================================================

-- 23. Check index usage on payment table
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE tablename = 'payment'
ORDER BY idx_scan DESC;

-- 24. Analyze payment table performance
ANALYZE payment;
VACUUM ANALYZE payment;

-- =====================================================
-- END OF QUERIES
-- =====================================================






