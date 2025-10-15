-- =====================================================
-- QUOTATION WORKFLOW - EXAMPLE SCENARIOS
-- =====================================================
-- This file demonstrates how the quotation system works
-- with the new business rules

-- =====================================================
-- SCENARIO 1: Normal Flow - Multiple Quotations
-- =====================================================

-- Step 1: Client creates a job cart
-- (Automatically sets submission deadline to NOW + 2 minutes)
INSERT INTO job_cart (client_id, service_id) 
VALUES ('client-uuid-123', 'service-uuid-456');
-- Result: quotation_submission_deadline = NOW + 2 minutes

-- Step 2: Service providers submit quotations (within 2 minutes)
-- Provider 1 submits after 30 seconds
INSERT INTO quotation (job_cart_id, service_provider_id, quotation_price, quotation_description)
VALUES ('job-cart-uuid-789', 'provider-1-uuid', 500.00, 'Professional service');
-- Status: 'pending'

-- Provider 2 submits after 1 minute
INSERT INTO quotation (job_cart_id, service_provider_id, quotation_price, quotation_description)
VALUES ('job-cart-uuid-789', 'provider-2-uuid', 450.00, 'Quality work guaranteed');
-- Status: 'pending'

-- Provider 3 submits after 1.5 minutes
INSERT INTO quotation (job_cart_id, service_provider_id, quotation_price, quotation_description)
VALUES ('job-cart-uuid-789', 'provider-3-uuid', 480.00, 'Best price, best service');
-- Status: 'pending'

-- Step 3: After 2 minutes, system automatically runs maintenance
SELECT public.run_quotation_maintenance();
-- This will:
-- 1. End the submission period for this job cart
-- 2. Move all 3 'pending' quotations to 'under_review'
-- 3. Set client_review_deadline to NOW + 24 hours

-- Step 4: Client checks if they can view quotations
SELECT * FROM public.can_client_view_quotations('job-cart-uuid-789', 'client-uuid-123');
-- Result: can_view = true, quotations_available = 3

-- Step 5: Client retrieves quotations for review
SELECT * FROM public.get_quotations_for_client_review('job-cart-uuid-789', 'client-uuid-123');
-- Shows all 3 quotations, sorted by price (cheapest first)
-- All quotations have status 'under_review'
-- They will NOT expire while client is reviewing

-- Step 6: Client accepts one quotation
UPDATE quotation 
SET quotation_status = 'accepted'
WHERE quotation_id = 'quotation-2-uuid'; -- The cheapest one

-- Step 7: Client rejects the others
UPDATE quotation 
SET quotation_status = 'rejected'
WHERE quotation_id IN ('quotation-1-uuid', 'quotation-3-uuid');


-- =====================================================
-- SCENARIO 2: Only 1 Quotation Submitted
-- =====================================================

-- Step 1: Client creates a job cart
INSERT INTO job_cart (client_id, service_id) 
VALUES ('client-uuid-999', 'service-uuid-888');

-- Step 2: Only 1 service provider submits
INSERT INTO quotation (job_cart_id, service_provider_id, quotation_price, quotation_description)
VALUES ('job-cart-uuid-999', 'provider-4-uuid', 600.00, 'Solo provider service');

-- Step 3: After 2 minutes, maintenance runs
SELECT public.run_quotation_maintenance();
-- Result: 
-- - Submission period ends
-- - 1 quotation moves to 'under_review'
-- - Message: "Only 1 quotation(s) available. Client can still review."

-- Step 4: Client can still view and accept the single quotation
SELECT * FROM public.get_quotations_for_client_review('job-cart-uuid-999', 'client-uuid-999');
-- Shows 1 quotation
-- Client can accept it or reject it and repost the job


-- =====================================================
-- SCENARIO 3: Service Provider Too Slow (Expired)
-- =====================================================

-- Step 1: Job cart created
INSERT INTO job_cart (client_id, service_id) 
VALUES ('client-uuid-777', 'service-uuid-666');

-- Step 2: One provider submits on time
INSERT INTO quotation (job_cart_id, service_provider_id, quotation_price)
VALUES ('job-cart-uuid-777', 'provider-5-uuid', 400.00);
-- Submitted at 1 minute - Status: 'pending'

-- Step 3: Another provider submits after 3 minutes (TOO LATE)
-- System has already run maintenance...
SELECT public.run_quotation_maintenance();
-- Result:
-- - Provider 5's quotation moved to 'under_review'
-- - Any late submissions would start as 'pending' but immediately expire

-- Late provider tries to submit
INSERT INTO quotation (job_cart_id, service_provider_id, quotation_price)
VALUES ('job-cart-uuid-777', 'provider-6-uuid', 350.00);
-- Status: 'pending' but quotation_expiry_date is in the past

-- Next maintenance run
SELECT public.expire_old_quotations();
-- Provider 6's quotation changes to 'expired'
-- They missed the submission window


-- =====================================================
-- SCENARIO 4: Client Tries to View Too Early
-- =====================================================

-- Job cart created
INSERT INTO job_cart (client_id, service_id) 
VALUES ('client-uuid-555', 'service-uuid-444');

-- Client tries to view quotations after 30 seconds
SELECT * FROM public.can_client_view_quotations('job-cart-uuid-555', 'client-uuid-555');
-- Result: 
-- can_view = false
-- reason = 'Submission period has not ended yet. Please wait for service providers to submit quotations.'


-- =====================================================
-- SCENARIO 5: No Quotations Submitted
-- =====================================================

-- Job cart created
INSERT INTO job_cart (client_id, service_id) 
VALUES ('client-uuid-333', 'service-uuid-222');

-- No service providers submit anything

-- After 2 minutes, maintenance runs
SELECT public.run_quotation_maintenance();
-- Result:
-- - Submission period ends
-- - Message: "No quotations submitted. Client may need to repost job."

-- Client checks
SELECT * FROM public.can_client_view_quotations('job-cart-uuid-333', 'client-uuid-333');
-- Result:
-- can_view = true
-- quotations_available = 0
-- Client sees no quotations and can decide to repost


-- =====================================================
-- KEY DIFFERENCES WITH NEW BUSINESS RULES
-- =====================================================

-- BEFORE (Old System):
-- ❌ Quotations could expire while client is reviewing
-- ❌ No clear separation between submission and review periods
-- ❌ Client might see quotations before submission period ends
-- ❌ Unclear what happens if less than 3 quotations submitted

-- AFTER (New System):
-- ✅ Quotations in 'under_review' NEVER expire
-- ✅ Clear separation: 2 min for providers, 24 hours for client
-- ✅ Client can ONLY view after submission period ends
-- ✅ Client sees whatever is available (1, 2, 3+ quotations)
-- ✅ Client has full 24 hours to compare and decide
-- ✅ System automatically manages all transitions


-- =====================================================
-- MONITORING & MAINTENANCE
-- =====================================================

-- View summary of all jobs and their quotation status
SELECT * FROM public.client_job_quotation_summary
WHERE client_id = 'your-client-uuid'
ORDER BY quotation_submission_deadline DESC;

-- Manually check quotations for a specific job
SELECT * FROM public.quotation_with_status_info
WHERE job_cart_id = 'your-job-cart-uuid';

-- Run maintenance (should be scheduled every minute in production)
SELECT public.run_quotation_maintenance();

-- Check quotation status history
SELECT * FROM public.quotation_status_history
WHERE quotation_id = 'your-quotation-uuid'
ORDER BY changed_at DESC;

