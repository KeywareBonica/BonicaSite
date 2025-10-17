# Actual Database Schema Analysis

## Production Schema Overview (Supabase)

This document reflects the **ACTUAL** database schema currently running in production.

---

## Key Tables & Relationships

### 1. **job_cart** (The Core of Your System)
```sql
job_cart (
  job_cart_id uuid PRIMARY KEY,
  
  -- Foreign Keys
  event_id uuid → event(event_id),
  service_id uuid → service(service_id),
  client_id uuid → client(client_id),
  accepted_quotation_id uuid → quotation(quotation_id),  -- Points to winning quote
  
  -- Job Cart Data
  job_cart_item text,
  job_cart_details text,
  job_cart_status text DEFAULT 'pending',
  job_cart_min_price numeric,      -- Client's budget range
  job_cart_max_price numeric,
  
  -- Deadline Management
  quotation_deadline timestamp,
  quotation_expiry_minutes integer DEFAULT 2,
  
  -- Timestamps
  job_cart_created_date date,
  job_cart_created_time time,
  created_at timestamp
)
```

**Key Points:**
- ✅ `accepted_quotation_id` stores the winning quotation
- ✅ `quotation_deadline` sets time limit for providers to quote
- ✅ `quotation_expiry_minutes` sets urgency (default 2 minutes - seems very short!)

---

### 2. **quotation** (Service Provider Quotes)
```sql
quotation (
  quotation_id uuid PRIMARY KEY,
  
  -- Foreign Keys
  job_cart_id uuid → job_cart(job_cart_id),
  service_provider_id uuid → service_provider(service_provider_id),
  service_id uuid → service(service_id),
  event_id uuid → event(event_id),
  booking_id uuid → booking(booking_id),      -- Set when accepted
  file_storage_id uuid → file_storage(file_id),
  
  -- Quotation Data
  quotation_price numeric NOT NULL,
  quotation_details text,
  quotation_status quotation_status_enum DEFAULT 'pending',
  
  -- File Management (Enhanced)
  quotation_file_path text,
  quotation_file_name text,
  quotation_file_size bigint,
  quotation_file_type text CHECK (...pdf/doc/docx...),
  quotation_file_hash text,        -- SHA-256 for integrity
  quotation_file_validated boolean DEFAULT false,
  
  -- Deadline Management
  quotation_deadline timestamp,
  quotation_expiry_date timestamp,
  
  -- Timestamps
  quotation_submission_date date,
  quotation_submission_time time,
  quotation_created_at timestamp,
  quotation_last_updated timestamp,
  created_at timestamp
)
```

**Key Points:**
- ✅ File validation with hash checking
- ✅ Links to `file_storage` table for proper file management
- ✅ `booking_id` set when quotation is accepted
- ✅ Expiry management built-in

---

### 3. **booking** (Final Booking)
```sql
booking (
  booking_id uuid PRIMARY KEY,
  
  -- Foreign Keys
  client_id uuid → client(client_id),
  event_id uuid → event(event_id),
  quotation_id uuid → quotation(quotation_id),     -- NEW!
  service_provider_id uuid → service_provider(...), -- NEW!
  payment_id uuid → payment(payment_id),            -- NEW!
  
  -- Booking Data
  booking_date date NOT NULL,
  booking_location text,
  booking_total_price numeric,
  booking_special_requests text,
  booking_status text DEFAULT 'pending',
  
  -- Payment Status
  payment_status payment_status_enum DEFAULT 'unpaid',
  
  -- Timestamps
  created_at timestamp
)
```

**Key Points:**
- ✅ `quotation_id` links back to the accepted quotation
- ✅ `service_provider_id` for direct provider reference
- ✅ `payment_id` links to payment record
- ✅ `payment_status` enum (separate from booking_status)

---

### 4. **payment** (New Table!)
```sql
payment (
  payment_id uuid PRIMARY KEY,
  
  -- Foreign Keys
  booking_id uuid → booking(booking_id),
  client_id uuid → client(client_id),
  service_provider_id uuid → service_provider(...),
  verified_by uuid → service_provider(...),  -- Admin/verifier
  
  -- Payment Data
  payment_amount numeric NOT NULL,
  payment_method text DEFAULT 'bank_transfer',
  payment_status payment_status_enum DEFAULT 'pending_verification',
  
  -- Proof of Payment
  proof_of_payment_file_path text,
  proof_of_payment_file_name text,
  proof_of_payment_file_type text,
  proof_of_payment_file_size bigint,
  
  -- Verification
  verification_date timestamp,
  verification_notes text,
  rejection_reason text,
  
  -- Timestamps
  uploaded_at timestamp,
  created_at timestamp,
  updated_at timestamp
)
```

**Payment Status Enum Values:**
- `unpaid`
- `pending_verification` (proof uploaded, awaiting admin check)
- `verified` (payment confirmed)
- `rejected` (proof rejected)
- `refunded`

---

### 5. **file_storage** (Secure File Management)
```sql
file_storage (
  file_id uuid PRIMARY KEY,
  
  file_path text UNIQUE NOT NULL,
  file_name text NOT NULL,
  file_size bigint CHECK (file_size > 0),
  file_type text CHECK (...pdf/doc/docx...),
  file_hash text CHECK (SHA-256 format),
  
  upload_date timestamp,
  uploaded_by uuid,
  uploaded_by_type user_type_enum,
  is_active boolean DEFAULT true,
  
  created_at timestamp,
  updated_at timestamp
)
```

**Key Points:**
- ✅ Centralized file management
- ✅ SHA-256 hash validation
- ✅ File type restrictions
- ✅ Tracks who uploaded
- ✅ Soft delete with `is_active`

---

### 6. **quotation_status_history** (Audit Trail)
```sql
quotation_status_history (
  history_id uuid PRIMARY KEY,
  quotation_id uuid → quotation(quotation_id),
  
  old_status quotation_status_enum,
  new_status quotation_status_enum NOT NULL,
  
  changed_by uuid,
  changed_by_type user_type_enum,
  change_reason text,
  changed_at timestamp
)
```

**Key Points:**
- ✅ Complete audit trail for quotation status changes
- ✅ Tracks who changed it (client or provider)
- ✅ Reason for change

---

## Complete Data Flow (With Payment)

```
1. CLIENT creates JOB_CART
   ↓
2. SERVICE_PROVIDERS submit QUOTATIONS
   ↓
3. CLIENT accepts one QUOTATION
   ↓ (automatic trigger should set)
4. BOOKING created with quotation_id, service_provider_id
   ↓ (booking.payment_status = 'unpaid')
5. CLIENT uploads PAYMENT proof
   ↓
6. PAYMENT record created (status = 'pending_verification')
   ↓ (booking.payment_id set)
7. ADMIN verifies PAYMENT
   ↓ (payment.payment_status = 'verified')
8. BOOKING status updated to 'confirmed'
   ↓
9. EVENT happens
   ↓
10. CLIENT leaves REVIEW
```

---

## Current Schema vs Code Mismatches

### Issue 1: Missing quotation_id constraint in booking
**Schema shows:**
```sql
CONSTRAINT booking_quotation_fkey FOREIGN KEY (quotation_id) 
  REFERENCES public.quotation(quotation_id)
```

**But your schema.sql had:**
```sql
-- This constraint was missing!
```

**Action:** ✅ Schema is correct - no fix needed

---

### Issue 2: job_cart.accepted_quotation_id foreign key
**Schema shows:**
```sql
accepted_quotation_id uuid  -- No FK constraint listed!
```

**Expected:**
```sql
CONSTRAINT job_cart_accepted_quotation_fkey 
  FOREIGN KEY (accepted_quotation_id) 
  REFERENCES public.quotation(quotation_id)
```

**Action:** ⚠️ Add this constraint if missing

---

### Issue 3: Quotation expiry timing
```sql
quotation_expiry_minutes integer DEFAULT 2
```

**Problem:** 2 minutes is extremely short! Providers have only 2 minutes to submit quotes?

**Recommendation:** Change to reasonable timeframe:
- 24 hours = 1440 minutes
- 48 hours = 2880 minutes
- 72 hours = 4320 minutes

---

### Issue 4: event_service table (Unused?)
```sql
CREATE TABLE public.event_service (
  event_service_id uuid PRIMARY KEY,
  service_id uuid → service(service_id),
  event_id uuid → event(event_id),
  event_service_notes text,
  event_service_status text DEFAULT 'pending',
  created_at timestamp
)
```

**Question:** Is this table being used? It seems to duplicate job_cart functionality.

**Recommendation:** 
- If used: Keep both tables but clarify purpose
- If unused: Drop table to avoid confusion

---

## Enums Used (User-Defined Types)

### payment_status_enum
- `unpaid`
- `pending_verification`
- `verified`
- `rejected`
- `refunded`

### quotation_status_enum
- `pending`
- `accepted`
- `rejected`
- `withdrawn`

### user_type_enum
- `client`
- `service_provider`

---

## Critical Queries for Your System

### 1. Get Pending Job Carts for Service Provider
```javascript
const { data: pendingJobCarts } = await supabase
  .from('job_cart')
  .select(`
    job_cart_id,
    job_cart_min_price,
    job_cart_max_price,
    job_cart_status,
    quotation_deadline,
    service:service_id (service_name, service_type),
    event:event_id (
      event_date,
      event_start_time,
      event_end_time,
      event_location
    ),
    client:client_id (
      client_name,
      client_surname,
      client_contact
    )
  `)
  .eq('service_id', providerServiceId)
  .eq('job_cart_status', 'pending')
  .gte('quotation_deadline', new Date().toISOString());
```

---

### 2. Get Client's Quotations (with Provider Info)
```javascript
const { data: quotations } = await supabase
  .from('quotation')
  .select(`
    quotation_id,
    quotation_price,
    quotation_details,
    quotation_file_path,
    quotation_status,
    quotation_submission_date,
    quotation_expiry_date,
    service:service_id (service_name, service_type),
    service_provider:service_provider_id (
      service_provider_name,
      service_provider_surname,
      service_provider_rating,
      service_provider_location,
      service_provider_contactno
    ),
    job_cart:job_cart_id (
      job_cart_min_price,
      job_cart_max_price
    )
  `)
  .in('job_cart_id', clientJobCartIds)
  .eq('quotation_status', 'pending')
  .gte('quotation_expiry_date', new Date().toISOString());
```

---

### 3. Create Booking When Quotation Accepted
```javascript
// First, update quotation status
const { data: updatedQuotation } = await supabase
  .from('quotation')
  .update({ quotation_status: 'accepted' })
  .eq('quotation_id', selectedQuotationId)
  .select('*, job_cart:job_cart_id(*)').single();

// Then create booking (if not auto-created by trigger)
const { data: booking } = await supabase
  .from('booking')
  .insert([{
    client_id: clientId,
    event_id: eventId,
    quotation_id: selectedQuotationId,
    service_provider_id: updatedQuotation.service_provider_id,
    booking_date: updatedQuotation.job_cart.event.event_date,
    booking_total_price: updatedQuotation.quotation_price,
    booking_status: 'pending',
    payment_status: 'unpaid'
  }])
  .select()
  .single();

// Update job_cart with accepted quotation
await supabase
  .from('job_cart')
  .update({ accepted_quotation_id: selectedQuotationId })
  .eq('job_cart_id', updatedQuotation.job_cart_id);
```

---

### 4. Submit Payment Proof
```javascript
// Upload file to storage
const { data: fileData, error: uploadError } = await supabase
  .storage
  .from('payment-proofs')
  .upload(`${bookingId}/${filename}`, file);

// Create payment record
const { data: payment } = await supabase
  .from('payment')
  .insert([{
    booking_id: bookingId,
    client_id: clientId,
    service_provider_id: serviceProviderId,
    payment_amount: totalAmount,
    payment_method: 'bank_transfer',
    payment_status: 'pending_verification',
    proof_of_payment_file_path: fileData.path,
    proof_of_payment_file_name: filename,
    proof_of_payment_file_type: file.type,
    proof_of_payment_file_size: file.size
  }])
  .select()
  .single();

// Update booking with payment_id
await supabase
  .from('booking')
  .update({ 
    payment_id: payment.payment_id,
    payment_status: 'pending_verification'
  })
  .eq('booking_id', bookingId);
```

---

### 5. Get Bookings with Payment Status
```javascript
const { data: bookings } = await supabase
  .from('booking')
  .select(`
    booking_id,
    booking_date,
    booking_status,
    booking_total_price,
    payment_status,
    event:event_id (
      event_type,
      event_date,
      event_location
    ),
    quotation:quotation_id (
      quotation_price,
      quotation_details,
      service_provider:service_provider_id (
        service_provider_name,
        service_provider_surname
      )
    ),
    payment:payment_id (
      payment_amount,
      payment_status,
      proof_of_payment_file_path,
      uploaded_at,
      verification_notes
    )
  `)
  .eq('client_id', clientId)
  .order('created_at', { ascending: false });
```

---

## Schema Health Check

### ✅ Good Practices
1. UUID primary keys everywhere
2. Foreign key constraints properly defined
3. Enum types for status fields
4. File validation with hash checking
5. Audit trail with history table
6. Timestamp tracking (created_at, updated_at)

### ⚠️ Potential Issues
1. **quotation_expiry_minutes = 2** (too short!)
2. **event_service table** (purpose unclear, might be duplicate)
3. **Missing FK constraint** on job_cart.accepted_quotation_id
4. **No unique constraint** preventing multiple accepted quotations per job_cart

### 🔧 Recommended Fixes

```sql
-- 1. Add missing FK constraint
ALTER TABLE job_cart
ADD CONSTRAINT job_cart_accepted_quotation_fkey
FOREIGN KEY (accepted_quotation_id)
REFERENCES quotation(quotation_id);

-- 2. Add unique constraint for accepted quotations
CREATE UNIQUE INDEX uq_one_accepted_per_job_cart
ON quotation (job_cart_id)
WHERE quotation_status = 'accepted';

-- 3. Update default expiry time
ALTER TABLE job_cart
ALTER COLUMN quotation_expiry_minutes SET DEFAULT 2880; -- 48 hours

-- 4. Add check constraint for price range
ALTER TABLE job_cart
ADD CONSTRAINT job_cart_price_range_check
CHECK (job_cart_max_price IS NULL OR job_cart_max_price >= job_cart_min_price);
```

---

**Last Updated:** October 17, 2025  
**Source:** Production Supabase Schema

