# 🧪 Concurrent Access Testing Guide

## Prerequisites
1. Start local server: `python -m http.server 8000` or `npx serve html5up-stellar`
2. Have Supabase database running
3. Create test accounts for different user types

## Test Scenario 1: Service Provider Concurrent Access

### Setup
1. **Browser Window 1**: Login as Service Provider 1
2. **Browser Window 2**: Login as Service Provider 2  
3. **Browser Window 3**: Login as Customer
4. **Browser Window 4**: Login as Customer (different account)

### Test Steps

#### Step 1: Create Job Cart
1. In Browser 3 (Customer), navigate to booking page
2. Create a new booking with job cart
3. Note the job cart ID from browser console or database

#### Step 2: Test Concurrent Access
1. **Simultaneously** in both Browser 1 and Browser 2:
   - Navigate to service provider dashboard
   - Look for the new job cart
   - Both should see the same job cart

#### Step 3: Test Acceptance Race Condition
1. **Click "Accept" button simultaneously** in both browsers
2. **Expected Result**: Only one should succeed, other should get error message
3. **Check**: Only one acceptance record in database

#### Step 4: Test Quotation Upload
1. Provider who successfully accepted should see "Upload Quotation" button
2. Upload a test quotation
3. Customer should now see the quotation in their view

## Test Scenario 2: Customer Quotation Viewing

### Setup
1. Have quotations already uploaded by service providers
2. Login as customer

### Test Steps
1. Navigate to quotation page
2. **Expected**: Only uploaded quotations should be visible
3. **Expected**: Real-time notifications when new quotations are uploaded

## Test Scenario 3: Real-time Notifications

### Setup
1. Open multiple browser windows as different users
2. Set up real-time subscriptions

### Test Steps
1. Create job cart as customer
2. **Expected**: Service providers get real-time notification
3. Accept job as service provider
4. **Expected**: Other providers see status change
5. Upload quotation
6. **Expected**: Customer gets notification about new quotation

## Automated Testing

### Using the Test Script
1. Open browser console on any page
2. Load the test script:
```javascript
// Include the test script in your page
<script src="js/test-concurrent-access.js"></script>

// Run tests
const tester = new ConcurrentAccessTester();
await tester.runFullTest();
```

### Network Simulation
1. Open DevTools → Network tab
2. Set throttling to "Slow 3G"
3. Test concurrent access with network delays
4. Verify race conditions are handled properly

## Expected Results

### ✅ Success Criteria
- [ ] Multiple service providers can see the same job cart
- [ ] Only one provider can accept a job cart
- [ ] Accepted provider can upload quotations
- [ ] Customer only sees uploaded quotations
- [ ] Real-time updates work across all users
- [ ] No race conditions or data corruption
- [ ] Proper error messages for failed operations

### ❌ Failure Indicators
- Multiple providers can accept the same job cart
- Customer sees quotations before upload
- Real-time updates not working
- Database inconsistencies
- UI not updating after operations

## Debugging Tips

### Check Database State
```sql
-- Check job cart acceptance records
SELECT * FROM job_cart_acceptance ORDER BY created_at DESC;

-- Check quotation records
SELECT * FROM quotation ORDER BY created_at DESC;

-- Check job cart status
SELECT job_cart_id, job_cart_status FROM job_cart;
```

### Browser Console Debugging
```javascript
// Check current user
console.log('Current user:', await supabase.auth.getUser());

// Check real-time subscriptions
console.log('Active channels:', supabase.getChannels());

// Check job cart manager state
console.log('Job cart manager:', window.jobCartManager);
```

### Network Tab Monitoring
1. Open DevTools → Network tab
2. Filter by "WS" (WebSocket) to see real-time connections
3. Monitor API calls for race conditions
4. Check response times and error codes

## Common Issues & Solutions

### Issue: Multiple providers accepting same job cart
**Solution**: Check database locking implementation in migration file

### Issue: Customer not seeing quotations
**Solution**: Verify quotation status and job cart acceptance

### Issue: Real-time updates not working
**Solution**: Check Supabase real-time configuration and subscriptions

### Issue: UI not updating after operations
**Solution**: Verify event listeners and DOM updates

## Performance Testing

### Load Testing
1. Create multiple job carts simultaneously
2. Have multiple providers access the same job cart
3. Monitor database performance and response times

### Stress Testing
1. Rapidly create/accept job carts
2. Upload multiple quotations quickly
3. Test with slow network conditions

## Security Testing

### Authorization Testing
1. Try to accept job carts not assigned to you
2. Try to upload quotations without accepting job cart
3. Try to view quotations from other customers

### Data Validation
1. Test with invalid job cart IDs
2. Test with malformed quotation data
3. Test with oversized files

## Test Data Cleanup

After testing, clean up test data:
```sql
-- Clean up test records
DELETE FROM quotation WHERE quotation_details LIKE '%test%';
DELETE FROM job_cart_acceptance WHERE created_at > '2024-01-01';
DELETE FROM job_cart WHERE job_cart_item LIKE '%Test%';
DELETE FROM event WHERE event_name LIKE '%Test%';
```
