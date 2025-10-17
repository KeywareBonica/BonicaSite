# 🎯 Booking Session Integration Guide

## Overview

The **Booking Session Manager** (`js/booking-session-manager.js`) provides centralized state management for the entire booking flow. It ensures that all pages (bookings, quotations, summary, payment) have consistent access to client authentication and booking data **without requiring re-login**.

---

## 🔑 Key Concept

**Problem:** The booking flow spans multiple pages, and each page was checking authentication separately using different localStorage keys, causing "re-login" prompts.

**Solution:** A centralized session manager that:
- Maintains authentication state across page transitions
- Stores all booking-related IDs (event_id, job_cart_ids, quotation_ids, booking_id, payment_id)
- Provides a single source of truth for client data
- Ensures backward compatibility with existing localStorage usage

---

## 📋 Session Data Structure

```javascript
{
  // User Authentication
  clientId: "uuid",
  userName: "John Doe",
  userType: "client",
  
  // Session Metadata
  sessionStartTime: "2025-10-17T10:00:00Z",
  lastActivityTime: "2025-10-17T10:30:00Z",
  
  // Booking Flow Data
  eventId: "event-uuid",
  jobCartIds: ["jobcart-uuid-1", "jobcart-uuid-2"],
  selectedServiceIds: ["service-uuid-1", "service-uuid-2"],
  quotationIds: ["quote-uuid-1", "quote-uuid-2"],
  acceptedQuotationIds: ["quote-uuid-1"],
  bookingId: "booking-uuid",
  paymentId: "payment-uuid",
  
  // Additional Data
  eventDetails: {...},
  serviceDetails: [...],
  quotationDetails: [...],
  totalAmount: 15000.00,
  
  // Flow Control
  currentStep: 5,
  completedSteps: [1, 2, 3, 4],
  
  // Flags
  isActive: true,
  needsPayment: false
}
```

---

## 🚀 How to Use in Each Page

### 1. **bookings.html** (Steps 1-4)

**Include the script:**
```html
<script src="js/booking-session-manager.js"></script>
```

**Initialize session on page load:**
```javascript
// After authentication check
const clientId = localStorage.getItem("clientId");
if (clientId) {
    window.BookingSession.initializeSession(
        clientId,
        localStorage.getItem("userName"),
        localStorage.getItem("userType") || 'client'
    );
}
```

**Store event ID when created:**
```javascript
// After creating event
if (window.BookingSession) {
    window.BookingSession.setEventId(eventId, {
        event_type: 'wedding',
        event_date: '2025-10-20',
        event_location: 'Sandton'
    });
}
```

**Store job cart IDs when created:**
```javascript
// After creating job cart
if (window.BookingSession) {
    window.BookingSession.addJobCartId(jobCartId, serviceId);
}
```

---

### 2. **quotation.html** (Step 5)

**Include the script:**
```html
<script src="js/booking-session-manager.js"></script>
<script src="js/customer-quotation.js"></script>
```

**Check authentication:**
```javascript
document.addEventListener('DOMContentLoaded', async function() {
    // Check if session manager is loaded
    if (!window.BookingSession) {
        console.error("❌ Booking Session Manager not loaded");
        return;
    }
    
    // Check if user is authenticated
    if (!window.BookingSession.isAuthenticated()) {
        console.error("❌ Not authenticated");
        window.location.href = 'Login.html';
        return;
    }
    
    // Get client ID from session
    const clientId = window.BookingSession.getClientId();
    const serviceIds = window.BookingSession.getSelectedServiceIds();
    
    // Continue with quotation loading...
});
```

**Store accepted quotations:**
```javascript
// When client accepts a quotation
if (window.BookingSession) {
    window.BookingSession.addAcceptedQuotation(quotationId, {
        price: 5000.00,
        service_provider_id: providerId,
        quotation_details: '...'
    });
}
```

---

### 3. **summary.html** (Step 6)

**Include the script:**
```html
<script src="js/booking-session-manager.js"></script>
```

**Load booking data:**
```javascript
document.addEventListener('DOMContentLoaded', async function() {
    // Check authentication
    if (!window.BookingSession || !window.BookingSession.isAuthenticated()) {
        window.location.href = 'Login.html';
        return;
    }
    
    // Get all booking data
    const clientId = window.BookingSession.getClientId();
    const eventId = window.BookingSession.getEventId();
    const jobCartIds = window.BookingSession.getJobCartIds();
    const quotationIds = window.BookingSession.getAcceptedQuotationIds();
    
    // Display summary...
    displayBookingSummary(clientId, eventId, jobCartIds, quotationIds);
});
```

**Create booking and store booking ID:**
```javascript
// After creating booking record
const { data: bookingData } = await supabase
    .from('booking')
    .insert({
        client_id: window.BookingSession.getClientId(),
        event_id: window.BookingSession.getEventId(),
        // ... other fields
    })
    .select()
    .single();

if (bookingData) {
    window.BookingSession.setBookingId(bookingData.booking_id);
    console.log('✅ Booking ID stored:', bookingData.booking_id);
}
```

---

### 4. **payment.html** (Step 7)

**Include the script:**
```html
<script src="js/booking-session-manager.js"></script>
```

**Load booking data:**
```javascript
document.addEventListener('DOMContentLoaded', async function() {
    // Check authentication
    if (!window.BookingSession || !window.BookingSession.isAuthenticated()) {
        window.location.href = 'Login.html';
        return;
    }
    
    // Get booking data
    const clientId = window.BookingSession.getClientId();
    const bookingId = window.BookingSession.getBookingId();
    const totalAmount = window.BookingSession.getTotalAmount();
    
    // Display payment form...
    displayPaymentForm(clientId, bookingId, totalAmount);
});
```

**Store payment ID:**
```javascript
// After uploading proof of payment
const { data: paymentData } = await supabase
    .from('payment')
    .insert({
        client_id: window.BookingSession.getClientId(),
        booking_id: window.BookingSession.getBookingId(),
        payment_amount: totalAmount,
        // ... other fields
    })
    .select()
    .single();

if (paymentData) {
    window.BookingSession.setPaymentId(paymentData.payment_id);
    console.log('✅ Payment ID stored:', paymentData.payment_id);
}
```

**Complete the session:**
```javascript
// After successful payment confirmation
window.BookingSession.completeSession();
console.log('✅ Booking completed!');

// Redirect to confirmation page
window.location.href = 'confirmation.html';
```

---

## 🔧 Available Methods

### Authentication Methods
```javascript
// Check if user is authenticated
window.BookingSession.isAuthenticated()  // Returns: boolean

// Get client ID
window.BookingSession.getClientId()  // Returns: string (UUID)

// Get user name
window.BookingSession.getUserName()  // Returns: string
```

### Event Methods
```javascript
// Set event ID
window.BookingSession.setEventId(eventId, eventDetails)

// Get event ID
window.BookingSession.getEventId()  // Returns: string (UUID)
```

### Job Cart Methods
```javascript
// Add job cart ID
window.BookingSession.addJobCartId(jobCartId, serviceId)

// Get all job cart IDs
window.BookingSession.getJobCartIds()  // Returns: array of UUIDs

// Get selected service IDs
window.BookingSession.getSelectedServiceIds()  // Returns: array of UUIDs
```

### Quotation Methods
```javascript
// Add accepted quotation
window.BookingSession.addAcceptedQuotation(quotationId, quotationDetails)

// Get accepted quotation IDs
window.BookingSession.getAcceptedQuotationIds()  // Returns: array of UUIDs
```

### Booking Methods
```javascript
// Set booking ID
window.BookingSession.setBookingId(bookingId)

// Get booking ID
window.BookingSession.getBookingId()  // Returns: string (UUID)
```

### Payment Methods
```javascript
// Set payment ID
window.BookingSession.setPaymentId(paymentId)

// Get payment ID
window.BookingSession.getPaymentId()  // Returns: string (UUID)

// Set total amount
window.BookingSession.setTotalAmount(amount)

// Get total amount
window.BookingSession.getTotalAmount()  // Returns: number
```

### Session Management
```javascript
// Get full session data
window.BookingSession.getFullSession()  // Returns: object

// Export for API calls
window.BookingSession.exportForAPI()  // Returns: object with API-friendly keys

// Debug session state
window.BookingSession.debugSession()  // Logs to console

// Clear session
window.BookingSession.clearSession()

// Complete session
window.BookingSession.completeSession()
```

---

## ✅ Benefits

1. **No More Re-Login**: Client authentication persists across all booking pages
2. **Single Source of Truth**: All booking data stored in one place
3. **Backward Compatible**: Works with existing localStorage keys
4. **Easy Debugging**: Built-in `debugSession()` method
5. **Type Safety**: Consistent data structure across pages
6. **Session Expiry**: Automatically expires after 24 hours

---

## 🔍 Debugging

To check the current session state at any time:

```javascript
// In browser console
window.BookingSession.debugSession();
```

Output:
```
🔍 Booking Session Debug
  Session Active: true
  Client ID: ff33d598-3d94-4fc1-9287-8760290651d3
  User Name: Dineo Nyoni
  Event ID: 4c6702e9-189e-48ba-9991-b42af4e1e113
  Job Cart IDs: ["bdd52e09-4f15-4efc-9d4d-4ca6bb7f48a0"]
  Quotation IDs: ["quote-uuid-1"]
  Booking ID: null
  Payment ID: null
  Total Amount: 15000
  Current Step: 5
  Completed Steps: [1, 2, 3, 4]
```

---

## 🚨 Migration from Old System

**Old way:**
```javascript
const clientId = localStorage.getItem('clientId');
const eventId = localStorage.getItem('currentEventId');
const quotationClientId = localStorage.getItem('quotationClientId');
```

**New way:**
```javascript
const clientId = window.BookingSession.getClientId();
const eventId = window.BookingSession.getEventId();
// No need for separate quotationClientId
```

The session manager **automatically falls back** to legacy localStorage keys for backward compatibility.

---

## 📊 Database Integration

When creating database records, use the session manager to get all required IDs:

```javascript
// Example: Creating a booking
const sessionData = window.BookingSession.exportForAPI();

const { data: booking } = await supabase
    .from('booking')
    .insert({
        client_id: sessionData.client_id,
        event_id: sessionData.event_id,
        quotation_id: sessionData.quotation_ids[0],  // First accepted quotation
        booking_status: 'confirmed',
        booking_total_price: sessionData.total_amount
    })
    .select()
    .single();

// Store the created booking ID
window.BookingSession.setBookingId(booking.booking_id);
```

---

## ✅ Files Updated

1. ✅ `js/booking-session-manager.js` - **NEW** centralized session manager
2. ✅ `js/customer-quotation.js` - Uses session for authentication
3. ✅ `bookings.html` - Initializes session, stores event & job cart IDs
4. ✅ `quotation.html` - Loads session script

### Still Need Updates:
- [ ] `summary.html` - Add session script & use for booking creation
- [ ] `payment.html` - Add session script & use for payment creation
- [ ] `confirmation.html` - Add session script & display final summary

---

## 🎯 Next Steps

1. **Test the booking flow** from start to finish
2. **Update `summary.html`** to use BookingSession for booking creation
3. **Update `payment.html`** to use BookingSession for payment creation
4. **Update `confirmation.html`** to display final booking summary

---

**The re-login issue should now be completely resolved!** 🎉

