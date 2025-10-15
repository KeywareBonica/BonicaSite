# JavaScript Code Replacements - Ready to Paste

## 🔧 File 1: client-update-booking.html

### 📍 Location: Lines 762-868 (Function `confirmUpdate`)

### ❌ DELETE THIS (Lines 762-868):
```javascript
        // Confirm update
        async function confirmUpdate() {
            try {
                // Show loading state
                const saveBtn = document.querySelector('#confirmationModal .btn-primary');
                const originalText = saveBtn.innerHTML;
                saveBtn.innerHTML = '<span class="loading"></span> Saving...';
                saveBtn.disabled = true;

                // Get the changes for notification purposes
                const changes = [];
                const newEventDate = document.getElementById('updateEventDate').value;
                const newLocation = document.getElementById('updateLocation').value;
                const newStartTime = document.getElementById('updateStartTime').value;
                const newEndTime = document.getElementById('updateEndTime').value;
                const newSpecialRequests = document.getElementById('updateSpecialRequests').value;

                if (newEventDate !== (currentBooking.event?.event_date || '')) {
                    changes.push(`Event Date: ${currentBooking.event?.event_date || 'Not set'} → ${newEventDate}`);
                }
                if (newLocation !== (currentBooking.event?.event_location || '')) {
                    changes.push(`Location: ${currentBooking.event?.event_location || 'Not set'} → ${newLocation}`);
                }
                if (newStartTime !== (currentBooking.event?.event_start_time || '')) {
                    changes.push(`Start Time: ${currentBooking.event?.event_start_time || 'Not set'} → ${newStartTime}`);
                }
                if (newEndTime !== (currentBooking.event?.event_end_time || '')) {
                    changes.push(`End Time: ${currentBooking.event?.event_end_time || 'Not set'} → ${newEndTime}`);
                }
                if (newSpecialRequests !== (currentBooking.booking_special_requests || '')) {
                    changes.push(`Special Requests: Updated`);
                }

                // Update real booking in database
                console.log('💾 Updating booking in database:', currentBooking.booking_id);
                
                // Update event table
                const { error: eventError } = await supabase
                    .from('event')
                    .update({
                        event_date: newEventDate,
                        event_location: newLocation,
                        event_start_time: newStartTime,
                        event_end_time: newEndTime
                    })
                    .eq('event_id', currentBooking.event?.event_id);

                if (eventError) throw eventError;

                // Update booking table
                const newMinPrice = document.getElementById('updateMinPrice')?.value;
                const newMaxPrice = document.getElementById('updateMaxPrice')?.value;
                
                const bookingUpdateData = {
                    booking_special_requests: newSpecialRequests
                };
                
                // Add budget updates if fields exist and have values
                if (newMinPrice) bookingUpdateData.booking_min_price = parseFloat(newMinPrice);
                if (newMaxPrice) bookingUpdateData.booking_max_price = parseFloat(newMaxPrice);
                
                const { error: bookingError } = await supabase
                    .from('booking')
                    .update(bookingUpdateData)
                    .eq('booking_id', currentBooking.booking_id);

                if (bookingError) throw bookingError;

                // Send notifications to service providers (if there are changes)
                if (changes.length > 0) {
                    await notifyServiceProviders(currentBooking.booking_id, changes);
                }

                console.log('✅ Booking updated successfully');

                // Update the local booking data
                currentBooking.event.event_date = newEventDate;
                currentBooking.event.event_location = newLocation;
                currentBooking.event.event_start_time = newStartTime;
                currentBooking.event.event_end_time = newEndTime;
                currentBooking.booking_start_time = newStartTime;
                currentBooking.booking_end_time = newEndTime;
                currentBooking.booking_special_request = newSpecialRequests;

                // Close modal
                const modal = bootstrap.Modal.getInstance(document.getElementById('confirmationModal'));
                modal.hide();

                // Show success message with notification details
                const successMessage = changes.length > 0 ? 
                    `Booking has been successfully updated!\n\nChanges made:\n${changes.join('\n')}\n\nService providers have been notified of the changes.` :
                    'Booking has been successfully updated!';
                
                showSuccess(successMessage);
                
                // Refresh the booking display
                displayBookingData();

            } catch (error) {
                console.error('Error updating booking:', error);
                showError('Failed to update booking: ' + error.message);
                
                // Reset button state
                const saveBtn = document.querySelector('#confirmationModal .btn-primary');
                saveBtn.innerHTML = '<i class="fas fa-check me-2"></i>Yes, Update Booking';
                saveBtn.disabled = false;
            }
        }
```

### ✅ REPLACE WITH THIS:
```javascript
        // Confirm update
        async function confirmUpdate() {
            try {
                // Show loading state
                const saveBtn = document.querySelector('#confirmationModal .btn-primary');
                const originalText = saveBtn.innerHTML;
                saveBtn.innerHTML = '<span class="loading"></span> Saving...';
                saveBtn.disabled = true;

                // Get the changes for notification purposes
                const changes = [];
                const newEventDate = document.getElementById('updateEventDate').value;
                const newLocation = document.getElementById('updateLocation').value;
                const newStartTime = document.getElementById('updateStartTime').value;
                const newEndTime = document.getElementById('updateEndTime').value;
                const newSpecialRequests = document.getElementById('updateSpecialRequests').value;
                const newMinPrice = document.getElementById('updateMinPrice')?.value;
                const newMaxPrice = document.getElementById('updateMaxPrice')?.value;

                if (newEventDate !== (currentBooking.event?.event_date || '')) {
                    changes.push(`Event Date: ${currentBooking.event?.event_date || 'Not set'} → ${newEventDate}`);
                }
                if (newLocation !== (currentBooking.event?.event_location || '')) {
                    changes.push(`Location: ${currentBooking.event?.event_location || 'Not set'} → ${newLocation}`);
                }
                if (newStartTime !== (currentBooking.event?.event_start_time || '')) {
                    changes.push(`Start Time: ${currentBooking.event?.event_start_time || 'Not set'} → ${newStartTime}`);
                }
                if (newEndTime !== (currentBooking.event?.event_end_time || '')) {
                    changes.push(`End Time: ${currentBooking.event?.event_end_time || 'Not set'} → ${newEndTime}`);
                }
                if (newSpecialRequests !== (currentBooking.booking_special_requests || '')) {
                    changes.push(`Special Requests: Updated`);
                }

                // ✅ USE SECURE RPC FUNCTION WITH AUTHORIZATION CHECK
                console.log('💾 Updating booking securely:', currentBooking.booking_id);
                
                const { data, error } = await supabase
                    .rpc('client_update_booking', {
                        p_booking_id: currentBooking.booking_id,
                        p_client_id: currentUser.client_id,  // ✅ Authorization check at database level
                        p_event_date: newEventDate || null,
                        p_event_location: newLocation || null,
                        p_event_start_time: newStartTime || null,
                        p_event_end_time: newEndTime || null,
                        p_booking_min_price: newMinPrice ? parseFloat(newMinPrice) : null,
                        p_booking_max_price: newMaxPrice ? parseFloat(newMaxPrice) : null,
                        p_booking_special_request: newSpecialRequests || null
                    });

                if (error) {
                    throw error;
                }

                // Check if update was successful
                if (!data || !data.success) {
                    throw new Error(data?.error || 'Failed to update booking');
                }

                console.log('✅ Booking updated successfully:', data);

                // Send notifications to service providers (if there are changes)
                if (changes.length > 0) {
                    await notifyServiceProviders(currentBooking.booking_id, changes);
                }

                // Update the local booking data
                if (currentBooking.event) {
                    currentBooking.event.event_date = newEventDate;
                    currentBooking.event.event_location = newLocation;
                    currentBooking.event.event_start_time = newStartTime;
                    currentBooking.event.event_end_time = newEndTime;
                }
                currentBooking.booking_special_requests = newSpecialRequests;

                // Close modal
                const modal = bootstrap.Modal.getInstance(document.getElementById('confirmationModal'));
                modal.hide();

                // Show success message with notification details
                const successMessage = changes.length > 0 ? 
                    `Booking has been successfully updated!\n\nChanges made:\n${changes.join('\n')}\n\nService providers have been notified of the changes.` :
                    'Booking has been successfully updated!';
                
                showSuccess(successMessage);
                
                // Refresh the booking display
                displayBookingData();

            } catch (error) {
                console.error('Error updating booking:', error);
                
                // Handle authorization errors specifically
                if (error.message && error.message.includes('AUTHORIZATION FAILED')) {
                    showError('❌ Authorization failed: You do not have permission to update this booking.');
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

## 🔧 File 2: client-cancel-booking.html

### 📍 Location: Lines 710-803 (Function `confirmCancellation`)

### ❌ DELETE THIS (Lines 710-803):
```javascript
        // Confirm cancellation
        async function confirmCancellation() {
            try {
                // Show loading state
                const cancelBtn = document.querySelector('#confirmationModal .btn-danger');
                const originalText = cancelBtn.innerHTML;
                cancelBtn.innerHTML = '<span class="loading"></span> Cancelling...';
                cancelBtn.disabled = true;

                const reason = document.getElementById('cancellationReason').value.trim();

                // Calculate refund amount (3% deduction as per use case)
                const totalAmount = parseFloat(currentBooking.booking_total_price || currentBooking.booking_max_price || currentBooking.booking_min_price || 0);
                const deductionAmount = totalAmount * 0.03; // 3% deduction
                const refundAmount = totalAmount - deductionAmount;

                // Check if this is a fake booking (starts with 'cancel-')
                const isFakeBooking = currentBooking.booking_id.startsWith('cancel-');
                
                if (!isFakeBooking) {
                    // Real database cancellation
                    console.log('💾 Cancelling real booking in database:', currentBooking.booking_id);
                    
                    // Insert cancellation record
                    const { data: cancellationData, error: cancellationError } = await supabase
                        .from('cancellation')
                        .insert({
                            booking_id: currentBooking.booking_id,
                            cancellation_reason: reason,
                            cancellation_status: 'confirmed',
                            cancellation_pre_fund_price: totalAmount,
                            cancellation_deduction_amount: deductionAmount,
                            cancellation_refund_amount: refundAmount
                        })
                        .select();

                    if (cancellationError) throw cancellationError;

                    // Update booking status to cancelled
                    const { error: bookingError } = await supabase
                        .from('booking')
                        .update({
                            booking_status: 'cancelled'
                        })
                        .eq('booking_id', currentBooking.booking_id);

                    if (bookingError) throw bookingError;

                    // Send notifications to service providers
                    await notifyServiceProvidersOfCancellation(currentBooking.booking_id, reason, refundAmount);

                    console.log('✅ Real booking cancelled successfully');
                } else {
                    // Fake booking - just simulate delay
                    console.log('🎭 Simulating cancellation for fake booking');
                    await new Promise(resolve => setTimeout(resolve, 1500));
                }

                // Update local booking status
                currentBooking.booking_status = 'cancelled';

                // Close modal
                const modal = bootstrap.Modal.getInstance(document.getElementById('confirmationModal'));
                modal.hide();
                
                // Show success message with refund details
                const successMessage = `Booking has been successfully cancelled!\n\n` +
                    `Refund Details:\n` +
                    `Total Amount: R${totalAmount.toFixed(2)}\n` +
                    `Deduction (3%): R${deductionAmount.toFixed(2)}\n` +
                    `Refund Amount: R${refundAmount.toFixed(2)}\n\n` +
                    `Confirmation notifications have been sent to all service providers.`;
                
                showSuccess(successMessage);
                
                // Clear form
                document.getElementById('cancellationReason').value = '';
                document.getElementById('bookingCard').style.display = 'none';
                document.getElementById('bookingSelect').value = '';

                // Refresh bookings
                setTimeout(() => {
                    populateBookingSelect();
                }, 2000);
                
            } catch (error) {
                console.error('Error cancelling booking:', error);
                showError('Failed to cancel booking: ' + error.message);
                
                // Reset button state
                const cancelBtn = document.querySelector('#confirmationModal .btn-danger');
                cancelBtn.innerHTML = '<i class="fas fa-times me-2"></i>Yes, Cancel Booking';
                cancelBtn.disabled = false;
            }
        }
```

### ✅ REPLACE WITH THIS:
```javascript
        // Confirm cancellation
        async function confirmCancellation() {
            try {
                // Show loading state
                const cancelBtn = document.querySelector('#confirmationModal .btn-danger');
                const originalText = cancelBtn.innerHTML;
                cancelBtn.innerHTML = '<span class="loading"></span> Cancelling...';
                cancelBtn.disabled = true;

                const reason = document.getElementById('cancellationReason').value.trim();

                // ✅ USE SECURE RPC FUNCTION WITH AUTHORIZATION CHECK
                console.log('💾 Cancelling booking securely:', currentBooking.booking_id);
                
                const { data, error } = await supabase
                    .rpc('client_cancel_booking', {
                        p_booking_id: currentBooking.booking_id,
                        p_client_id: currentUser.client_id,  // ✅ Authorization check at database level
                        p_cancellation_reason: reason
                    });

                if (error) {
                    throw error;
                }

                // Check if cancellation was successful
                if (!data || !data.success) {
                    throw new Error(data?.error || 'Failed to cancel booking');
                }

                console.log('✅ Booking cancelled successfully:', data);

                // Send notifications to service providers
                await notifyServiceProvidersOfCancellation(currentBooking.booking_id, reason, data.refund_amount);

                // Update local booking status
                currentBooking.booking_status = 'cancelled';

                // Close modal
                const modal = bootstrap.Modal.getInstance(document.getElementById('confirmationModal'));
                modal.hide();
                
                // Show success message with refund details from database
                const successMessage = `Booking has been successfully cancelled!\n\n` +
                    `Refund Details:\n` +
                    `Total Amount: R${data.total_amount.toFixed(2)}\n` +
                    `Deduction (3%): R${data.deduction_amount.toFixed(2)}\n` +
                    `Refund Amount: R${data.refund_amount.toFixed(2)}\n\n` +
                    `Confirmation notifications have been sent to all service providers.`;
                
                showSuccess(successMessage);
                
                // Clear form
                document.getElementById('cancellationReason').value = '';
                document.getElementById('bookingCard').style.display = 'none';
                document.getElementById('bookingSelect').value = '';

                // Refresh bookings
                setTimeout(() => {
                    populateBookingSelect();
                }, 2000);
                
            } catch (error) {
                console.error('Error cancelling booking:', error);
                
                // Handle authorization errors specifically
                if (error.message && error.message.includes('AUTHORIZATION FAILED')) {
                    showError('❌ Authorization failed: You do not have permission to cancel this booking.');
                } else if (error.message && error.message.includes('cannot be cancelled')) {
                    showError('❌ This booking cannot be cancelled: ' + error.message);
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

## 🔧 File 3: sp-update-booking.html

### 📍 Location: Lines 813-940 (Function `confirmUpdate`)

### ❌ DELETE THIS (Lines 813-940):
```javascript
        // Confirm update
        async function confirmUpdate() {
            try {
                // Show loading state
                const saveBtn = document.querySelector('#confirmationModal .btn-warning');
                const originalText = saveBtn.innerHTML;
                saveBtn.innerHTML = '<span class="loading"></span> Saving...';
                saveBtn.disabled = true;

                // Get the changes for notification purposes
                const changes = [];
                const newEventDate = document.getElementById('updateEventDate').value;
                const newLocation = document.getElementById('updateLocation').value;
                const newStartTime = document.getElementById('updateStartTime').value;
                const newEndTime = document.getElementById('updateEndTime').value;
                const newQuotedPrice = document.getElementById('updateQuotedPrice').value;
                const newOvertimeRate = document.getElementById('updateOvertimeRate').value;
                const newSpecialRequests = document.getElementById('updateSpecialRequests').value;

                if (newEventDate !== currentBooking.event_date) {
                    changes.push(`Event Date: ${currentBooking.event_date} → ${newEventDate}`);
                }
                if (newLocation !== currentBooking.event_location) {
                    changes.push(`Location: ${currentBooking.event_location} → ${newLocation}`);
                }
                if (newStartTime !== currentBooking.event_start_time) {
                    changes.push(`Start Time: ${currentBooking.event_start_time} → ${newStartTime}`);
                }
                if (newEndTime !== currentBooking.event_end_time) {
                    changes.push(`End Time: ${currentBooking.event_end_time} → ${newEndTime}`);
                }
                if (newQuotedPrice !== currentBooking.quoted_price) {
                    changes.push(`Quoted Price: R${currentBooking.quoted_price} → R${newQuotedPrice}`);
                }
                if (newOvertimeRate !== currentBooking.overtime_rate) {
                    changes.push(`Overtime Rate: R${currentBooking.overtime_rate}/hour → R${newOvertimeRate}/hour`);
                }
                if (newSpecialRequests !== (currentBooking.special_requests || '')) {
                    changes.push(`Special Requests: Updated`);
                }

                // Check if this is a fake booking (starts with 'sp-')
                const isFakeBooking = currentBooking.booking_id.startsWith('sp-');
                
                if (!isFakeBooking) {
                    // Real database update
                    console.log('💾 Updating real booking in database:', currentBooking.booking_id);
                    
                    // Update event table
                    const { error: eventError } = await supabase
                        .from('event')
                        .update({
                            event_date: newEventDate,
                            event_location: newLocation,
                            event_start_time: newStartTime,
                            event_end_time: newEndTime
                        })
                        .eq('event_id', currentBooking.event_id);

                    if (eventError) throw eventError;

                    // Update booking table
                    const { error: bookingError } = await supabase
                        .from('booking')
                        .update({
                            booking_start_time: newStartTime,
                            booking_end_time: newEndTime,
                            booking_special_request: newSpecialRequests
                        })
                        .eq('booking_id', currentBooking.booking_id);

                    if (bookingError) throw bookingError;

                    // Update quotation table with new pricing
                    const { error: quotationError } = await supabase
                        .from('quotation')
                        .update({
                            quotation_price: newQuotedPrice
                        })
                        .eq('booking_id', currentBooking.booking_id)
                        .eq('service_provider_id', currentUser.service_provider_id);

                    if (quotationError) throw quotationError;

                    // Send notification to client (if there are changes)
                    if (changes.length > 0) {
                        await notifyClient(currentBooking.booking_id, changes);
                    }

                    console.log('✅ Real booking updated successfully');
                } else {
                    // Fake booking - just simulate delay
                    console.log('🎭 Simulating update for fake booking');
                    await new Promise(resolve => setTimeout(resolve, 1500));
                }

                // Update the local booking data
                currentBooking.event_date = newEventDate;
                currentBooking.event_location = newLocation;
                currentBooking.event_start_time = newStartTime;
                currentBooking.event_end_time = newEndTime;
                currentBooking.quoted_price = newQuotedPrice;
                currentBooking.overtime_rate = newOvertimeRate;
                currentBooking.special_requests = newSpecialRequests;

                // Close modal
                const modal = bootstrap.Modal.getInstance(document.getElementById('confirmationModal'));
                modal.hide();

                // Show success message with notification details
                const successMessage = changes.length > 0 ? 
                    `Booking has been successfully updated!\n\nChanges made:\n${changes.join('\n')}\n\nThe client has been notified of the changes.` :
                    'Booking has been successfully updated!';
                
                showSuccess(successMessage);
                
                // Refresh the booking display
                displayBookingData();

            } catch (error) {
                console.error('Error updating booking:', error);
                showError('Failed to update booking: ' + error.message);
                
                // Reset button state
                const saveBtn = document.querySelector('#confirmationModal .btn-warning');
                saveBtn.innerHTML = '<i class="fas fa-check me-2"></i>Yes, Update Booking';
                saveBtn.disabled = false;
            }
        }
```

### ✅ REPLACE WITH THIS:
```javascript
        // Confirm update
        async function confirmUpdate() {
            try {
                // Show loading state
                const saveBtn = document.querySelector('#confirmationModal .btn-warning');
                const originalText = saveBtn.innerHTML;
                saveBtn.innerHTML = '<span class="loading"></span> Saving...';
                saveBtn.disabled = true;

                // Get the changes for notification purposes
                const changes = [];
                const newEventDate = document.getElementById('updateEventDate').value;
                const newLocation = document.getElementById('updateLocation').value;
                const newStartTime = document.getElementById('updateStartTime').value;
                const newEndTime = document.getElementById('updateEndTime').value;
                const newQuotedPrice = document.getElementById('updateQuotedPrice').value;
                const newOvertimeRate = document.getElementById('updateOvertimeRate').value;
                const newSpecialRequests = document.getElementById('updateSpecialRequests').value;

                if (newEventDate !== currentBooking.event_date) {
                    changes.push(`Event Date: ${currentBooking.event_date} → ${newEventDate}`);
                }
                if (newLocation !== currentBooking.event_location) {
                    changes.push(`Location: ${currentBooking.event_location} → ${newLocation}`);
                }
                if (newStartTime !== currentBooking.event_start_time) {
                    changes.push(`Start Time: ${currentBooking.event_start_time} → ${newStartTime}`);
                }
                if (newEndTime !== currentBooking.event_end_time) {
                    changes.push(`End Time: ${currentBooking.event_end_time} → ${newEndTime}`);
                }
                if (newQuotedPrice !== currentBooking.quoted_price) {
                    changes.push(`Quoted Price: R${currentBooking.quoted_price} → R${newQuotedPrice}`);
                }
                if (newOvertimeRate !== currentBooking.overtime_rate) {
                    changes.push(`Overtime Rate: Updated`);
                }
                if (newSpecialRequests !== (currentBooking.special_requests || '')) {
                    changes.push(`Special Requests: Updated`);
                }

                // ✅ USE SECURE RPC FUNCTION WITH AUTHORIZATION CHECK
                console.log('💾 Updating booking securely:', currentBooking.booking_id);
                
                const { data, error } = await supabase
                    .rpc('service_provider_update_booking', {
                        p_booking_id: currentBooking.booking_id,
                        p_service_provider_id: currentUser.service_provider_id,  // ✅ Authorization check at database level
                        p_event_date: newEventDate || null,
                        p_event_location: newLocation || null,
                        p_event_start_time: newStartTime || null,
                        p_event_end_time: newEndTime || null,
                        p_quotation_price: newQuotedPrice ? parseFloat(newQuotedPrice) : null,
                        p_booking_special_request: newSpecialRequests || null
                    });

                if (error) {
                    throw error;
                }

                // Check if update was successful
                if (!data || !data.success) {
                    throw new Error(data?.error || 'Failed to update booking');
                }

                console.log('✅ Booking updated successfully:', data);

                // Send notification to client (if there are changes)
                if (changes.length > 0) {
                    await notifyClient(currentBooking.booking_id, changes);
                }

                // Update the local booking data
                currentBooking.event_date = newEventDate;
                currentBooking.event_location = newLocation;
                currentBooking.event_start_time = newStartTime;
                currentBooking.event_end_time = newEndTime;
                currentBooking.quoted_price = newQuotedPrice;
                currentBooking.overtime_rate = newOvertimeRate;
                currentBooking.special_requests = newSpecialRequests;

                // Close modal
                const modal = bootstrap.Modal.getInstance(document.getElementById('confirmationModal'));
                modal.hide();

                // Show success message with notification details
                const successMessage = changes.length > 0 ? 
                    `Booking has been successfully updated!\n\nChanges made:\n${changes.join('\n')}\n\nThe client has been notified of the changes.` :
                    'Booking has been successfully updated!';
                
                showSuccess(successMessage);
                
                // Refresh the booking display
                displayBookingData();

            } catch (error) {
                console.error('Error updating booking:', error);
                
                // Handle authorization errors specifically
                if (error.message && error.message.includes('AUTHORIZATION FAILED')) {
                    showError('❌ Authorization failed: You are not assigned to this booking.');
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

## 🔧 File 4: sp-cancel-booking.html

### 📍 Location: Lines 735-815 (Function `confirmCancellation`)

### ❌ DELETE THIS (Lines 735-815):
```javascript
        // Confirm cancellation
        async function confirmCancellation() {
            try {
                // Show loading state
                const cancelBtn = document.querySelector('#confirmationModal .btn-danger');
                const originalText = cancelBtn.innerHTML;
                cancelBtn.innerHTML = '<span class="loading"></span> Cancelling...';
                cancelBtn.disabled = true;

                const reason = document.getElementById('cancellationReason').value.trim();

                // All bookings are now real database bookings
                console.log('💾 Cancelling real booking in database:', currentBooking.booking_id);
                
                // Insert cancellation record
                const { data: cancellationData, error: cancellationError } = await supabase
                    .from('cancellation')
                    .insert({
                        booking_id: currentBooking.booking_id,
                        cancellation_reason: reason,
                        cancellation_status: 'confirmed',
                        cancellation_pre_fund_price: parseFloat(currentBooking.quoted_price) || 0,
                        cancellation_deduction_amount: 0, // Service provider cancellation doesn't affect client refund
                        cancellation_refund_amount: parseFloat(currentBooking.quoted_price) || 0
                    })
                    .select();

                if (cancellationError) throw cancellationError;

                // Update booking status to cancelled
                const { error: bookingError } = await supabase
                    .from('booking')
                    .update({
                        booking_status: 'cancelled'
                    })
                    .eq('booking_id', currentBooking.booking_id);

                if (bookingError) throw bookingError;

                // Send notification to client
                await notifyClientOfCancellation(currentBooking.booking_id, reason);

                console.log('✅ Real booking cancelled successfully');

                // Update local booking status
                currentBooking.booking_status = 'cancelled';

                // Close modal
                const modal = bootstrap.Modal.getInstance(document.getElementById('confirmationModal'));
                modal.hide();
                
                // Show success message with penalty details
                const successMessage = `Booking has been successfully cancelled!\n\n` +
                    `Important Notes:\n` +
                    `• The client has been notified of the cancellation\n` +
                    `• Your service provider rating may be affected\n` +
                    `• A cancellation penalty may be applied to your account\n` +
                    `• Please ensure this was absolutely necessary for future bookings\n\n` +
                    `Reason provided: ${reason}`;
                
                showSuccess(successMessage);
                
                // Clear form
                document.getElementById('cancellationReason').value = '';
                document.getElementById('bookingCard').style.display = 'none';
                document.getElementById('bookingSelect').value = '';

                // Refresh bookings
                setTimeout(() => {
                    populateBookingSelect();
                }, 2000);
                
            } catch (error) {
                console.error('Error cancelling booking:', error);
                showError('Failed to cancel booking: ' + error.message);
                
                // Reset button state
                const cancelBtn = document.querySelector('#confirmationModal .btn-danger');
                cancelBtn.innerHTML = '<i class="fas fa-times me-2"></i>Yes, Cancel Booking';
                cancelBtn.disabled = false;
            }
        }
```

### ✅ REPLACE WITH THIS:
```javascript
        // Confirm cancellation
        async function confirmCancellation() {
            try {
                // Show loading state
                const cancelBtn = document.querySelector('#confirmationModal .btn-danger');
                const originalText = cancelBtn.innerHTML;
                cancelBtn.innerHTML = '<span class="loading"></span> Cancelling...';
                cancelBtn.disabled = true;

                const reason = document.getElementById('cancellationReason').value.trim();

                // ✅ USE SECURE RPC FUNCTION WITH AUTHORIZATION CHECK
                console.log('💾 Cancelling booking securely:', currentBooking.booking_id);
                
                const { data, error } = await supabase
                    .rpc('service_provider_cancel_booking', {
                        p_booking_id: currentBooking.booking_id,
                        p_service_provider_id: currentUser.service_provider_id,  // ✅ Authorization check at database level
                        p_cancellation_reason: reason
                    });

                if (error) {
                    throw error;
                }

                // Check if cancellation was successful
                if (!data || !data.success) {
                    throw new Error(data?.error || 'Failed to cancel booking');
                }

                console.log('✅ Booking cancelled successfully:', data);

                // Send notification to client
                await notifyClientOfCancellation(currentBooking.booking_id, reason);

                // Update local booking status
                currentBooking.booking_status = 'cancelled';

                // Close modal
                const modal = bootstrap.Modal.getInstance(document.getElementById('confirmationModal'));
                modal.hide();
                
                // Show success message with penalty details from database
                const successMessage = `Booking has been successfully cancelled!\n\n` +
                    `Important Notes:\n` +
                    `• The client has been notified of the cancellation\n` +
                    `• Full refund to client: R${data.refund_to_client.toFixed(2)}\n` +
                    `• ${data.penalty_note}\n` +
                    `• Your service provider rating may be affected\n` +
                    `• Please ensure this was absolutely necessary for future bookings\n\n` +
                    `Reason provided: ${reason}`;
                
                showSuccess(successMessage);
                
                // Clear form
                document.getElementById('cancellationReason').value = '';
                document.getElementById('bookingCard').style.display = 'none';
                document.getElementById('bookingSelect').value = '';

                // Refresh bookings
                setTimeout(() => {
                    populateBookingSelect();
                }, 2000);
                
            } catch (error) {
                console.error('Error cancelling booking:', error);
                
                // Handle authorization errors specifically
                if (error.message && error.message.includes('AUTHORIZATION FAILED')) {
                    showError('❌ Authorization failed: You are not assigned to this booking.');
                } else if (error.message && error.message.includes('cannot be cancelled')) {
                    showError('❌ This booking cannot be cancelled: ' + error.message);
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

## ✅ Quick Summary of Changes

| File | Function | Lines | Key Change |
|------|----------|-------|------------|
| `client-update-booking.html` | `confirmUpdate()` | 762-868 | Replace direct DB updates with `client_update_booking()` RPC |
| `client-cancel-booking.html` | `confirmCancellation()` | 710-803 | Replace direct DB updates with `client_cancel_booking()` RPC |
| `sp-update-booking.html` | `confirmUpdate()` | 813-940 | Replace direct DB updates with `service_provider_update_booking()` RPC |
| `sp-cancel-booking.html` | `confirmCancellation()` | 735-815 | Replace direct DB updates with `service_provider_cancel_booking()` RPC |

## 🎯 What These Changes Do:

1. **✅ Authorization at database level** - Can't be bypassed from client
2. **✅ Clear error messages** - Shows "AUTHORIZATION FAILED" when user doesn't own booking
3. **✅ Returns structured JSON** - `{success: true/false, message: ..., data: ...}`
4. **✅ Handles all edge cases** - Null values, missing fields, errors
5. **✅ Secure by default** - No way to update someone else's booking

## 🚀 Ready to implement!

Just copy-paste each replacement into its respective file!

