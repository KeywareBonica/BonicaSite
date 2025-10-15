# Quotation Workflow - Business Rules Documentation

## Overview
This system ensures fair time limits for both service providers and clients in the quotation process.

---

## Timeline Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ CLIENT CREATES JOB                                                          │
│ ↓                                                                           │
│ Submission Deadline = NOW + 2 minutes                                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ SUBMISSION PERIOD (0-2 minutes)                                            │
│                                                                             │
│ Service Providers submit quotations:                                       │
│   • Status: 'pending'                                                      │
│   • Deadline: NOW + 2 minutes from submission                              │
│   • Client CANNOT see quotations yet                                       │
│                                                                             │
│ Provider 1: ✅ Submits at 0:30 → Status: pending                           │
│ Provider 2: ✅ Submits at 1:00 → Status: pending                           │
│ Provider 3: ✅ Submits at 1:45 → Status: pending                           │
│ Provider 4: ❌ Submits at 2:30 → TOO LATE (will expire)                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
                           ⏰ 2 MINUTES PASS
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ SYSTEM AUTO-MAINTENANCE                                                     │
│                                                                             │
│ 1. End submission period                                                   │
│ 2. Move 'pending' → 'under_review'                                         │
│ 3. Set client review deadline = NOW + 24 hours                             │
│ 4. Expire late quotations                                                  │
│                                                                             │
│ Result:                                                                     │
│   Provider 1: ✅ Status: under_review                                       │
│   Provider 2: ✅ Status: under_review                                       │
│   Provider 3: ✅ Status: under_review                                       │
│   Provider 4: ❌ Status: expired                                            │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ CLIENT REVIEW PERIOD (0-24 hours)                                          │
│                                                                             │
│ Client can now view quotations:                                            │
│   • Sees 3 quotations (sorted by price)                                    │
│   • Has 24 hours to decide                                                 │
│   • Quotations DO NOT expire during review                                 │
│                                                                             │
│ Client actions:                                                             │
│   • Accept one quotation → Status: accepted                                │
│   • Reject others → Status: rejected                                       │
│   • Or reject all and repost job                                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ BOOKING CREATED                                                             │
│   Accepted quotation → Status: confirmed → completed                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Answer to Your Question

### "After 2 minutes, is the client seeing at least 3 quotations or whichever ones are there?"

**Answer: The client sees WHICHEVER quotations are available - NOT necessarily 3.**

### Detailed Explanation:

1. **If 3+ providers submit within 2 minutes:**
   - Client sees all submitted quotations
   - Can compare and choose the best one

2. **If only 1 provider submits within 2 minutes:**
   - Client sees that 1 quotation
   - Can accept it, reject it, or repost the job
   - System shows message: "Only 1 quotation(s) available. Client can still review."

3. **If 0 providers submit within 2 minutes:**
   - Client sees no quotations
   - System shows message: "No quotations submitted. Client may need to repost job."
   - Client can repost to try again

---

## Status Workflow

```
┌─────────────┐
│   PENDING   │ ← Quotation just submitted by service provider
└──────┬──────┘
       │
       ├─────→ (After 2 min deadline) → EXPIRED ❌ (Provider too slow)
       │
       ├─────→ (When submission period ends) ↓
       │
┌──────▼──────────┐
│  UNDER_REVIEW   │ ← Client is reviewing (QUOTATIONS DO NOT EXPIRE)
└──────┬──────────┘
       │
       ├─────→ ACCEPTED ✅ (Client chose this one)
       │           │
       │           └─────→ CONFIRMED → COMPLETED
       │
       └─────→ REJECTED ❌ (Client chose another one)
```

---

## Business Rules Summary

### Rule 1: Submission Time Limit (Service Providers)
- **Time:** 2 minutes (configurable)
- **Action:** Submit quotation with price and details
- **Penalty:** If not submitted in time → Status becomes 'expired'
- **Note:** Each quotation has individual tracking

### Rule 2: Client Review Period
- **When:** Starts AFTER submission period ends
- **Time:** 24 hours (configurable)
- **What Client Sees:** ALL quotations submitted during submission period
- **Important:** Quotations in 'under_review' DO NOT expire

### Rule 3: No Minimum Quotation Requirement
- Client sees whatever is available (1, 2, 3, 4+ quotations)
- System informs client of the count
- Client can still proceed with fewer quotations or repost

### Rule 4: Quotation Visibility
- **Service Providers:** See their own quotations anytime
- **Clients:** Can ONLY see quotations AFTER submission period ends
- **Reason:** Prevents clients from accepting before all providers have a chance

### Rule 5: Automatic Process
- System automatically:
  - Expires late quotations
  - Ends submission periods
  - Transitions quotations to 'under_review'
  - Tracks all status changes

---

## Key Functions for Your Application

### 1. Check if Client Can View Quotations
```sql
SELECT * FROM public.can_client_view_quotations(
    'job-cart-uuid', 
    'client-uuid'
);
```
Returns:
- `can_view`: true/false
- `reason`: Explanation message
- `quotations_available`: Count of quotations
- `time_until_deadline`: How long client has to decide

### 2. Get Quotations for Client Review
```sql
SELECT * FROM public.get_quotations_for_client_review(
    'job-cart-uuid',
    'client-uuid'
);
```
Returns all available quotations with:
- Price, description, status
- Service provider name and rating
- File attachments
- Sorted by price (cheapest first)

### 3. Run Maintenance (Schedule Every Minute)
```sql
SELECT public.run_quotation_maintenance();
```
This function:
- Ends submission periods that have passed
- Expires quotations that weren't submitted in time
- Transitions quotations to 'under_review'

### 4. View Job Summary (For Client Dashboard)
```sql
SELECT * FROM public.client_job_quotation_summary
WHERE client_id = 'your-client-uuid';
```
Shows:
- Total quotations
- Quotations under review
- Price range
- Status summary (e.g., "Ready for review", "Waiting for quotations")

---

## Scenarios Covered

### ✅ Scenario 1: All Goes Well
- 3+ providers submit within 2 minutes
- Client reviews and accepts one
- Booking created successfully

### ✅ Scenario 2: Few Providers
- Only 1-2 providers submit
- Client still sees quotations
- Client decides to accept or repost

### ✅ Scenario 3: Late Provider
- Provider submits after deadline
- Their quotation is marked expired
- Client doesn't see it

### ✅ Scenario 4: No Providers
- No one submits
- Client sees empty list
- Can repost the job

### ✅ Scenario 5: Client Tries Early Access
- Client tries to view before 2 minutes
- System blocks access
- Shows "Submission period not ended yet"

---

## Configuration Options

| Setting | Default | Purpose |
|---------|---------|---------|
| `quotation_expiry_minutes` | 2 | How long providers have to submit |
| `client_review_hours` | 24 | How long client has to review |
| Both are configurable in the `job_cart` table | | |

---

## Important Notes

1. **Quotations under review NEVER expire** - Client has full time to decide
2. **No minimum quotation requirement** - Client sees what's available
3. **Clear separation of periods** - Providers submit first, then client reviews
4. **Automatic management** - System handles all transitions
5. **Full audit trail** - All status changes are logged in `quotation_status_history`

---

## Next Steps for Your Application

1. **Schedule maintenance:**
   - Set up a cron job to call `run_quotation_maintenance()` every minute

2. **Client UI:**
   - Show countdown during submission period
   - After period ends, show all available quotations
   - Display time remaining for client to decide

3. **Service Provider UI:**
   - Show countdown timer (2 minutes)
   - Display warning when time is running out
   - Show if quotation expired or is under review

4. **Notifications:**
   - Alert client when submission period ends
   - Alert providers when quotation is accepted/rejected
   - Remind client before review deadline expires

