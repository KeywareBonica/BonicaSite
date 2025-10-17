# 🔥 Manual Real-Time Quotation Test

## 🎯 Goal: Test the complete real-time quotation upload flow

---

## 📋 Prerequisites

### 1. Get Test Credentials
Run this in Supabase SQL Editor to get test accounts:

```sql
-- Get test client
SELECT 
    'CLIENT LOGIN' as type,
    client_email as email,
    client_name || ' ' || client_surname as name,
    client_id::text as id
FROM public.client 
ORDER BY created_at DESC 
LIMIT 1;

-- Get test service provider
SELECT 
    'SERVICE PROVIDER LOGIN' as type,
    service_provider_email as email,
    service_provider_name || ' ' || service_provider_surname as name,
    service_provider_id::text as id
FROM public.service_provider 
WHERE service_provider_verification = true
ORDER BY created_at DESC 
LIMIT 1;
```

**Write down both emails and IDs!**

---

## 🖥️ Step 1: Setup Two Browser Windows

### Window 1: Client View
1. **Open:** Your application (Login.html)
2. **Login as:** [CLIENT EMAIL from above]
3. **Navigate to:** Create a new event and select services
4. **Go to:** quotation.html page
5. **Keep this window open** and visible

### Window 2: Service Provider View  
1. **Open:** New browser window (or incognito)
2. **Login as:** [SERVICE PROVIDER EMAIL from above]
3. **Navigate to:** service-provider-dashboard.html
4. **Look for:** Available job carts
5. **Keep this window open** and visible

---

## ⏱️ Step 2: Test the Timer Flow

### From Client Window:
1. **Complete booking** until you reach services selection
2. **Select services** you need (e.g., Photography, Catering)
3. **Click "Next"** or "Continue"
4. **Look for:** 1-minute timer appearing
5. **Message should show:** "Quotations are being uploaded, please wait..."

### Expected Behavior:
- ✅ Timer counts down from 60 seconds
- ✅ Client can't proceed until timer ends
- ✅ Message indicates quotations are being uploaded

---

## 📤 Step 3: Test Real-Time Quotation Upload

### From Service Provider Window:
1. **Look for:** New job cart that appeared
2. **Click on:** The job cart item
3. **Fill out quotation form:**
   - Price: R2,500 (or any reasonable amount)
   - Details: "Professional photography service for your event"
   - Optional: Upload a test PDF
4. **Click:** "Submit Quotation"

### From Client Window (Watch Carefully):
1. **Look for:** Real-time notification
2. **Expected:** "New quotation available!" popup
3. **Check:** Does quotation appear in the list immediately?
4. **Verify:** Price, details, and provider name are correct

---

## 🔄 Step 4: Test Multiple Providers

### Repeat Step 3 with Different Provider:
1. **Get another service provider** email from SQL query above
2. **Login as second provider** in a third browser window
3. **Upload another quotation** for the same service
4. **Watch client window** for second quotation appearing

### Expected Behavior:
- ✅ Client sees 2 quotations for same service
- ✅ Both show as "pending" status
- ✅ Client can compare prices and details

---

## ✅ Step 5: Test Client Acceptance

### From Client Window:
1. **Review** all quotations that appeared
2. **Click "Select This Quote"** on your preferred quotation
3. **Expected behavior:**
   - Selected quotation status changes to 'confirmed'
   - Other quotations for same service become 'rejected' or disabled
   - Price breakdown appears
   - "Continue to Payment" button becomes available

---

## 🚨 What to Watch For (Common Issues):

### Timer Issues:
- ❌ Timer doesn't appear
- ❌ Timer doesn't count down
- ❌ Client can proceed before timer ends

### Real-Time Issues:
- ❌ No notification when provider uploads
- ❌ Quotation doesn't appear immediately
- ❌ Need to refresh page to see new quotation

### UI Issues:
- ❌ Can't select quotations
- ❌ Status doesn't change when selected
- ❌ Price breakdown doesn't appear

### Database Issues:
- ❌ Quotations not saved to database
- ❌ Status changes don't persist
- ❌ Wrong status values (should be 'pending', 'confirmed', 'rejected')

---

## 📊 Expected Results Summary:

| Test | Expected | Pass/Fail |
|------|----------|-----------|
| Timer appears | ✅ 60-second countdown | ⬜ |
| Provider can upload | ✅ Quotation saved to DB | ⬜ |
| Real-time notification | ✅ "New quotation available!" | ⬜ |
| Quotation appears | ✅ Shows immediately on client side | ⬜ |
| Multiple quotations | ✅ Up to 3 per service | ⬜ |
| Client can select | ✅ One quotation per service | ⬜ |
| Status updates | ✅ pending → confirmed/rejected | ⬜ |
| Price breakdown | ✅ Shows total cost | ⬜ |

---

## 🎯 Success Criteria:

**✅ REAL-TIME SYSTEM IS WORKING IF:**
1. Client sees quotations appear **immediately** when provider uploads
2. No page refresh needed
3. Timer works correctly
4. Notifications appear
5. Client can accept quotations
6. Status changes persist in database

**❌ SYSTEM HAS ISSUES IF:**
1. Need to refresh to see new quotations
2. Timer doesn't work
3. No real-time notifications
4. Can't accept quotations
5. Database status doesn't update

---

## 📝 Report Results:

After testing, document:
- ✅ What worked perfectly
- ⚠️ What had minor issues
- ❌ What completely failed
- 📸 Screenshots of any errors

**This manual test will show you exactly how your real-time system behaves for actual users!** 🎉

---

## 🔧 Troubleshooting Tips:

### If Real-Time Doesn't Work:
1. **Check browser console** for JavaScript errors
2. **Check Network tab** for failed API calls
3. **Verify Supabase connection** is working
4. **Check if WebSocket** connections are active

### If Timer Doesn't Work:
1. **Check if JavaScript** is enabled
2. **Look for timer-related** errors in console
3. **Verify timer code** is loading correctly

### If Database Updates Fail:
1. **Check Supabase logs** for errors
2. **Verify RLS policies** allow updates
3. **Check foreign key** constraints
