# Job Cart & Quotation System - Database Interaction Flow

## Overview
This document explains how job carts and quotations work together in your event management system.

---

## Database Schema

### 1. **job_cart** Table
```sql
job_cart (
  job_cart_id uuid PRIMARY KEY,
  event_id uuid → references event(event_id),
  service_id uuid → references service(service_id),
  client_id uuid → references client(client_id),
  accepted_quotation_id uuid → references quotation(quotation_id),
  
  job_cart_item text,
  job_cart_details text,
  job_cart_min_price numeric,
  job_cart_max_price numeric,
  job_cart_status job_cart_status_enum DEFAULT 'pending',
  job_cart_created_date date,
  job_cart_created_time time,
  created_at timestamp
)
```

**Job Cart Status Enum:**
- `pending` - Created, waiting for providers to quote
- `quotations_in_progress` - Quotations exist
- `awaiting_client_decision` - Multiple quotations available
- `quotation_accepted` - Client accepted one
- `completed` - Booking completed
- `cancelled` - Cancelled

---

### 2. **quotation** Table
```sql
quotation (
  quotation_id uuid PRIMARY KEY,
  job_cart_id uuid → references job_cart(job_cart_id),
  service_provider_id uuid → references service_provider(service_provider_id),
  service_id uuid → references service(service_id),
  event_id uuid → references event(event_id),
  booking_id uuid → references booking(booking_id),
  
  quotation_price numeric NOT NULL,
  quotation_details text,
  quotation_file_path text,
  quotation_file_name text,
  quotation_status quotation_status_enum DEFAULT 'pending',
  quotation_submission_date date,
  quotation_submission_time time,
  created_at timestamp
)
```

**Quotation Status Enum:**
- `pending` - Submitted by provider, awaiting client
- `accepted` - Chosen by client (only ONE per job_cart)
- `rejected` - Explicitly rejected by client
- `withdrawn` - Provider withdrew the quote

---

## Data Flow

### Phase 1: Client Creates Job Cart (bookings.html)
```javascript
// When client selects a service and provides budget
const jobCartRecord = {
    service_id: actualServiceId,      // UUID from service table
    client_id: clientId,               // Logged in client
    event_id: eventId,                 // Created event
    job_cart_status: 'pending',
    job_cart_min_price: budgetData.minPrice,
    job_cart_max_price: budgetData.maxPrice
};

// Insert into database
await supabase
    .from('job_cart')
    .insert([jobCartRecord]);
```

**What happens:**
1. Client selects services (e.g., Photography, Catering)
2. Client provides budget range for each service
3. System creates one job_cart entry per service
4. job_cart_status = `'pending'`
5. Job cart IDs stored in localStorage

---

### Phase 2: Service Providers Submit Quotations
```javascript
// Service provider sees pending job carts for their service type
const { data: pendingJobCarts } = await supabase
    .from('job_cart')
    .select(`*, event(*), service(*)`)
    .eq('service_id', providerServiceId)
    .eq('job_cart_status', 'pending');

// Provider submits quotation
const quotationData = {
    job_cart_id: jobCartId,
    service_provider_id: providerId,
    service_id: serviceId,
    event_id: eventId,
    quotation_price: price,
    quotation_details: description,
    quotation_file_path: uploadedFilePath,
    quotation_status: 'pending'
};

await supabase
    .from('quotation')
    .insert([quotationData]);
```

**Automatic Trigger After Insert:**
```sql
-- fn_on_new_quotation() runs automatically
UPDATE job_cart
SET job_cart_status = 'quotations_in_progress'
WHERE job_cart_id = NEW.job_cart_id
  AND job_cart_status = 'pending';
```

**Business Rules:**
- Each job_cart can have multiple quotations (typically 3)
- Only quotations from providers with matching service_type
- Providers see job cart budget range (min/max)

---

### Phase 3: Client Views Quotations (quotation.html)
```javascript
// Load quotations for client's selected services
const { data: quotations } = await supabase
    .from('quotation')
    .select(`
        *,
        service_provider:service_provider_id (*),
        service:service_id (*),
        job_cart:job_cart_id (*)
    `)
    .in('service_id', selectedServiceIds)
    .eq('quotation_status', 'pending');

// Group by service
// Client sees: Provider name, rating, price, details, file
```

**Display:**
- Grouped by service type
- Shows 3 quotations per service (max)
- Client can compare prices, providers, details
- Can download quotation files

---

### Phase 4: Client Accepts Quotation
```javascript
// Client selects one quotation per service
selectedQuotations = {
    'service-id-1': 'quotation-id-A',
    'service-id-2': 'quotation-id-B'
};

// Update quotation status
await supabase
    .from('quotation')
    .update({ quotation_status: 'accepted' })
    .eq('quotation_id', selectedQuotationId);
```

**Automatic Trigger After Update:**
```sql
-- fn_handle_quotation_accepted() runs automatically
-- 1. Update job cart
UPDATE job_cart
SET accepted_quotation_id = NEW.quotation_id,
    job_cart_status = 'quotation_accepted'
WHERE job_cart_id = NEW.job_cart_id;

-- 2. Create booking automatically
INSERT INTO booking (
    booking_date,
    client_id,
    event_id,
    quotation_id,
    booking_total_price,
    payment_status
) VALUES (
    event.event_date,
    job_cart.client_id,
    job_cart.event_id,
    NEW.quotation_id,
    NEW.quotation_price,
    'unpaid'
);
```

**Constraints:**
- Only ONE quotation per job_cart can be 'accepted' (enforced by unique index)
- Other quotations for same job_cart remain 'pending' (not auto-rejected)

---

## Key Relationships

```
CLIENT
  ↓ creates
EVENT (date, location, time)
  ↓ for each service needed
JOB_CART (budget range, pending)
  ↓ visible to
SERVICE_PROVIDERS (matching service_type)
  ↓ submit (max 3 per job_cart)
QUOTATIONS (price, details, file)
  ↓ client selects one
ACCEPTED QUOTATION
  ↓ automatically creates
BOOKING (payment pending)
  ↓ after payment
CONFIRMED BOOKING
```

---

## Current Issues Observed (from console logs)

### 1. **Bad Request Errors**
```
GET /job_cart?...&quotation:quotation_id(...) 400 (Bad Request)
```
**Problem:** Trying to fetch `quotation` as a nested relationship on `job_cart`, but the foreign key is the opposite direction.

**Solution:** Fetch from `quotation` table instead:
```javascript
// WRONG ❌
await supabase.from('job_cart').select('*, quotation:quotation_id(*)');

// CORRECT ✅
await supabase.from('quotation').select('*, job_cart:job_cart_id(*)');
```

---

### 2. **Table Not Found Errors**
```
GET /job_cart_acceptance 404 (Not Found)
```
**Problem:** Code references `job_cart_acceptance` table which doesn't exist in schema.

**Solution:** 
- Either create the table, or
- Use `quotation.quotation_status = 'accepted'` instead

---

### 3. **Missing DOM Elements**
```
TypeError: Cannot set properties of null (setting 'textContent')
```
**Problem:** JavaScript tries to update HTML elements that don't exist.

**Solution:** Add null checks:
```javascript
const element = document.getElementById('elementId');
if (element) {
    element.textContent = value;
}
```

---

## Recommended Query Patterns

### Get Job Carts with Quotations
```javascript
// For service provider dashboard
const { data } = await supabase
    .from('job_cart')
    .select(`
        job_cart_id,
        job_cart_status,
        job_cart_min_price,
        job_cart_max_price,
        service:service_id (service_name, service_type),
        event:event_id (event_date, event_location),
        client:client_id (client_name, client_surname)
    `)
    .eq('service_id', providerServiceId)
    .eq('job_cart_status', 'pending');
```

### Get Quotations for Client
```javascript
// For client quotation view
const { data } = await supabase
    .from('quotation')
    .select(`
        quotation_id,
        quotation_price,
        quotation_details,
        quotation_file_path,
        quotation_status,
        service_provider:service_provider_id (
            service_provider_name,
            service_provider_surname,
            service_provider_rating,
            service_provider_location
        ),
        service:service_id (service_name),
        job_cart:job_cart_id (job_cart_min_price, job_cart_max_price)
    `)
    .in('service_id', clientServiceIds)
    .eq('quotation_status', 'pending');
```

### Get Accepted Quotations
```javascript
// For bookings/summary
const { data } = await supabase
    .from('job_cart')
    .select(`
        *,
        accepted_quotation:accepted_quotation_id (
            quotation_id,
            quotation_price,
            service_provider:service_provider_id (*)
        )
    `)
    .eq('client_id', clientId)
    .eq('job_cart_status', 'quotation_accepted');
```

---

## Testing the Flow

1. **Create job cart:** Login as client → bookings.html → select service → provide budget
2. **Check database:** Query job_cart table, verify status='pending'
3. **Submit quotation:** Login as service provider → submit quote for pending job cart
4. **Check trigger:** Verify job_cart_status changed to 'quotations_in_progress'
5. **View quotations:** Login as client → quotation.html → see available quotes
6. **Accept quotation:** Select one quotation per service
7. **Check trigger:** Verify booking created, job_cart.accepted_quotation_id set

---

## Troubleshooting Guide

| Error | Cause | Fix |
|-------|-------|-----|
| 400 Bad Request | Invalid join direction | Swap table in query |
| 404 Not Found | Table doesn't exist | Check schema, create table |
| PGRST200 | Foreign key not found | Verify FK relationship exists |
| Duplicate key | Multiple accepted | Unique index working correctly |
| null textContent | DOM element missing | Add null checks |

---

**Last Updated:** October 17, 2025
**Schema Version:** schema.sql (lines 81-278)

