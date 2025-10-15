# Secure Booking Update Implementation Guide

## Overview
This guide shows how to update your JavaScript code to use the new secure database functions that verify booking ownership.

---

## 1. CLIENT UPDATE BOOKING

### ❌ BEFORE (INSECURE - Current Code)
```javascript
// client-update-booking.html - Lines 794-827
async function confirmUpdate() {
    // NO AUTHORIZATION CHECK!
    
    // Direct update to event table
    const { error: eventError } = await supabase
        .from('event')
        .update({
            event_date: newEventDate,
            event_location: newLocation,
            event_start_time: newStartTime,
            event_end_time: newEndTime
        })
        .eq('event_id', currentBooking.event?.event_id);
    
    // Direct update to booking table
    const { error: bookingError } = await supabase
        .from('booking')
        .update({
            booking_special_requests: newSpecialRequests,
            booking_min_price: parseFloat(newMinPrice),
            booking_max_price: parseFloat(newMaxPrice)
        })
        .eq('booking_id', currentBooking.booking_id);
    
    // PROBLEM: Anyone can update ANY booking by changing booking_id!
}
```

### ✅ AFTER (SECURE - New Code)
```javascript
// client-update-booking.html - Replace confirmUpdate function
async function confirmUpdate() {
    try {
        // Show loading state
        const saveBtn = document.querySelector('#confirmationModal .btn-primary');
        saveBtn.innerHTML = '<span class="loading"></span> Saving...';
        saveBtn.disabled = true;

        // Get updated values
        const newEventDate = document.getElementById('updateEventDate').value;
        const newLocation = document.getElementById('updateLocation').value;
        const newStartTime = document.getElementById('updateStartTime').value;
        const newEndTime = document.getElementById('updateEndTime').value;
        const newSpecialRequests = document.getElementById('updateSpecialRequests').value;
        const newMinPrice = document.getElementById('updateMinPrice')?.value;
        const newMaxPrice = document.getElementById('updateMaxPrice')?.value;

        // ✅ USE SECURE RPC FUNCTION WITH AUTHORIZATION
        const { data, error } = await supabase
            .rpc('client_update_booking', {
                p_booking_id: currentBooking.booking_id,
                p_client_id: currentUser.client_id,  // Authorization check
                p_event_date: newEventDate,
                p_event_location: newLocation,
                p_event_start_time: newStartTime,
                p_event_end_time: newEndTime,
                p_booking_min_price: newMinPrice ? parseFloat(newMinPrice) : null,
                p_booking_max_price: newMaxPrice ? parseFloat(newMaxPrice) : null,
                p_booking_special_request: newSpecialRequests
            });

        if (error) {
            throw error;
        }

        // Check result
        if (!data.success) {
            throw new Error(data.error || 'Failed to update booking');
        }

        console.log('✅ Booking updated securely:', data);

        // Send notifications to service providers
        if (changes.length > 0) {
            await notifyServiceProviders(currentBooking.booking_id, changes);
        }

        // Close modal and show success
        const modal = bootstrap.Modal.getInstance(document.getElementById('confirmationModal'));
        modal.hide();
        
        showSuccess('Booking has been successfully updated!');
        displayBookingData();

    } catch (error) {
        console.error('Error updating booking:', error);
        
        // Handle authorization errors
        if (error.message && error.message.includes('AUTHORIZATION FAILED')) {
            showError('You do not have permission to update this booking.');
        } else {
            showError('Failed to update booking: ' + error.message);
        }
        
        // Reset button state
        const saveBtn = document.querySelector('#confirmationModal .btn-primary');
        saveBtn.innerHTML = '<i class="fas fa-check me-2"></i>Yes, Update Booking';
        saveBtn.disabled = false;
    }
}
```

---

## 2. CLIENT GET BOOKINGS

### ❌ BEFORE (INSECURE - Current Code)
```javascript
// client-update-booking.html - Lines 558-586
async function populateBookingSelect() {
    // NO AUTHORIZATION - Gets ALL bookings from database!
    const { data: bookings, error } = await supabase
        .from('booking')
        .select(`
            booking_id,
            booking_status,
            booking_special_requests,
            booking_min_price,
            booking_max_price,
            booking_date,
            booking_location,
            event:event_id (
                event_type,
                event_date,
                event_start_time,
                event_end_time
            )
        `)
        .eq('client_id', currentUser.client_id)  // Client-side filter only!
        .in('booking_status', ['active', 'pending', 'confirmed'])
        .order('booking_date', { ascending: false });
    
    // PROBLEM: If currentUser.client_id is manipulated, can see others' bookings!
}
```

### ✅ AFTER (SECURE - New Code)
```javascript
// client-update-booking.html - Replace populateBookingSelect function
async function populateBookingSelect() {
    const select = document.getElementById('bookingSelect');
    select.innerHTML = '<option value="">Loading bookings...</option>';
    
    try {
        console.log('🔍 Loading bookings for client:', currentUser.client_id);
        
        // ✅ USE SECURE RPC FUNCTION - Authorization at database level
        const { data: bookings, error } = await supabase
            .rpc('get_client_bookings', {
                p_client_id: currentUser.client_id,
                p_status_filter: ['active', 'pending', 'confirmed']
            });

        if (error) {
            console.error('❌ Error loading bookings:', error);
            throw error;
        }

        // Clear loading option
        select.innerHTML = '<option value="">Select a booking...</option>';

        if (bookings && bookings.length > 0) {
            console.log('✅ Loaded', bookings.length, 'bookings securely');
            
            bookings.forEach(booking => {
                const option = document.createElement('option');
                option.value = booking.booking_id;
                option.textContent = `${booking.event_type || 'Event'} - ${booking.event_date || 'Unknown Date'} (${booking.booking_status})`;
                option.dataset.booking = JSON.stringify(booking);
                select.appendChild(option);
            });
        } else {
            console.log('📭 No bookings found');
            select.innerHTML = '<option value="">No bookings found</option>';
            showNoBookingsMessage();
        }
    } catch (error) {
        console.error('Error loading bookings:', error);
        select.innerHTML = '<option value="">Error loading bookings</option>';
        showError('Unable to load your bookings. Please try again.');
    }
}
```

---

## 3. CLIENT CANCEL BOOKING

### ❌ BEFORE (INSECURE - Current Code)
```javascript
// client-cancel-booking.html - Lines 728-771
async function confirmCancellation() {
    const reason = document.getElementById('cancellationReason').value.trim();
    const totalAmount = parseFloat(currentBooking.booking_total_price || 0);
    const deductionAmount = totalAmount * 0.03;
    const refundAmount = totalAmount - deductionAmount;

    // NO AUTHORIZATION CHECK!
    
    // Direct insert to cancellation table
    const { error: cancellationError } = await supabase
        .from('cancellation')
        .insert({
            booking_id: currentBooking.booking_id,
            cancellation_reason: reason,
            cancellation_status: 'confirmed',
            cancellation_pre_fund_price: totalAmount,
            cancellation_deduction_amount: deductionAmount,
            cancellation_refund_amount: refundAmount
        });

    // Direct update to booking table
    const { error: bookingError } = await supabase
        .from('booking')
        .update({ booking_status: 'cancelled' })
        .eq('booking_id', currentBooking.booking_id);
    
    // PROBLEM: Anyone can cancel ANY booking!
}
```

### ✅ AFTER (SECURE - New Code)
```javascript
// client-cancel-booking.html - Replace confirmCancellation function
async function confirmCancellation() {
    try {
        // Show loading state
        const cancelBtn = document.querySelector('#confirmationModal .btn-danger');
        cancelBtn.innerHTML = '<span class="loading"></span> Cancelling...';
        cancelBtn.disabled = true;

        const reason = document.getElementById('cancellationReason').value.trim();

        // ✅ USE SECURE RPC FUNCTION WITH AUTHORIZATION
        const { data, error } = await supabase
            .rpc('client_cancel_booking', {
                p_booking_id: currentBooking.booking_id,
                p_client_id: currentUser.client_id,  // Authorization check
                p_cancellation_reason: reason
            });

        if (error) {
            throw error;
        }

        // Check result
        if (!data.success) {
            throw new Error(data.error || 'Failed to cancel booking');
        }

        console.log('✅ Booking cancelled securely:', data);

        // Send notifications to service providers
        await notifyServiceProvidersOfCancellation(
            currentBooking.booking_id, 
            reason, 
            data.refund_amount
        );

        // Update local booking status
        currentBooking.booking_status = 'cancelled';

        // Close modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('confirmationModal'));
        modal.hide();
        
        // Show success message with refund details
        const successMessage = `Booking has been successfully cancelled!\n\n` +
            `Refund Details:\n` +
            `Total Amount: R${data.total_amount.toFixed(2)}\n` +
            `Deduction (3%): R${data.deduction_amount.toFixed(2)}\n` +
            `Refund Amount: R${data.refund_amount.toFixed(2)}\n\n` +
            `Confirmation notifications have been sent.`;
        
        showSuccess(successMessage);
        
        // Clear form and refresh
        document.getElementById('cancellationReason').value = '';
        document.getElementById('bookingCard').style.display = 'none';
        document.getElementById('bookingSelect').value = '';

        setTimeout(() => populateBookingSelect(), 2000);
        
    } catch (error) {
        console.error('Error cancelling booking:', error);
        
        // Handle authorization errors
        if (error.message && error.message.includes('AUTHORIZATION FAILED')) {
            showError('You do not have permission to cancel this booking.');
        } else if (error.message && error.message.includes('cannot be cancelled')) {
            showError(error.message);
        } else {
            showError('Failed to cancel booking: ' + error.message);
        }
        
        // Reset button state
        const cancelBtn = document.querySelector('#confirmationModal .btn-danger');
        cancelBtn.innerHTML = '<i class="fas fa-times me-2"></i>Yes, Cancel Booking';
        cancelBtn.disabled = false;
    }
}
```

---

## 4. SERVICE PROVIDER UPDATE BOOKING

### ❌ BEFORE (INSECURE - Current Code)
```javascript
// sp-update-booking.html - Lines 861-894
async function confirmUpdate() {
    // NO AUTHORIZATION CHECK!
    
    // Direct update to event table
    const { error: eventError } = await supabase
        .from('event')
        .update({
            event_date: newEventDate,
            event_location: newLocation,
            event_start_time: newStartTime,
            event_end_time: newEndTime
        })
        .eq('event_id', currentBooking.event_id);

    // Direct update to quotation table
    const { error: quotationError } = await supabase
        .from('quotation')
        .update({ quotation_price: newQuotedPrice })
        .eq('booking_id', currentBooking.booking_id)
        .eq('service_provider_id', currentUser.service_provider_id);
    
    // PROBLEM: Can update ANY booking's quotation!
}
```

### ✅ AFTER (SECURE - New Code)
```javascript
// sp-update-booking.html - Replace confirmUpdate function
async function confirmUpdate() {
    try {
        // Show loading state
        const saveBtn = document.querySelector('#confirmationModal .btn-warning');
        saveBtn.innerHTML = '<span class="loading"></span> Saving...';
        saveBtn.disabled = true;

        // Get updated values
        const newEventDate = document.getElementById('updateEventDate').value;
        const newLocation = document.getElementById('updateLocation').value;
        const newStartTime = document.getElementById('updateStartTime').value;
        const newEndTime = document.getElementById('updateEndTime').value;
        const newQuotedPrice = document.getElementById('updateQuotedPrice').value;
        const newSpecialRequests = document.getElementById('updateSpecialRequests').value;

        // ✅ USE SECURE RPC FUNCTION WITH AUTHORIZATION
        const { data, error } = await supabase
            .rpc('service_provider_update_booking', {
                p_booking_id: currentBooking.booking_id,
                p_service_provider_id: currentUser.service_provider_id,  // Authorization check
                p_event_date: newEventDate,
                p_event_location: newLocation,
                p_event_start_time: newStartTime,
                p_event_end_time: newEndTime,
                p_quotation_price: newQuotedPrice ? parseFloat(newQuotedPrice) : null,
                p_booking_special_request: newSpecialRequests
            });

        if (error) {
            throw error;
        }

        // Check result
        if (!data.success) {
            throw new Error(data.error || 'Failed to update booking');
        }

        console.log('✅ Booking updated securely:', data);

        // Send notification to client
        if (changes.length > 0) {
            await notifyClient(currentBooking.booking_id, changes);
        }

        // Close modal and show success
        const modal = bootstrap.Modal.getInstance(document.getElementById('confirmationModal'));
        modal.hide();
        
        showSuccess('Booking has been successfully updated!');
        displayBookingData();

    } catch (error) {
        console.error('Error updating booking:', error);
        
        // Handle authorization errors
        if (error.message && error.message.includes('AUTHORIZATION FAILED')) {
            showError('You are not assigned to this booking.');
        } else {
            showError('Failed to update booking: ' + error.message);
        }
        
        // Reset button state
        const saveBtn = document.querySelector('#confirmationModal .btn-warning');
        saveBtn.innerHTML = '<i class="fas fa-check me-2"></i>Yes, Update Booking';
        saveBtn.disabled = false;
    }
}
```

---

## 5. SERVICE PROVIDER GET BOOKINGS

### ❌ BEFORE (INSECURE - Current Code)
```javascript
// sp-update-booking.html - Lines 629-664
async function populateBookingSelect() {
    // Complex query with joins - potential authorization bypass
    const { data: quotations, error } = await supabase
        .from('quotation')
        .select(`
            quotation_id,
            quotation_price,
            job_cart:job_cart_id (
                event:event_id (...)
            ),
            booking:booking_id (...)
        `)
        .eq('service_provider_id', currentUser.service_provider_id);
    
    // PROBLEM: Complex query, potential for manipulation
}
```

### ✅ AFTER (SECURE - New Code)
```javascript
// sp-update-booking.html - Replace populateBookingSelect function
async function populateBookingSelect() {
    const select = document.getElementById('bookingSelect');
    select.innerHTML = '<option value="">Loading bookings...</option>';
    
    try {
        console.log('🔍 Loading bookings for service provider:', currentUser.service_provider_id);
        
        // ✅ USE SECURE RPC FUNCTION - Authorization at database level
        const { data: bookings, error } = await supabase
            .rpc('get_service_provider_bookings', {
                p_service_provider_id: currentUser.service_provider_id,
                p_status_filter: ['confirmed', 'active', 'in_progress']
            });

        if (error) {
            console.error('❌ Error loading bookings:', error);
            throw error;
        }

        // Clear loading option
        select.innerHTML = '<option value="">Select a booking...</option>';

        if (bookings && bookings.length > 0) {
            console.log('✅ Loaded', bookings.length, 'bookings securely');
            
            bookings.forEach(booking => {
                const option = document.createElement('option');
                option.value = booking.booking_id;
                option.textContent = `${booking.event_type || 'Event'} - ${booking.client_name} - ${booking.event_date} (${booking.booking_status})`;
                option.dataset.booking = JSON.stringify(booking);
                select.appendChild(option);
            });
        } else {
            console.log('📭 No bookings found');
            select.innerHTML = '<option value="">No bookings found</option>';
            showNoBookingsMessage();
        }
    } catch (error) {
        console.error('Error loading bookings:', error);
        select.innerHTML = '<option value="">Error loading bookings</option>';
        showError('Unable to load your bookings. Please try again.');
    }
}
```

---

## 6. SERVICE PROVIDER CANCEL BOOKING

### ❌ BEFORE (INSECURE - Current Code)
```javascript
// sp-cancel-booking.html - Lines 749-776
async function confirmCancellation() {
    // NO AUTHORIZATION CHECK!
    
    const { error: cancellationError } = await supabase
        .from('cancellation')
        .insert({
            booking_id: currentBooking.booking_id,
            cancellation_reason: reason,
            cancellation_status: 'confirmed',
            cancellation_pre_fund_price: quotedPrice,
            cancellation_deduction_amount: 0,
            cancellation_refund_amount: quotedPrice
        });

    const { error: bookingError } = await supabase
        .from('booking')
        .update({ booking_status: 'cancelled' })
        .eq('booking_id', currentBooking.booking_id);
    
    // PROBLEM: Can cancel ANY booking!
}
```

### ✅ AFTER (SECURE - New Code)
```javascript
// sp-cancel-booking.html - Replace confirmCancellation function
async function confirmCancellation() {
    try {
        // Show loading state
        const cancelBtn = document.querySelector('#confirmationModal .btn-danger');
        cancelBtn.innerHTML = '<span class="loading"></span> Cancelling...';
        cancelBtn.disabled = true;

        const reason = document.getElementById('cancellationReason').value.trim();

        // ✅ USE SECURE RPC FUNCTION WITH AUTHORIZATION
        const { data, error } = await supabase
            .rpc('service_provider_cancel_booking', {
                p_booking_id: currentBooking.booking_id,
                p_service_provider_id: currentUser.service_provider_id,  // Authorization check
                p_cancellation_reason: reason
            });

        if (error) {
            throw error;
        }

        // Check result
        if (!data.success) {
            throw new Error(data.error || 'Failed to cancel booking');
        }

        console.log('✅ Booking cancelled securely:', data);

        // Send notification to client
        await notifyClientOfCancellation(currentBooking.booking_id, reason);

        // Update local booking status
        currentBooking.booking_status = 'cancelled';

        // Close modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('confirmationModal'));
        modal.hide();
        
        // Show success message with penalty warning
        const successMessage = `Booking has been successfully cancelled!\n\n` +
            `Important Notes:\n` +
            `• The client has been notified\n` +
            `• Full refund: R${data.refund_to_client.toFixed(2)}\n` +
            `• ${data.penalty_note}\n\n` +
            `Reason: ${reason}`;
        
        showSuccess(successMessage);
        
        // Clear form and refresh
        document.getElementById('cancellationReason').value = '';
        document.getElementById('bookingCard').style.display = 'none';
        document.getElementById('bookingSelect').value = '';

        setTimeout(() => populateBookingSelect(), 2000);
        
    } catch (error) {
        console.error('Error cancelling booking:', error);
        
        // Handle authorization errors
        if (error.message && error.message.includes('AUTHORIZATION FAILED')) {
            showError('You are not assigned to this booking.');
        } else if (error.message && error.message.includes('cannot be cancelled')) {
            showError(error.message);
        } else {
            showError('Failed to cancel booking: ' + error.message);
        }
        
        // Reset button state
        const cancelBtn = document.querySelector('#confirmationModal .btn-danger');
        cancelBtn.innerHTML = '<i class="fas fa-times me-2"></i>Yes, Cancel Booking';
        cancelBtn.disabled = false;
    }
}
```

---

## 7. IMPLEMENTATION CHECKLIST

### Step 1: Run SQL Migration ✅
```bash
# Run the fix_loophole_0_booking_ownership.sql file
psql -U your_user -d your_database -f fix_loophole_0_booking_ownership.sql
```

### Step 2: Update Client Files 🔄
- [ ] Update `client-update-booking.html`:
  - Replace `populateBookingSelect()` function
  - Replace `confirmUpdate()` function
  
- [ ] Update `client-cancel-booking.html`:
  - Replace `populateBookingSelect()` function
  - Replace `confirmCancellation()` function

### Step 3: Update Service Provider Files 🔄
- [ ] Update `sp-update-booking.html`:
  - Replace `populateBookingSelect()` function
  - Replace `confirmUpdate()` function
  
- [ ] Update `sp-cancel-booking.html`:
  - Replace `populateBookingSelect()` function
  - Replace `confirmCancellation()` function

### Step 4: Test Authorization ✅
```javascript
// Test 1: Try to update someone else's booking (should fail)
const { data, error } = await supabase.rpc('client_update_booking', {
    p_booking_id: 'someone-elses-booking-id',
    p_client_id: 'your-client-id',
    p_event_date: '2024-12-31'
});
// Expected: error.message contains "AUTHORIZATION FAILED"

// Test 2: Try to cancel someone else's booking (should fail)
const { data, error } = await supabase.rpc('client_cancel_booking', {
    p_booking_id: 'someone-elses-booking-id',
    p_client_id: 'your-client-id',
    p_cancellation_reason: 'test'
});
// Expected: error.message contains "AUTHORIZATION FAILED"
```

---

## 8. SECURITY BENEFITS

### Before (Vulnerable):
❌ Any user could update ANY booking  
❌ Authorization checked client-side (easily bypassed)  
❌ Direct database access without verification  
❌ No audit trail of who accessed what  

### After (Secure):
✅ Authorization checked at database level  
✅ Cannot be bypassed from client-side  
✅ Clear error messages for unauthorized access  
✅ Returns only user's own bookings  
✅ All updates verified before execution  

---

## 9. NEXT STEPS

After implementing these changes:
1. Test thoroughly with multiple user accounts
2. Verify authorization errors work correctly
3. Check that legitimate updates still work
4. Review server logs for any authorization failures
5. Proceed to fix Loopholes 7-14 (permission control, audit trail, etc.)

---

## IMPORTANT NOTES

⚠️ **CRITICAL:** Do NOT skip the SQL migration step. Without it, the RPC functions will not exist and all updates/cancellations will fail.

⚠️ **BACKWARD COMPATIBILITY:** Old code will break after running the migration. You MUST update all JavaScript files that modify bookings.

✅ **ROLLBACK PLAN:** If needed, you can temporarily allow direct table access by updating Supabase Row Level Security (RLS) policies while you update the code.

---

## QUESTIONS?

If you encounter any issues:
1. Check that SQL migration ran successfully
2. Verify user is logged in with correct user_id
3. Check browser console for error messages
4. Look for "AUTHORIZATION FAILED" in error messages
5. Ensure booking_id exists and user is actually part of that booking

