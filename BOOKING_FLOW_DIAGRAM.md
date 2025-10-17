# 📊 Booking Flow Diagram with Session Management

## 🔄 Complete Booking Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         LOGIN PAGE (Login.html)                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ ✅ User enters credentials                                   │   │
│  │ ✅ System validates client                                   │   │
│  │ ✅ Stores: localStorage.setItem('clientId', uuid)            │   │
│  │ ✅ Stores: localStorage.setItem('userName', 'Dineo Nyoni')   │   │
│  │ ✅ Stores: localStorage.setItem('userType', 'client')        │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              ↓                                       │
└──────────────────────────────┼───────────────────────────────────────┘
                               │
┌──────────────────────────────┼───────────────────────────────────────┐
│             BOOKINGS PAGE (bookings.html) - Steps 1-4                │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 📋 STEP 1: Check Authentication                               │ │
│  │   const clientId = localStorage.getItem('clientId')           │ │
│  │   if (!clientId) → redirect to Registration.html             │ │
│  │                                                               │ │
│  │ ✅ Initialize Booking Session:                                │ │
│  │   window.BookingSession.initializeSession(                   │ │
│  │       clientId,    // "ff33d598-3d94..."                    │ │
│  │       userName,    // "Dineo Nyoni"                         │ │
│  │       userType     // "client"                              │ │
│  │   )                                                          │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 📋 STEP 2: Create Event                                       │ │
│  │   User fills: event type, date, location, times              │ │
│  │                                                               │ │
│  │ ✅ Insert into database:                                      │ │
│  │   const { data } = await supabase.from('event').insert({...})│ │
│  │   eventId = data[0].event_id                                 │ │
│  │                                                               │ │
│  │ ✅ Store in session:                                          │ │
│  │   window.BookingSession.setEventId(                          │ │
│  │       eventId,              // "4c6702e9-189e..."           │ │
│  │       { event_type, date, location, ... }                   │ │
│  │   )                                                          │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 📋 STEP 3: Select Services                                    │ │
│  │   User selects: Photography, Catering, etc.                  │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 📋 STEP 4: Create Job Carts                                   │ │
│  │                                                               │ │
│  │ ✅ Insert into database:                                      │ │
│  │   for each selected service:                                 │ │
│  │     const { data } = await supabase.from('job_cart').insert({│ │
│  │         client_id: clientId,                                 │ │
│  │         event_id: eventId,                                   │ │
│  │         service_id: serviceId                                │ │
│  │     })                                                        │ │
│  │     jobCartId = data[0].job_cart_id                          │ │
│  │                                                               │ │
│  │ ✅ Store in session:                                          │ │
│  │   window.BookingSession.addJobCartId(                        │ │
│  │       jobCartId,            // "bdd52e09-4f15..."           │ │
│  │       serviceId             // "62799bba-be1d..."           │ │
│  │   )                                                          │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│  [User clicks "View Quotations" button]                             │
└──────────────────────────────┼───────────────────────────────────────┘
                               │
┌──────────────────────────────┼───────────────────────────────────────┐
│           QUOTATION PAGE (quotation.html) - Step 5                   │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 🔐 Check Authentication (NO RE-LOGIN!)                        │ │
│  │                                                               │ │
│  │ ❌ OLD WAY (Caused re-login):                                │ │
│  │   const clientId = localStorage.getItem('clientId')          │ │
│  │   const userType = localStorage.getItem('userType')          │ │
│  │   if (!clientId || userType !== 'client') {                 │ │
│  │       redirect to Login.html  ← PROBLEM!                    │ │
│  │   }                                                          │ │
│  │                                                               │ │
│  │ ✅ NEW WAY (Session persists):                               │ │
│  │   if (!window.BookingSession.isAuthenticated()) {            │ │
│  │       redirect to Login.html                                 │ │
│  │   }                                                          │ │
│  │   const clientId = window.BookingSession.getClientId()       │ │
│  │   const serviceIds = window.BookingSession.getSelectedServiceIds() │
│  └───────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 📋 Load Quotations                                            │ │
│  │   Query database for quotations matching:                    │ │
│  │     - client_id (from session)                               │ │
│  │     - job_cart_ids (from session)                            │ │
│  │     - service_ids (from session)                             │ │
│  │                                                               │ │
│  │ ✅ Display quotations to client                              │ │
│  │ ✅ Client selects quotation(s)                               │ │
│  │                                                               │ │
│  │ ✅ Store in session:                                          │ │
│  │   window.BookingSession.addAcceptedQuotation(                │ │
│  │       quotationId,          // "quote-uuid-1"               │ │
│  │       { price, details, ... }                               │ │
│  │   )                                                          │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│  [User clicks "Continue to Summary" button]                         │
└──────────────────────────────┼───────────────────────────────────────┘
                               │
┌──────────────────────────────┼───────────────────────────────────────┐
│             SUMMARY PAGE (summary.html) - Step 6                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 🔐 Check Authentication (NO RE-LOGIN!)                        │ │
│  │   if (!window.BookingSession.isAuthenticated()) {            │ │
│  │       redirect to Login.html                                 │ │
│  │   }                                                          │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 📋 Display Booking Summary                                    │ │
│  │   Load all data from session:                                │ │
│  │     - clientId                                               │ │
│  │     - eventId & eventDetails                                 │ │
│  │     - jobCartIds                                             │ │
│  │     - quotationIds                                           │ │
│  │     - totalAmount                                            │ │
│  │                                                               │ │
│  │ ✅ Client reviews and confirms                               │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 📋 Create Booking Record                                      │ │
│  │                                                               │ │
│  │ ✅ Insert into database:                                      │ │
│  │   const { data } = await supabase.from('booking').insert({   │ │
│  │       client_id: window.BookingSession.getClientId(),        │ │
│  │       event_id: window.BookingSession.getEventId(),          │ │
│  │       quotation_id: window.BookingSession.getAcceptedQuotationIds()[0], │
│  │       booking_total_price: window.BookingSession.getTotalAmount(), │
│  │       booking_status: 'pending_payment'                      │ │
│  │   })                                                          │ │
│  │   bookingId = data[0].booking_id                             │ │
│  │                                                               │ │
│  │ ✅ Store in session:                                          │ │
│  │   window.BookingSession.setBookingId(bookingId)              │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│  [User clicks "Proceed to Payment" button]                          │
└──────────────────────────────┼───────────────────────────────────────┘
                               │
┌──────────────────────────────┼───────────────────────────────────────┐
│             PAYMENT PAGE (payment.html) - Step 7                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 🔐 Check Authentication (NO RE-LOGIN!)                        │ │
│  │   if (!window.BookingSession.isAuthenticated()) {            │ │
│  │       redirect to Login.html                                 │ │
│  │   }                                                          │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 📋 Display Payment Form                                       │ │
│  │   Load booking data from session:                            │ │
│  │     - bookingId                                              │ │
│  │     - totalAmount                                            │ │
│  │     - clientId                                               │ │
│  │                                                               │ │
│  │ ✅ Client uploads proof of payment                           │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 📋 Create Payment Record                                      │ │
│  │                                                               │ │
│  │ ✅ Insert into database:                                      │ │
│  │   const { data } = await supabase.from('payment').insert({   │ │
│  │       client_id: window.BookingSession.getClientId(),        │ │
│  │       booking_id: window.BookingSession.getBookingId(),      │ │
│  │       payment_amount: window.BookingSession.getTotalAmount(), │
│  │       payment_status: 'pending_verification',                │ │
│  │       proof_of_payment_file_path: uploadedFilePath           │ │
│  │   })                                                          │ │
│  │   paymentId = data[0].payment_id                             │ │
│  │                                                               │ │
│  │ ✅ Store in session:                                          │ │
│  │   window.BookingSession.setPaymentId(paymentId)              │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│  [User clicks "Complete Booking" button]                            │
└──────────────────────────────┼───────────────────────────────────────┘
                               │
┌──────────────────────────────┼───────────────────────────────────────┐
│         CONFIRMATION PAGE (confirmation.html) - Step 8               │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ ✅ Display Full Booking Summary                               │ │
│  │   - Client Name                                              │ │
│  │   - Event Details                                            │ │
│  │   - Selected Services                                        │ │
│  │   - Accepted Quotations                                      │ │
│  │   - Booking ID                                               │ │
│  │   - Payment ID                                               │ │
│  │   - Total Amount                                             │ │
│  │                                                               │ │
│  │ ✅ Complete the session:                                      │ │
│  │   window.BookingSession.completeSession()                    │ │
│  │                                                               │ │
│  │ ✅ Send confirmation email                                    │ │
│  │ ✅ Show "Booking Complete" message                           │ │
│  └───────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────┘
```

---

## 🔑 Session Data Flow

```
Login → BookingSession.initializeSession()
        ↓
        {
          clientId: "ff33d598-3d94-4fc1-9287-8760290651d3",
          userName: "Dineo Nyoni",
          userType: "client"
        }

Step 2 → BookingSession.setEventId()
        ↓
        {
          ...previous data,
          eventId: "4c6702e9-189e-48ba-9991-b42af4e1e113",
          eventDetails: { type, date, location, ... }
        }

Step 4 → BookingSession.addJobCartId()
        ↓
        {
          ...previous data,
          jobCartIds: ["bdd52e09-4f15-4efc-9d4d-4ca6bb7f48a0"],
          selectedServiceIds: ["62799bba-be1d-468a-bbb3-0bc2eeccc542"]
        }

Step 5 → BookingSession.addAcceptedQuotation()
        ↓
        {
          ...previous data,
          acceptedQuotationIds: ["quote-uuid-1", "quote-uuid-2"]
        }

Step 6 → BookingSession.setBookingId()
        ↓
        {
          ...previous data,
          bookingId: "booking-uuid"
        }

Step 7 → BookingSession.setPaymentId()
        ↓
        {
          ...previous data,
          paymentId: "payment-uuid"
        }

Step 8 → BookingSession.completeSession()
        ↓
        { ...all data, isActive: false }
```

---

## 🎯 Key Takeaway

**Every page now has consistent access to ALL booking data through `window.BookingSession`!**

No more:
- ❌ Re-login prompts
- ❌ Missing clientId errors
- ❌ Inconsistent localStorage keys
- ❌ Lost booking data between pages

**The entire booking flow is now ONE CONTINUOUS SESSION!** 🎉

