# Booking Flow Testing Guide

## Step 1: Run the SQL Script

### Option A: Using Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** (left sidebar)
3. Create a new query
4. Copy and paste the contents of `use_existing_data_booking_flow.sql`
5. Click **Run** or press `Ctrl+Enter`
6. Review the output to see what test data was created

### Option B: Using PostgreSQL Client
```bash
psql -U your_username -d your_database -f use_existing_data_booking_flow.sql
```

---

## Step 2: Note Your Test Credentials

After running the script, look for this output:
```
🔑 USE THIS TO LOGIN:
email: [some-email@example.com]
name: [Client Name]
```

**Write down this email** - you'll use it to login and test.

---

## Step 3: Test the Booking Flow

### 3.1 Client Login
- [ ] Go to your application's login page
- [ ] Login using the email from Step 2
- [ ] Verify you can see the dashboard

### 3.2 View Events
- [ ] Navigate to events section
- [ ] Confirm you can see the test event
- [ ] Check event details (date, location, type)

### 3.3 Browse Services
- [ ] Go to services/providers section
- [ ] Verify service providers are displayed
- [ ] Check provider details (rating, description, pricing)

### 3.4 View Job Cart
- [ ] Navigate to job cart/requested services
- [ ] Confirm job cart items exist for your event
- [ ] Verify service details are correct

### 3.5 View Quotations
- [ ] Go to quotations page
- [ ] **Expected**: See quotations from service providers
- [ ] Verify each quotation shows:
  - [ ] Provider name
  - [ ] Service type
  - [ ] Price
  - [ ] Details/description
  - [ ] Status (should be "pending")

### 3.6 Compare Quotations
- [ ] If multiple quotes exist for same service, compare them
- [ ] Check if sorting/filtering works
- [ ] Verify price differences are visible

### 3.7 Accept Quotation
- [ ] Select a quotation to accept
- [ ] Click "Accept" or similar button
- [ ] **Expected**: 
  - [ ] Quotation status changes to "accepted"
  - [ ] Other quotations for same service may be rejected
  - [ ] Proceed to payment option appears

### 3.8 Payment Upload
- [ ] Navigate to payment section
- [ ] Upload a test image/PDF as proof of payment
- [ ] Fill in payment details:
  - [ ] Amount
  - [ ] Payment date
  - [ ] Payment method
- [ ] Submit payment proof
- [ ] **Expected**:
  - [ ] Payment record created
  - [ ] Status shows "pending verification"
  - [ ] Confirmation message displayed

### 3.9 Check Payment Status
- [ ] Go to payment history/bookings
- [ ] Verify uploaded payment appears
- [ ] Check status is "pending" or "awaiting verification"

---

## Step 4: Admin Testing (if applicable)

### 4.1 Admin Login
- [ ] Logout from client account
- [ ] Login as admin/service provider

### 4.2 View Payment Verification Queue
- [ ] Navigate to admin/payments section
- [ ] **Expected**: See pending payments
- [ ] Verify payment details are visible

### 4.3 Verify Payment
- [ ] Select the test payment
- [ ] View uploaded proof
- [ ] Approve or reject payment
- [ ] **Expected**:
  - [ ] Status updates to "verified" or "approved"
  - [ ] Booking status changes
  - [ ] Client receives notification (if implemented)

---

## Step 5: Check Database State

Run these queries to verify the data flow:

```sql
-- Check job cart status
SELECT 
    jc.job_cart_id,
    jc.job_cart_item,
    jc.job_cart_status,
    c.client_email
FROM public.job_cart jc
JOIN public.client c ON jc.client_id = c.client_id
ORDER BY jc.created_at DESC
LIMIT 5;

-- Check quotation status
SELECT 
    q.quotation_id,
    q.quotation_price,
    q.quotation_status,
    sp.service_provider_name || ' ' || sp.service_provider_surname as provider
FROM public.quotation q
JOIN public.service_provider sp ON q.service_provider_id = sp.service_provider_id
ORDER BY q.created_at DESC
LIMIT 10;

-- Check payment records
SELECT 
    p.payment_id,
    p.payment_amount,
    p.payment_status,
    p.payment_date,
    c.client_email
FROM public.payment p
JOIN public.client c ON p.client_id = c.client_id
ORDER BY p.created_at DESC
LIMIT 5;

-- Check booking records
SELECT 
    b.booking_id,
    b.booking_status,
    b.total_price,
    c.client_email,
    e.event_type
FROM public.booking b
JOIN public.client c ON b.client_id = c.client_id
JOIN public.event e ON b.event_id = e.event_id
ORDER BY b.created_at DESC
LIMIT 5;
```

---

## Common Issues & Troubleshooting

### Issue: No quotations showing up
**Check:**
- [ ] Job cart items exist for the client's event
- [ ] Quotations are linked to correct job_cart_id
- [ ] Quotation status is "pending"
- [ ] Your UI filters aren't hiding them

### Issue: Can't accept quotation
**Check:**
- [ ] User is logged in as the correct client
- [ ] Quotation belongs to user's event
- [ ] Accept button has correct event handler
- [ ] API endpoint is working

### Issue: Payment upload fails
**Check:**
- [ ] File upload configuration is correct
- [ ] Storage bucket permissions (if using Supabase Storage)
- [ ] File size limits
- [ ] File type restrictions

### Issue: Admin can't see payments
**Check:**
- [ ] Admin role/permissions are set correctly
- [ ] Payment records exist in database
- [ ] Admin query filters are correct

---

## Expected Results Summary

After complete testing, you should have:
- ✅ Client can view available quotations
- ✅ Client can accept a quotation
- ✅ Client can upload payment proof
- ✅ Payment record is created in database
- ✅ Admin can view pending payments
- ✅ Admin can verify/approve payments
- ✅ Booking status updates accordingly
- ✅ All data persists correctly in database

---

## Report Issues

As you test, document any issues:

| Step | Expected | Actual | Error Message | Screenshot |
|------|----------|--------|---------------|------------|
|      |          |        |               |            |

