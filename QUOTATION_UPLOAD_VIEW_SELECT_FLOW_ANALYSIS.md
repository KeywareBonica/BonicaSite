# 🔄 **QUOTATION FLOW: Upload → View → Select Analysis**

## 📊 **Complete Flow Breakdown**

This document traces the **entire lifecycle** of a quotation from when a service provider uploads it to when a customer views and selects it.

---

## 🎯 **STEP 1: SERVICE PROVIDER UPLOADS QUOTATION**

### **File:** `sp-quotation.js`

### **Upload Process:**

#### **1.1 Service Provider Loads Job Carts**
```javascript
// Lines 161-273: loadJobCarts()
const { data: acceptedJobs, error } = await supabase
    .from("job_cart_acceptance")          // ⚠️ PROBLEM: This table doesn't exist
    .select(`
        job_cart:job_cart_id (
            job_cart_id,
            job_cart_item,
            job_cart_details,
            job_cart_status,
            job_cart_created_date,
            service_id,
            event:event_id (
                event_id,
                event_name,
                event_date,
                event_location,
                event_start_time,
                event_end_time,
                client:client_id (
                    client_name,
                    client_surname
                )
            )
        )
    `)
    .eq("service_provider_id", serviceProviderId)
    .eq("acceptance_status", "accepted")
    .order("accepted_at", { ascending: false });
```

**🚨 CRITICAL ISSUE #1:** Querying **non-existent** `job_cart_acceptance` table!

---

#### **1.2 Service Provider Submits Quotation**
```javascript
// Lines 393-516: Form submit handler
const quotationData = {
    service_provider_id: serviceProviderId,
    job_cart_id: jobCartId,
    service_id: serviceId,                  // ✅ Added from job_cart
    quotation_price: price,
    quotation_details: details,
    quotation_file_path: filePath,
    quotation_file_name: file.name,
    quotation_submission_date: new Date().toISOString().split("T")[0],
    quotation_submission_time: new Date().toLocaleTimeString(),
    quotation_status: "confirmed",          // ⚠️ PROBLEM: Should be "pending"
    total_amount: price
};

const { data: quotation, error: insertError } = await supabase
    .from("quotation")
    .insert([quotationData])
    .select("quotation_id");
```

**🚨 CRITICAL ISSUE #2:** Setting status to **"confirmed"** instead of **"pending"**!

**Expected Status Flow:**
```
pending → accepted (by client) → confirmed (for booking)
```

**Actual Status:**
```
confirmed (immediately) ❌
```

---

#### **1.3 Notification Sent to Client**
```javascript
// Lines 519-571: sendQuotationNotification()
const notification = {
    client_id: jobCart.event.client_id,     // ⚠️ PROBLEM: event doesn't have client_id
    notification_type: "new_quotation",
    notification_title: "New Quotation Received",
    notification_message: `You have received a new quotation from ${provider.service_provider_name} ${provider.service_provider_surname} for R${price.toLocaleString()}`,
    notification_data: {
        job_cart_id: jobCartId,
        service_provider_id: serviceProviderId,
        quotation_price: price,
        service_provider_name: `${provider.service_provider_name} ${provider.service_provider_surname}`
    },
    created_at: new Date().toISOString()
};
```

**🚨 CRITICAL ISSUE #3:** Trying to access `jobCart.event.client_id` but `event` table has no `client_id` field!

**Correct Path:** `job_cart.client_id` (direct field)

---

## 📥 **STEP 2: CUSTOMER VIEWS QUOTATIONS**

### **File:** `js/customer-quotation.js`

### **View Process:**

#### **2.1 Customer Authentication Check**
```javascript
// Lines 14-69: DOMContentLoaded
if (!window.BookingSession) {
    console.error("❌ Booking Session Manager not loaded");
    showMessage("System error - please refresh the page", "error");
    return;
}

if (!window.BookingSession.isAuthenticated()) {
    console.error("❌ Authentication required - no active booking session");
    showMessage("Please log in to view quotations", "error");
    setTimeout(() => {
        window.location.href = 'Login.html';
    }, 2000);
    return;
}

clientId = window.BookingSession.getClientId();
```

**✅ GOOD:** Using centralized session management

---

#### **2.2 Load Quotations from Database**
```javascript
// Lines 90-187: loadQuotationsFromDatabase()
const { data: quotations, error: quotationError } = await supabase
    .from('quotation')
    .select(`
        quotation_id,
        service_id,                         // ✅ Direct field from quotation
        quotation_price,
        quotation_details,
        quotation_file_path,
        quotation_file_name,
        quotation_submission_date,
        quotation_submission_time,
        quotation_status,
        created_at,
        job_cart:job_cart_id (
            job_cart_id,
            job_cart_created_date,
            created_at
        ),
        service_provider:service_provider_id (
            service_provider_id,
            service_provider_name,
            service_provider_surname,
            service_provider_email,
            service_provider_contactno,
            service_provider_rating,
            service_provider_location
        ),
        service:service_id (
            service_id,
            service_name,
            service_type
        )
    `)
    .in('service_id', serviceIds)           // ✅ Filters by service_id array
    .eq('quotation_status', 'pending')      // ⚠️ MISMATCH: SP uploads as "confirmed"
    .gte('quotation_submission_date', today)
    .order('quotation_submission_date', { ascending: false });
```

**🚨 CRITICAL ISSUE #4:** Customer searches for **"pending"** quotations, but SP uploads them as **"confirmed"**!

**Result:** Customer will **NEVER see** the uploaded quotations! 🚨

---

#### **2.3 Display Quotations**
```javascript
// Lines 369-431: createQuotationCard()
<div class="quotation-card" 
     data-quotation-id="${quotation.quotation_id}" 
     data-service-id="${quotation.service_id}">
    
    <div class="quotation-header">
        <h4>${provider.service_provider_name} ${provider.service_provider_surname}</h4>
        <div class="provider-rating">
            <i class="fas fa-star"></i>
            <span>${provider.service_provider_rating || 'N/A'}</span>
        </div>
    </div>
    
    <div class="quotation-details">
        <div class="price">
            <span class="currency">R</span>
            <span class="amount">${quotation.quotation_price.toLocaleString()}</span>
        </div>
        
        <div class="provider-info">
            <p><i class="fas fa-map-marker-alt"></i> ${provider.service_provider_location || 'N/A'}</p>
            <p><i class="fas fa-calendar"></i> Submitted: ${new Date(quotation.quotation_submission_date).toLocaleDateString()}</p>
        </div>
    </div>
    
    <div class="quotation-description">
        <p>${quotation.quotation_details}</p>
    </div>
    
    <div class="quotation-actions">
        <button class="btn-select" onclick="selectQuotation('${quotation.quotation_id}')">
            Select This Quote
        </button>
        <button class="btn-view-file" onclick="viewQuotationFile('${quotation.quotation_file_path}')">
            View File
        </button>
    </div>
</div>
```

**✅ GOOD:** Well-structured quotation card display

---

## ✅ **STEP 3: CUSTOMER SELECTS QUOTATION**

### **File:** `js/customer-quotation.js`

### **Selection Process:**

#### **3.1 Customer Selects a Quotation**
```javascript
// Lines 434-505: selectQuotation()
function selectQuotation(quotationId) {
    // Get the service ID from the quotation card
    const selectedCard = document.querySelector(`[data-quotation-id="${quotationId}"]`);
    const serviceId = selectedCard.getAttribute('data-service-id');
    
    // Remove selection from other quotations in the same service group
    const serviceGroup = selectedCard.closest('.service-group');
    if (serviceGroup) {
        serviceGroup.querySelectorAll('.quotation-card').forEach(card => {
            card.classList.remove('selected');
            card.style.opacity = '1';
            card.style.pointerEvents = 'auto';
        });
    }
    
    // Select the current quotation
    selectedCard.classList.add('selected');
    
    // Disable other quotations in the same service group
    if (serviceGroup) {
        serviceGroup.querySelectorAll('.quotation-card:not(.selected)').forEach(card => {
            card.style.opacity = '0.6';
            card.style.pointerEvents = 'none';
        });
    }
    
    // Store the selection: {service_id: quotation_id}
    selectedQuotations[serviceId] = quotationId;
    
    // Store in localStorage for the summary page
    localStorage.setItem('selectedQuotations', JSON.stringify(selectedQuotations));
}
```

**✅ GOOD:** Proper UI feedback and storage

---

#### **3.2 Continue to Summary**
```javascript
// Lines 598-691: setupContinueButton()
continueBtn.onclick = async () => {
    // Fetch complete quotation details from database
    for (const serviceId of serviceIds) {
        const quotationId = selectedQuotations[serviceId];
        
        const { data: quotation, error } = await supabase
            .from('quotation')
            .select(`
                quotation_id,
                quotation_price,
                quotation_details,
                service_id,
                service_provider:service_provider_id (
                    service_provider_name,
                    service_provider_surname,
                    service_provider_email,
                    service_provider_contactno,
                    service_provider_location
                ),
                service:service_id (
                    service_name,
                    service_type,
                    service_description
                )
            `)
            .eq('quotation_id', quotationId)
            .single();

        selectedQuotationData.push({
            serviceId: serviceId,
            serviceName: serviceName,
            quotationId: quotationId,
            providerName: providerName,
            providerEmail: quotation.service_provider?.service_provider_email || 'N/A',
            providerPhone: quotation.service_provider?.service_provider_contactno || 'N/A',
            providerLocation: quotation.service_provider?.service_provider_location || 'N/A',
            price: parseFloat(quotation.quotation_price) || 0,
            details: quotation.quotation_details || quotation.service?.service_description || 'No details available'
        });
    }
    
    localStorage.setItem('selectedQuotationData', JSON.stringify(selectedQuotationData));
    window.location.href = 'summary.html';
};
```

**✅ GOOD:** Comprehensive data fetching and storage

---

## 🚨 **CRITICAL LOOPHOLES IDENTIFIED**

### **1. Non-Existent Table Reference**
**Location:** `sp-quotation.js` Line 168
```javascript
.from("job_cart_acceptance")  // ❌ Table doesn't exist
```

**Impact:** Service providers **cannot load job carts** to upload quotations

**Fix:**
```javascript
// Option 1: Use job_cart table directly
.from("job_cart")
.select(`
    job_cart_id,
    job_cart_item,
    job_cart_details,
    job_cart_status,
    service_id,
    client_id,
    event:event_id (...)
`)
.eq("job_cart_status", "pending")  // Only show pending job carts

// Option 2: Create job_cart_acceptance table
CREATE TABLE job_cart_acceptance (
    acceptance_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    job_cart_id uuid NOT NULL REFERENCES job_cart(job_cart_id),
    service_provider_id uuid NOT NULL REFERENCES service_provider(service_provider_id),
    acceptance_status text DEFAULT 'accepted',
    accepted_at timestamp DEFAULT now()
);
```

---

### **2. Status Mismatch**
**Upload:** `quotation_status: "confirmed"` (Line 474)
**Search:** `.eq('quotation_status', 'pending')` (Line 157)

**Impact:** Customers **NEVER see** uploaded quotations! 🚨

**Fix:**
```javascript
// sp-quotation.js Line 474
const quotationData = {
    // ...
    quotation_status: "pending",  // ✅ Changed from "confirmed"
    // ...
};
```

---

### **3. Invalid Foreign Key Path**
**Location:** `sp-quotation.js` Line 545
```javascript
client_id: jobCart.event.client_id  // ❌ event has no client_id
```

**Impact:** Notifications **fail silently**

**Fix:**
```javascript
// Get job cart details to find the client
const { data: jobCart, error: jobCartError } = await supabase
    .from("job_cart")
    .select(`
        client_id,      // ✅ Direct field
        event:event_id (
            event_type,
            event_date
        )
    `)
    .eq("job_cart_id", jobCartId)
    .single();

// Create notification for client
const notification = {
    client_id: jobCart.client_id,  // ✅ Direct access
    // ...
};
```

---

### **4. Data Redundancy**
**Upload:** Stores `service_id` in quotation table (Line 467)
**Schema:** `quotation.service_id` duplicates `job_cart.service_id`

**Impact:** Potential data inconsistency

**Fix:**
```javascript
// Remove service_id from quotation table
// Access via relationship: quotation.job_cart.service_id

const quotationData = {
    service_provider_id: serviceProviderId,
    job_cart_id: jobCartId,
    // service_id: serviceId,  // ❌ Remove this
    quotation_price: price,
    quotation_details: details,
    // ...
};

// Customer query should then use:
.from('quotation')
.select(`
    quotation_id,
    quotation_price,
    job_cart:job_cart_id (
        job_cart_id,
        service_id,  // ✅ Access via relationship
        service:service_id (
            service_name,
            service_type
        )
    ),
    service_provider:service_provider_id (...)
`)
.in('job_cart.service_id', serviceIds)  // ✅ Filter via relationship
```

---

## 📋 **DATA FLOW DIAGRAM**

```
┌─────────────────────────────────────────────────────────────────┐
│                     SERVICE PROVIDER SIDE                        │
└─────────────────────────────────────────────────────────────────┘

1. Load Job Carts
   ├─ Query: job_cart_acceptance (❌ Doesn't exist)
   ├─ Should: job_cart (✅ Direct)
   └─ Filter: acceptance_status = "accepted"

2. Upload Quotation
   ├─ Data: {
   │    service_provider_id: "uuid",
   │    job_cart_id: "uuid",
   │    service_id: "uuid",           (⚠️ Redundant)
   │    quotation_price: 5000,
   │    quotation_status: "confirmed" (❌ Should be "pending")
   │  }
   ├─ Insert: quotation table
   └─ Result: Quotation saved with wrong status

3. Send Notification
   ├─ Query: job_cart.event.client_id (❌ Invalid path)
   ├─ Should: job_cart.client_id      (✅ Direct)
   └─ Result: Notification fails

┌─────────────────────────────────────────────────────────────────┐
│                        CUSTOMER SIDE                             │
└─────────────────────────────────────────────────────────────────┘

4. View Quotations
   ├─ Query: quotation WHERE quotation_status = "pending"
   ├─ Problem: SP uploaded as "confirmed"
   └─ Result: NO QUOTATIONS FOUND ❌

5. Select Quotation
   ├─ Store: {service_id: quotation_id}
   ├─ localStorage: selectedQuotations
   └─ Result: Cannot proceed (no quotations to select)

6. Continue to Summary
   ├─ Fetch: Complete quotation details
   ├─ Store: selectedQuotationData
   └─ Redirect: summary.html

┌─────────────────────────────────────────────────────────────────┐
│                     BROKEN FLOW SUMMARY                          │
└─────────────────────────────────────────────────────────────────┘

Upload (confirmed) ────X──── View (pending) ────X──── Select
         ↓                           ↓                    ↓
   STATUS MISMATCH          NO RESULTS           NO QUOTATIONS
```

---

## 🎯 **IMMEDIATE FIXES REQUIRED**

### **Priority 1: Status Mismatch (CRITICAL)**
```javascript
// sp-quotation.js Line 474
quotation_status: "pending",  // ✅ Changed from "confirmed"
```

### **Priority 2: Job Cart Loading**
```javascript
// sp-quotation.js Line 167
// Option A: Use job_cart table directly
const { data: jobCarts, error } = await supabase
    .from("job_cart")
    .select(`
        job_cart_id,
        job_cart_item,
        job_cart_details,
        service_id,
        client_id,
        event:event_id (
            event_type,
            event_date,
            event_location
        )
    `)
    .eq("job_cart_status", "pending")
    .order("job_cart_created_date", { ascending: false });

// Option B: Create job_cart_acceptance table (see SQL above)
```

### **Priority 3: Notification Path**
```javascript
// sp-quotation.js Line 522
const { data: jobCart, error: jobCartError } = await supabase
    .from("job_cart")
    .select(`
        client_id,  // ✅ Direct field
        event:event_id (
            event_type,
            event_date
        )
    `)
    .eq("job_cart_id", jobCartId)
    .single();

// sp-quotation.js Line 545
const notification = {
    client_id: jobCart.client_id,  // ✅ Direct access
    // ...
};
```

### **Priority 4: Remove Data Redundancy**
```sql
-- Remove redundant service_id from quotation table
ALTER TABLE quotation DROP COLUMN service_id;
ALTER TABLE quotation DROP COLUMN event_id;
```

---

## ✅ **EXPECTED CORRECT FLOW**

```
┌─────────────────────────────────────────────────────────────────┐
│                   CORRECTED DATA FLOW                            │
└─────────────────────────────────────────────────────────────────┘

1. SP loads job_cart (pending status)
2. SP uploads quotation (status = "pending")
3. Client receives notification
4. Client views quotations (status = "pending") ✅ MATCH
5. Client selects quotation
6. Quotation status → "accepted"
7. Booking created → quotation status → "confirmed"
```

---

## 📊 **STATUS LIFECYCLE**

```
pending       (SP uploads)
   ↓
accepted      (Client selects)
   ↓
confirmed     (Booking created)
   ↓
completed     (Service delivered)
```

---

This analysis reveals **4 critical loopholes** that completely break the quotation flow! 🚨

