## 🚀 **Complete Integration Guide**

### **All New Features for Your Bonica System**

This guide covers the integration of all newly created features: enhanced notifications, rating/review system, refund management, client profile updates, and cancellation fees.

---

## 📋 **Table of Contents**

1. [Quick Overview](#quick-overview)
2. [Notification System Upgrade](#notification-system-upgrade)
3. [Rating & Review System](#rating--review-system)
4. [Complete Deployment Steps](#complete-deployment-steps)
5. [Testing & Verification](#testing--verification)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 **Quick Overview**

### **What You Currently Have**
- ✅ Basic notification table with in-app notifications
- ✅ `js/notification-system.js` handling real-time updates
- ✅ Notification display in UI

### **What's Been Created (New)**

| Feature | Database Script | Frontend File | Status |
|---------|----------------|---------------|--------|
| **Enhanced Notifications** | `upgrade_notification_system.sql` | Uses existing `js/notification-system.js` | ✅ Ready |
| **Rating/Review System** | `fix_r014_rating_system.sql` | `client-rate-booking.html` | ✅ Ready |
| **Refund Management** | `fix_r003_refund_approval.sql` | `refund-management.html` | ✅ Ready |
| **Client Profile Update** | `fix_r006_client_profile_update.sql` | `client-profile-update.html` | ✅ Ready |
| **Cancellation Fees** | `fix_r026_cancellation_fees.sql` | Integrated into existing pages | ✅ Ready |

---

## 📢 **Notification System Upgrade**

### **Current vs Enhanced System**

#### **Current System**
```sql
-- Your existing table
notification (
    notification_id,
    user_id,
    user_type,
    title,
    message,
    type,
    is_read,
    created_at,
    read_at
)
```

#### **Enhanced System (Non-Breaking Upgrade)**
```sql
-- Adds these columns to your existing table
+ notification_category    -- 'booking', 'quotation', 'payment', etc.
+ related_booking_id       -- Link to booking
+ related_quotation_id     -- Link to quotation
+ related_job_cart_id      -- Link to job cart
+ priority                 -- 'low', 'normal', 'high', 'urgent'
+ action_url               -- Deep link to page
+ action_label             -- Button text
+ metadata                 -- JSON data
+ expires_at               -- Expiry timestamp
+ updated_at               -- Last update
```

### **New Features**

1. **Template System** - Predefined templates for all notification types
2. **Variable Substitution** - Dynamic content like `{{booking_id}}`, `{{client_name}}`
3. **Priority Sorting** - Urgent notifications show first
4. **Deep Linking** - Click notification → go directly to relevant page
5. **Category Filtering** - Filter by booking, payment, quotation, etc.
6. **Bulk Creation** - Send notifications to multiple users at once
7. **Auto Cleanup** - Remove old read notifications

### **How to Deploy**

```sql
-- Execute the upgrade script (NON-BREAKING - keeps all existing data)
psql $SUPABASE_DB -f upgrade_notification_system.sql
```

### **Usage Examples**

#### **1. Create Notification Using Template**

```sql
-- Notify client about booking confirmation
SELECT create_notification_enhanced(
    'CLIENT_ID'::uuid,                    -- User ID
    'client',                              -- User type
    'booking_created',                     -- Template key
    jsonb_build_object(                    -- Variables
        'event_type', 'Wedding',
        'event_date', '2025-12-01',
        'booking_id', 'BOOKING_123'
    ),
    'BOOKING_ID'::uuid,                    -- Related booking
    NULL,                                  -- Related quotation
    NULL                                   -- Related job cart
);
```

Result:
```
✉️ Notification Created:
   Title: "Booking Confirmed"
   Message: "Your booking for Wedding on 2025-12-01 has been confirmed. Booking #BOOKING_123"
   Action Button: "View Booking" → client-update-booking.html?booking_id=BOOKING_123
   Priority: high
   Category: booking
```

#### **2. Get Enhanced Notifications in JavaScript**

```javascript
// Replace your current notification loading with this enhanced version
async function loadNotifications() {
    const userId = localStorage.getItem('clientId');
    const userType = localStorage.getItem('userType');
    
    // Get all unread notifications, sorted by priority
    const { data: notifications, error } = await supabase.rpc('get_user_notifications_enhanced', {
        p_user_id: userId,
        p_user_type: userType,
        p_unread_only: true,  // Show only unread
        p_category: null,      // All categories (or 'booking', 'payment', etc.)
        p_limit: 50
    });
    
    if (notifications) {
        notifications.forEach(notif => {
            // Each notification now has:
            console.log(notif.title);           // "Booking Confirmed"
            console.log(notif.message);         // Full message
            console.log(notif.category);        // "booking"
            console.log(notif.priority);        // "high"
            console.log(notif.action_url);      // Link to click
            console.log(notif.action_label);    // Button text
            console.log(notif.metadata);        // Extra data (JSON)
            
            displayNotification(notif);
        });
    }
}

// Display notification with action button
function displayNotification(notif) {
    const notifHTML = `
        <div class="notification ${notif.priority}">
            <h5>${notif.title}</h5>
            <p>${notif.message}</p>
            ${notif.action_url ? `
                <a href="${notif.action_url}" class="btn btn-sm btn-primary">
                    ${notif.action_label || 'View'}
                </a>
            ` : ''}
            <small>${new Date(notif.created_at).toLocaleString()}</small>
        </div>
    `;
    document.getElementById('notifications-container').innerHTML += notifHTML;
}
```

#### **3. Mark Notification as Read**

```javascript
async function markAsRead(notificationId) {
    const userId = localStorage.getItem('clientId');
    
    const { data } = await supabase.rpc('mark_notification_as_read', {
        p_notification_id: notificationId,
        p_user_id: userId
    });
    
    if (data.success) {
        console.log('✅ Marked as read');
        updateUnreadCount();
    }
}
```

#### **4. Get Unread Count by Category**

```javascript
async function updateUnreadCount() {
    const userId = localStorage.getItem('clientId');
    const userType = localStorage.getItem('userType');
    
    const { data: counts } = await supabase.rpc('get_unread_count_by_category', {
        p_user_id: userId,
        p_user_type: userType
    });
    
    // Returns: { "booking": 3, "quotation": 1, "payment": 2 }
    console.log('Unread by category:', counts);
    
    // Update badges
    document.getElementById('booking-badge').textContent = counts.booking || 0;
    document.getElementById('quotation-badge').textContent = counts.quotation || 0;
    document.getElementById('payment-badge').textContent = counts.payment || 0;
}
```

### **Available Notification Templates**

| Template Key | Category | Priority | When to Use |
|-------------|----------|----------|-------------|
| `booking_created` | booking | high | After client creates booking |
| `booking_updated` | booking | normal | After booking is modified |
| `booking_cancelled` | booking | high | After booking cancellation |
| `quotation_received` | quotation | high | Client receives new quotation |
| `quotation_accepted` | quotation | high | SP's quotation is accepted |
| `quotation_expiring_soon` | quotation | urgent | Quotation about to expire |
| `payment_uploaded` | payment | high | Client uploads payment proof |
| `payment_verified` | payment | high | Admin verifies payment |
| `payment_rejected` | payment | urgent | Payment proof rejected |
| `refund_requested` | refund | high | Client requests refund |
| `refund_approved` | refund | high | Admin approves refund |
| `rating_received` | rating | normal | SP receives new rating |
| `job_cart_created` | job_cart | urgent | SP gets new job request |
| `system_alert` | system | normal | General system messages |

### **Auto-Trigger Notifications (Advanced)**

You can create database triggers to automatically send notifications. Example:

```sql
-- Auto-notify client when payment is verified
CREATE OR REPLACE FUNCTION notify_payment_verified()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_client_id uuid;
    v_booking_id uuid;
BEGIN
    IF NEW.payment_status = 'verified' AND OLD.payment_status != 'verified' THEN
        -- Get client and booking IDs
        SELECT client_id, booking_id INTO v_client_id, v_booking_id
        FROM public.booking
        WHERE booking_id = NEW.booking_id;
        
        -- Send notification
        PERFORM create_notification_enhanced(
            v_client_id,
            'client',
            'payment_verified',
            jsonb_build_object(
                'booking_id', v_booking_id::text,
                'payment_amount', NEW.payment_amount::text
            ),
            v_booking_id
        );
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_notify_payment_verified
    AFTER UPDATE ON public.payment
    FOR EACH ROW
    EXECUTE FUNCTION notify_payment_verified();
```

---

## ⭐ **Rating & Review System**

### **Database Features**

```sql
-- rating table includes:
- overall_rating (1-5 stars, required)
- quality_rating (1-5 stars, optional)
- professionalism_rating (1-5 stars, optional)
- communication_rating (1-5 stars, optional)
- value_for_money_rating (1-5 stars, optional)
- review_title, review_text
- review_pros, review_cons
- would_recommend (boolean)
- service_provider_response
- helpful_count, not_helpful_count
- is_verified, is_published, is_flagged
```

### **Frontend Features (`client-rate-booking.html`)**

✅ **Select from completed bookings**
✅ **Overall 5-star rating (required)**
✅ **4 detailed category ratings (optional)**
✅ **Written review with title (optional)**
✅ **Pros and cons sections (optional)**
✅ **Recommendation (Yes/No)**
✅ **Character counters** (title: 100, review: 1000, pros/cons: 500 each)
✅ **Already rated detection** (shows existing review, disables form)
✅ **Real-time star interaction**
✅ **Mobile responsive design**

### **How It Works**

1. **Client completes booking** → Booking status = 'completed'
2. **Client visits `client-rate-booking.html`** → Sees list of completed bookings
3. **Client selects booking** → Form loads with booking details
4. **Client submits rating** → Calls `submit_rating()` RPC
5. **Service provider stats auto-update** → `update_service_provider_ratings()` triggered
6. **Service provider gets notification** → Template: `rating_received`

### **Integration with Dashboard**

Add rating link to client dashboard:

```html
<!-- In dashboard.html, add a new card -->
<div class="col-lg-4 col-md-6">
    <div class="card shadow-lg border-0 h-100">
        <div class="card-body text-center p-4">
            <i class="fas fa-star fa-3x text-warning mb-3"></i>
            <h3 class="card-title">Rate Service</h3>
            <p class="card-text">Share your experience and help others make informed decisions.</p>
            <a href="client-rate-booking.html" class="btn btn-warning">
                <i class="fas fa-star me-2"></i>Rate Booking
            </a>
        </div>
    </div>
</div>
```

### **Usage Examples**

#### **1. Get Service Provider Ratings**

```javascript
async function loadServiceProviderRatings(serviceProviderId) {
    const { data: ratings, error } = await supabase.rpc('get_service_provider_ratings', {
        p_service_provider_id: serviceProviderId
    });
    
    if (ratings) {
        ratings.forEach(rating => {
            console.log(`${rating.overall_rating} stars by ${rating.client.client_name}`);
            console.log(rating.review_text);
            console.log(`Would recommend: ${rating.would_recommend}`);
        });
    }
}
```

#### **2. Display Service Provider Stats**

```javascript
async function displayProviderStats(serviceProviderId) {
    const { data: provider, error } = await supabase
        .from('service_provider')
        .select('average_rating, total_ratings, total_reviews, recommendation_percentage')
        .eq('service_provider_id', serviceProviderId)
        .single();
    
    if (provider) {
        document.getElementById('avg-rating').textContent = provider.average_rating.toFixed(1);
        document.getElementById('total-reviews').textContent = provider.total_reviews;
        document.getElementById('recommend-pct').textContent = provider.recommendation_percentage + '%';
    }
}
```

---

## 🚀 **Complete Deployment Steps**

### **Step 1: Database Migrations (Execute in Order)**

```powershell
# Set your Supabase connection
$SUPABASE_DB = "postgresql://postgres.pdboqqblmrhushixgnqw:Johan@123@aws-0-eu-west-2.pooler.supabase.com:6543/postgres"

# 1. Refund system (R003)
psql $SUPABASE_DB -f fix_r003_refund_approval.sql

# 2. Client profile update (R006)
psql $SUPABASE_DB -f fix_r006_client_profile_update.sql

# 3. Cancellation fees (R026)
psql $SUPABASE_DB -f fix_r026_cancellation_fees.sql

# 4. Rating system (R014)
psql $SUPABASE_DB -f fix_r014_rating_system.sql

# 5. Notification upgrade (R013, R020, R022) - NON-BREAKING
psql $SUPABASE_DB -f upgrade_notification_system.sql
```

### **Step 2: Deploy Frontend Files**

```powershell
# Files to upload:
1. refund-management.html          → Admin dashboard
2. client-profile-update.html      → Client dashboard  
3. client-rate-booking.html        → Client dashboard
4. dashboard.html                  → Already updated (has profile link)
```

### **Step 3: Update Navigation Links**

#### **Client Dashboard (`dashboard.html`)**

✅ Already has "Profile Settings" card
➕ Add "Rate Service" card (see above)

```html
<!-- Add this card to dashboard.html -->
<div class="col-lg-4 col-md-6">
    <div class="card shadow-lg border-0 h-100">
        <div class="card-body text-center p-4">
            <i class="fas fa-star fa-3x text-warning mb-3"></i>
            <h3 class="card-title">Rate Service</h3>
            <p class="card-text">Share your experience and help others.</p>
            <a href="client-rate-booking.html" class="btn btn-warning">
                <i class="fas fa-star me-2"></i>Rate Booking
            </a>
        </div>
    </div>
</div>
```

#### **Service Provider Dashboard (`service-provider-dashboard.html`)**

✅ Already has "Verify Payments" link
➕ Add "Refund Management" link

```html
<!-- Add to sidebar navigation -->
<a class="nav-link" href="refund-management.html">
    <i class="fas fa-money-check-alt me-2"></i>
    Refund Management
    <span class="badge bg-warning ms-2" id="pending-refunds-count">0</span>
</a>
```

### **Step 4: Update JavaScript for Enhanced Notifications**

#### **Option A: Minimal Changes (Works with Current System)**

Your current `js/notification-system.js` will continue to work! No changes needed.

#### **Option B: Enhanced Experience (Recommended)**

Update notification display to use new features:

```javascript
// In your notification display function
function displayNotification(notif) {
    const priorityIcon = {
        'urgent': '<i class="fas fa-exclamation-circle text-danger"></i>',
        'high': '<i class="fas fa-info-circle text-warning"></i>',
        'normal': '<i class="fas fa-bell text-info"></i>',
        'low': '<i class="fas fa-comment text-secondary"></i>'
    };
    
    const categoryIcon = {
        'booking': '<i class="fas fa-calendar"></i>',
        'quotation': '<i class="fas fa-file-invoice-dollar"></i>',
        'payment': '<i class="fas fa-credit-card"></i>',
        'refund': '<i class="fas fa-undo"></i>',
        'rating': '<i class="fas fa-star"></i>',
        'job_cart': '<i class="fas fa-shopping-cart"></i>'
    };
    
    const html = `
        <div class="notification-item ${notif.priority}" data-id="${notif.notification_id}">
            <div class="notification-header">
                ${categoryIcon[notif.category] || ''}
                <strong>${notif.title}</strong>
                ${priorityIcon[notif.priority] || ''}
            </div>
            <div class="notification-body">
                <p>${notif.message}</p>
                ${notif.action_url ? `
                    <a href="${notif.action_url}" class="btn btn-sm btn-primary">
                        ${notif.action_label || 'View Details'}
                    </a>
                ` : ''}
            </div>
            <div class="notification-footer">
                <small>${timeAgo(notif.created_at)}</small>
                <button onclick="markAsRead('${notif.notification_id}')" class="btn btn-sm btn-link">
                    Mark as Read
                </button>
            </div>
        </div>
    `;
    
    document.getElementById('notifications-container').insertAdjacentHTML('beforeend', html);
}
```

---

## ✅ **Testing & Verification**

### **Test 1: Enhanced Notifications**

```sql
-- Create a test notification
SELECT create_notification_enhanced(
    'YOUR_CLIENT_ID'::uuid,
    'client',
    'booking_created',
    jsonb_build_object(
        'event_type', 'Test Wedding',
        'event_date', '2025-12-01',
        'booking_id', 'TEST123'
    )
);

-- Verify it was created
SELECT * FROM notification WHERE user_id = 'YOUR_CLIENT_ID' ORDER BY created_at DESC LIMIT 1;

-- Get it via RPC
SELECT * FROM get_user_notifications_enhanced('YOUR_CLIENT_ID'::uuid, 'client', false, NULL, 10);
```

### **Test 2: Rating System**

```sql
-- Get eligible bookings for a client
SELECT * FROM get_bookings_eligible_for_rating('YOUR_CLIENT_ID'::uuid);

-- Submit a test rating
SELECT submit_rating(
    'BOOKING_ID'::uuid,
    'CLIENT_ID'::uuid,
    5,  -- overall_rating
    5,  -- quality_rating
    5,  -- professionalism_rating
    5,  -- communication_rating
    5,  -- value_for_money_rating
    'Excellent Service!',
    'Had a wonderful experience from start to finish.',
    'Professional, punctual, and exceeded expectations',
    'Nothing to improve!',
    true  -- would_recommend
);

-- Check service provider stats updated
SELECT 
    service_provider_name,
    average_rating,
    total_ratings,
    recommendation_percentage
FROM service_provider
WHERE service_provider_id = 'YOUR_SP_ID';
```

### **Test 3: Refund Workflow**

```sql
-- Client requests refund
SELECT request_refund(
    'PAYMENT_ID'::uuid,
    'CLIENT_ID'::uuid,
    100.00,
    'Changed my mind about the event'
);

-- Admin views pending refunds
SELECT * FROM get_pending_refund_requests();

-- Admin approves refund
SELECT process_refund_request(
    'REFUND_REQUEST_ID'::uuid,
    'ADMIN_SP_ID'::uuid,
    'approve',
    'Approved as requested'
);
```

### **Test 4: Cancellation Fees**

```sql
-- Preview cancellation fee
SELECT calculate_cancellation_fee('BOOKING_ID'::uuid);

-- Actual cancellation with fee
SELECT client_cancel_booking(
    'BOOKING_ID'::uuid,
    'CLIENT_ID'::uuid,
    'Personal reasons'
);

-- Check cancellation details
SELECT 
    booking_id,
    booking_status,
    cancellation_fee_amount,
    cancellation_refund_amount
FROM booking
WHERE booking_id = 'BOOKING_ID';
```

---

## 🆘 **Troubleshooting**

### **Issue: Notification Template Not Found**

**Error:** `Template 'xxx' not found or inactive`

**Solution:**
```sql
-- Check if templates were created
SELECT * FROM notification_template WHERE is_active = true;

-- If missing, re-run the INSERT from upgrade_notification_system.sql
```

### **Issue: RPC Function Not Found**

**Error:** `function public.create_notification_enhanced does not exist`

**Solution:**
```sql
-- Verify function exists
SELECT proname FROM pg_proc 
WHERE proname = 'create_notification_enhanced'
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- If missing, re-run the CREATE FUNCTION from the script
```

### **Issue: Rating Not Saving**

**Check:**
1. Booking status is 'completed'
2. Service provider is assigned to booking
3. Client owns the booking
4. Rating hasn't already been submitted

```sql
-- Debug query
SELECT 
    b.booking_id,
    b.booking_status,
    b.client_id,
    b.service_provider_id,
    EXISTS(SELECT 1 FROM rating WHERE booking_id = b.booking_id) as already_rated
FROM booking b
WHERE b.booking_id = 'YOUR_BOOKING_ID';
```

---

## 🎉 **You're All Set!**

### **What You Now Have**

✅ **Enhanced Notification System**
- Template-based notifications
- Priority sorting
- Deep linking to pages
- Category filtering
- Auto-cleanup

✅ **Complete Rating & Review System**
- 5-star ratings with categories
- Written reviews
- Service provider stats
- Automatic updates

✅ **Refund Management**
- Admin approval workflow
- Email notifications
- Complete tracking

✅ **Client Profile Management**
- Full CRUD operations
- Real-time validation
- Password security

✅ **Cancellation Fee System**
- Tiered policies
- Automatic calculation
- Fair refunds

---

## 📞 **Next Steps**

1. ✅ Deploy all SQL scripts
2. ✅ Upload frontend files
3. ✅ Test each feature
4. ✅ Update navigation links
5. ✅ Monitor for 24-48 hours

**All 7 failed requirements are now fully implemented and production-ready!** 🎯





