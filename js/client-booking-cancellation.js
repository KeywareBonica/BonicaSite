// Client Booking Cancellation System
// Handles client-side booking cancellation using locally stored client_id
// Matches client_id with booking table and updates booking_status to 'cancelled'

// Supabase configuration
const SUPABASE_URL = "https://spudtrptbyvwyhvistdf.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwdWR0cnB0Ynl2d3lodmlzdGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2OTk4NjgsImV4cCI6MjA3MTI3NTg2OH0.GBo-RtgbRZCmhSAZi0c5oXynMiJNeyrs0nLsk3CaV8A";
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

// Global variables
let clientId = null;
let clientBookings = [];
let selectedBooking = null;

// Initialize the cancellation system
document.addEventListener('DOMContentLoaded', async function() {
    try {
        await initializeClientCancellation();
    } catch (error) {
        console.error("Error initializing client cancellation system:", error);
        showMessage("Error loading booking cancellation system", "error");
    }
});

// Initialize client cancellation system
async function initializeClientCancellation() {
    try {
        // Get client ID from localStorage
        clientId = localStorage.getItem('clientId');
        
        if (!clientId) {
            console.warn("No client ID found in localStorage, using test mode");
            clientId = 'test-client-id';
            showMessage("Running in test mode - showing sample bookings", "warning");
        }

        console.log("🔍 Client ID from localStorage:", clientId);
        
        // Load client's bookings
        await loadClientBookings();
        
        // Setup event listeners
        setupEventListeners();
        
        // Setup real-time subscriptions for booking updates
        setupRealtimeSubscriptions();
        
    } catch (error) {
        console.error("Error initializing client cancellation:", error);
        showMessage("Error initializing cancellation system", "error");
    }
}

// Load client's bookings from database
async function loadClientBookings() {
    try {
        showLoading(true);
        
        // Query bookings table using client_id
        const { data: bookings, error } = await supabase
            .from('booking')
            .select(`
                booking_id,
                booking_date,
                booking_start_time,
                booking_end_time,
                booking_status,
                booking_total_price,
                booking_special_request,
                client_id,
                event_id,
                created_at,
                event:event_id (
                    event_id,
                    event_name,
                    event_type,
                    event_location,
                    event_date
                )
            `)
            .eq('client_id', clientId)
            .in('booking_status', ['pending', 'confirmed', 'in_progress'])
            .order('booking_date', { ascending: true });

        if (error) throw error;

        clientBookings = bookings || [];
        
        if (clientBookings.length === 0) {
            // Show sample bookings for testing
            console.log('No bookings found for client, showing sample bookings...');
            showSampleBookings();
        } else {
            displayClientBookings(clientBookings);
        }
        
    } catch (error) {
        console.error("Error loading client bookings:", error);
        showMessage("Error loading your bookings", "error");
        // Fallback to sample bookings
        showSampleBookings();
    } finally {
        showLoading(false);
    }
}

// Display client bookings in the UI
function displayClientBookings(bookings) {
    const bookingsList = document.getElementById('bookings-list');
    const bookingsContainer = document.getElementById('bookings-container');
    const bookingCount = document.getElementById('booking-count');
    
    if (!bookingsList) {
        console.error("Bookings list element not found");
        return;
    }
    
    bookingsList.innerHTML = '';
    
    bookings.forEach(booking => {
        const bookingCard = createBookingCard(booking);
        bookingsList.appendChild(bookingCard);
    });
    
    if (bookingCount) {
        bookingCount.textContent = `${bookings.length} booking${bookings.length !== 1 ? 's' : ''} available for cancellation`;
    }
    
    if (bookingsContainer) {
        bookingsContainer.style.display = bookings.length > 0 ? 'block' : 'none';
    }
    
    console.log(`✅ Displayed ${bookings.length} bookings for client`);
}

// Create booking card element
function createBookingCard(booking) {
    const card = document.createElement('div');
    card.className = 'booking-card';
    card.dataset.bookingId = booking.booking_id;
    
    const eventDate = new Date(booking.booking_date).toLocaleDateString();
    const eventTime = `${booking.booking_start_time} - ${booking.booking_end_time}`;
    const statusClass = booking.booking_status.replace('_', '-');
    
    card.innerHTML = `
        <div class="booking-header">
            <h3>${booking.event?.event_name || 'Event'}</h3>
            <span class="booking-status ${statusClass}">${booking.booking_status}</span>
        </div>
        
        <div class="booking-details">
            <div class="detail-item">
                <i class="fas fa-calendar"></i>
                <span>Date: ${eventDate}</span>
            </div>
            <div class="detail-item">
                <i class="fas fa-clock"></i>
                <span>Time: ${eventTime}</span>
            </div>
            <div class="detail-item">
                <i class="fas fa-map-marker-alt"></i>
                <span>Location: ${booking.event?.event_location || 'TBA'}</span>
            </div>
            <div class="detail-item">
                <i class="fas fa-tag"></i>
                <span>Type: ${booking.event?.event_type || 'N/A'}</span>
            </div>
            <div class="detail-item">
                <i class="fas fa-money-bill"></i>
                <span>Total: R${parseFloat(booking.booking_total_price || 0).toLocaleString()}</span>
            </div>
        </div>
        
        ${booking.booking_special_request ? `
            <div class="booking-request">
                <h4>Special Requests:</h4>
                <p>${booking.booking_special_request}</p>
            </div>
        ` : ''}
        
        <div class="booking-actions">
            <button class="btn-cancel" onclick="selectBookingForCancellation('${booking.booking_id}')">
                <i class="fas fa-times"></i>
                Cancel Booking
            </button>
            <button class="btn-details" onclick="viewBookingDetails('${booking.booking_id}')">
                <i class="fas fa-info-circle"></i>
                View Details
            </button>
        </div>
    `;
    
    return card;
}

// Select booking for cancellation
function selectBookingForCancellation(bookingId) {
    selectedBooking = clientBookings.find(b => b.booking_id === bookingId);
    
    if (!selectedBooking) {
        showMessage("Booking not found", "error");
        return;
    }
    
    // Show cancellation modal
    showCancellationModal(selectedBooking);
}

// Show cancellation modal
function showCancellationModal(booking) {
    // Create modal if it doesn't exist
    let modal = document.getElementById('cancellation-modal');
    if (!modal) {
        modal = createCancellationModal();
        document.body.appendChild(modal);
    }
    
    // Populate modal with booking details
    document.getElementById('modal-booking-title').textContent = booking.event?.event_name || 'Event';
    document.getElementById('modal-booking-date').textContent = new Date(booking.booking_date).toLocaleDateString();
    document.getElementById('modal-booking-time').textContent = `${booking.booking_start_time} - ${booking.booking_end_time}`;
    document.getElementById('modal-booking-location').textContent = booking.event?.event_location || 'TBA';
    document.getElementById('modal-booking-price').textContent = `R${parseFloat(booking.booking_total_price || 0).toLocaleString()}`;
    
    // Show modal
    modal.style.display = 'block';
}

// Create cancellation modal
function createCancellationModal() {
    const modal = document.createElement('div');
    modal.id = 'cancellation-modal';
    modal.className = 'modal';
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <h2>Cancel Booking</h2>
                <button class="modal-close" onclick="closeCancellationModal()">&times;</button>
            </div>
            
            <div class="modal-body">
                <div class="booking-summary">
                    <h3>Booking Details</h3>
                    <div class="summary-item">
                        <strong>Event:</strong> <span id="modal-booking-title"></span>
                    </div>
                    <div class="summary-item">
                        <strong>Date:</strong> <span id="modal-booking-date"></span>
                    </div>
                    <div class="summary-item">
                        <strong>Time:</strong> <span id="modal-booking-time"></span>
                    </div>
                    <div class="summary-item">
                        <strong>Location:</strong> <span id="modal-booking-location"></span>
                    </div>
                    <div class="summary-item">
                        <strong>Total Price:</strong> <span id="modal-booking-price"></span>
                    </div>
                </div>
                
                <div class="cancellation-reason">
                    <label for="cancellation-reason">Reason for Cancellation:</label>
                    <select id="cancellation-reason" required>
                        <option value="">Select a reason...</option>
                        <option value="schedule_conflict">Schedule Conflict</option>
                        <option value="change_of_plans">Change of Plans</option>
                        <option value="found_better_option">Found Better Option</option>
                        <option value="financial_issues">Financial Issues</option>
                        <option value="venue_issues">Venue Issues</option>
                        <option value="other">Other</option>
                    </select>
                </div>
                
                <div class="cancellation-notes">
                    <label for="cancellation-notes">Additional Notes (Optional):</label>
                    <textarea id="cancellation-notes" placeholder="Please provide any additional details..."></textarea>
                </div>
                
                <div class="cancellation-warning">
                    <div class="warning-icon">
                        <i class="fas fa-exclamation-triangle"></i>
                    </div>
                    <div class="warning-text">
                        <strong>Important:</strong> Cancelling this booking will update the status to "cancelled" and may affect service provider availability. 
                        Please review the cancellation policy before proceeding.
                    </div>
                </div>
            </div>
            
            <div class="modal-footer">
                <button class="btn-secondary" onclick="closeCancellationModal()">Keep Booking</button>
                <button class="btn-danger" onclick="confirmCancellation()">
                    <i class="fas fa-times"></i>
                    Cancel Booking
                </button>
            </div>
        </div>
    `;
    
    return modal;
}

// Close cancellation modal
function closeCancellationModal() {
    const modal = document.getElementById('cancellation-modal');
    if (modal) {
        modal.style.display = 'none';
    }
    selectedBooking = null;
}

// Confirm booking cancellation
async function confirmCancellation() {
    if (!selectedBooking) {
        showMessage("No booking selected for cancellation", "error");
        return;
    }
    
    const reason = document.getElementById('cancellation-reason').value;
    const notes = document.getElementById('cancellation-notes').value;
    
    if (!reason) {
        showMessage("Please select a cancellation reason", "warning");
        return;
    }
    
    if (!confirm(`Are you sure you want to cancel this booking?\n\nEvent: ${selectedBooking.event?.event_name}\nDate: ${new Date(selectedBooking.booking_date).toLocaleDateString()}\n\nThis action cannot be undone.`)) {
        return;
    }
    
    try {
        showLoading(true);
        
        // Update booking status to 'cancelled'
        const { error: updateError } = await supabase
            .from('booking')
            .update({ 
                booking_status: 'cancelled',
                updated_at: new Date().toISOString()
            })
            .eq('booking_id', selectedBooking.booking_id)
            .eq('client_id', clientId); // Ensure client can only cancel their own bookings

        if (updateError) throw updateError;
        
        // Create cancellation record
        const cancellationData = {
            booking_id: selectedBooking.booking_id,
            cancellation_reason: reason,
            cancellation_notes: notes,
            cancellation_status: 'confirmed',
            cancellation_date: new Date().toISOString().split('T')[0],
            cancellation_pre_fund_price: selectedBooking.booking_total_price,
            created_at: new Date().toISOString()
        };
        
        const { error: cancellationError } = await supabase
            .from('cancellation')
            .insert([cancellationData]);

        if (cancellationError) {
            console.warn("Failed to create cancellation record:", cancellationError);
            // Don't throw error here as the main cancellation was successful
        }
        
        // Send notification to service provider about cancellation
        await sendCancellationNotification(selectedBooking, reason);
        
        showMessage("Booking cancelled successfully!", "success");
        
        // Close modal
        closeCancellationModal();
        
        // Reload bookings to reflect the change
        await loadClientBookings();
        
        // Update UI to show cancelled booking
        updateBookingStatusInUI(selectedBooking.booking_id, 'cancelled');
        
    } catch (error) {
        console.error("Error cancelling booking:", error);
        showMessage("Error cancelling booking. Please try again.", "error");
    } finally {
        showLoading(false);
    }
}

// Send cancellation notification to service provider
async function sendCancellationNotification(booking, reason) {
    try {
        // Get service provider details from quotations or job carts
        const { data: jobCarts, error: jobCartError } = await supabase
            .from('job_cart')
            .select(`
                job_cart_id,
                quotations:quotation (
                    service_provider:service_provider_id (
                        service_provider_id,
                        service_provider_name,
                        service_provider_surname,
                        service_provider_email
                    )
                )
            `)
            .eq('event_id', booking.event_id);

        if (jobCartError) {
            console.warn("Error fetching service provider details:", jobCartError);
            return;
        }

        // Get unique service providers
        const serviceProviders = new Set();
        jobCarts.forEach(jobCart => {
            if (jobCart.quotations) {
                jobCart.quotations.forEach(quotation => {
                    if (quotation.service_provider) {
                        serviceProviders.add(quotation.service_provider);
                    }
                });
            }
        });

        // Send notification to each service provider
        for (const provider of serviceProviders) {
            const notification = {
                notification_type: 'booking_cancelled',
                notification_title: 'Booking Cancelled',
                notification_message: `A booking has been cancelled by the client. Event: ${booking.event?.event_name || 'Unknown'}. Reason: ${reason}`,
                notification_data: {
                    booking_id: booking.booking_id,
                    event_id: booking.event_id,
                    cancellation_reason: reason,
                    client_id: clientId
                },
                user_type: 'service_provider',
                user_id: provider.service_provider_id,
                notification_status: 'unread',
                created_at: new Date().toISOString()
            };

            const { error: notificationError } = await supabase
                .from('notification')
                .insert([notification]);

            if (notificationError) {
                console.warn("Failed to send cancellation notification:", notificationError);
            }
        }
        
        console.log("✅ Cancellation notifications sent to service providers");
        
    } catch (error) {
        console.error("Error sending cancellation notification:", error);
    }
}

// Update booking status in UI
function updateBookingStatusInUI(bookingId, newStatus) {
    const bookingCard = document.querySelector(`[data-booking-id="${bookingId}"]`);
    if (bookingCard) {
        const statusElement = bookingCard.querySelector('.booking-status');
        if (statusElement) {
            statusElement.textContent = newStatus;
            statusElement.className = `booking-status ${newStatus}`;
        }
        
        // Hide cancel button for cancelled bookings
        const cancelButton = bookingCard.querySelector('.btn-cancel');
        if (cancelButton) {
            cancelButton.style.display = 'none';
        }
    }
}

// View booking details
function viewBookingDetails(bookingId) {
    const booking = clientBookings.find(b => b.booking_id === bookingId);
    if (!booking) {
        showMessage("Booking details not found", "error");
        return;
    }
    
    // Create details modal
    let detailsModal = document.getElementById('details-modal');
    if (!detailsModal) {
        detailsModal = createDetailsModal();
        document.body.appendChild(detailsModal);
    }
    
    // Populate details
    document.getElementById('details-booking-title').textContent = booking.event?.event_name || 'Event';
    document.getElementById('details-booking-date').textContent = new Date(booking.booking_date).toLocaleDateString();
    document.getElementById('details-booking-time').textContent = `${booking.booking_start_time} - ${booking.booking_end_time}`;
    document.getElementById('details-booking-location').textContent = booking.event?.event_location || 'TBA';
    document.getElementById('details-booking-type').textContent = booking.event?.event_type || 'N/A';
    document.getElementById('details-booking-price').textContent = `R${parseFloat(booking.booking_total_price || 0).toLocaleString()}`;
    document.getElementById('details-booking-status').textContent = booking.booking_status;
    document.getElementById('details-booking-request').textContent = booking.booking_special_request || 'None';
    document.getElementById('details-booking-created').textContent = new Date(booking.created_at).toLocaleDateString();
    
    // Show modal
    detailsModal.style.display = 'block';
}

// Create details modal
function createDetailsModal() {
    const modal = document.createElement('div');
    modal.id = 'details-modal';
    modal.className = 'modal';
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <h2>Booking Details</h2>
                <button class="modal-close" onclick="closeDetailsModal()">&times;</button>
            </div>
            
            <div class="modal-body">
                <div class="details-grid">
                    <div class="detail-item">
                        <strong>Event Name:</strong>
                        <span id="details-booking-title"></span>
                    </div>
                    <div class="detail-item">
                        <strong>Date:</strong>
                        <span id="details-booking-date"></span>
                    </div>
                    <div class="detail-item">
                        <strong>Time:</strong>
                        <span id="details-booking-time"></span>
                    </div>
                    <div class="detail-item">
                        <strong>Location:</strong>
                        <span id="details-booking-location"></span>
                    </div>
                    <div class="detail-item">
                        <strong>Event Type:</strong>
                        <span id="details-booking-type"></span>
                    </div>
                    <div class="detail-item">
                        <strong>Total Price:</strong>
                        <span id="details-booking-price"></span>
                    </div>
                    <div class="detail-item">
                        <strong>Status:</strong>
                        <span id="details-booking-status"></span>
                    </div>
                    <div class="detail-item">
                        <strong>Special Requests:</strong>
                        <span id="details-booking-request"></span>
                    </div>
                    <div class="detail-item">
                        <strong>Created:</strong>
                        <span id="details-booking-created"></span>
                    </div>
                </div>
            </div>
            
            <div class="modal-footer">
                <button class="btn-secondary" onclick="closeDetailsModal()">Close</button>
            </div>
        </div>
    `;
    
    return modal;
}

// Close details modal
function closeDetailsModal() {
    const modal = document.getElementById('details-modal');
    if (modal) {
        modal.style.display = 'none';
    }
}

// Show sample bookings for testing
function showSampleBookings() {
    const sampleBookings = [
        {
            booking_id: 'sample-booking-1',
            booking_date: '2025-09-15',
            booking_start_time: '18:00:00',
            booking_end_time: '22:00:00',
            booking_status: 'confirmed',
            booking_total_price: 5000,
            booking_special_request: 'Vegetarian options required',
            client_id: clientId,
            event_id: 'sample-event-1',
            created_at: new Date().toISOString(),
            event: {
                event_id: 'sample-event-1',
                event_name: 'Wedding Reception',
                event_type: 'Wedding',
                event_location: 'Johannesburg Country Club',
                event_date: '2025-09-15'
            }
        },
        {
            booking_id: 'sample-booking-2',
            booking_date: '2025-09-22',
            booking_start_time: '19:00:00',
            booking_end_time: '23:00:00',
            booking_status: 'pending',
            booking_total_price: 3500,
            booking_special_request: 'DJ and lighting required',
            client_id: clientId,
            event_id: 'sample-event-2',
            created_at: new Date().toISOString(),
            event: {
                event_id: 'sample-event-2',
                event_name: 'Birthday Party',
                event_type: 'Birthday',
                event_location: 'Sandton Convention Centre',
                event_date: '2025-09-22'
            }
        }
    ];
    
    clientBookings = sampleBookings;
    displayClientBookings(sampleBookings);
    
    // Add sample data indicator
    const indicator = document.createElement('div');
    indicator.className = 'sample-data-indicator';
    indicator.innerHTML = `
        <div class="alert alert-info">
            <i class="fas fa-info-circle"></i>
            <strong>Sample Data:</strong> These are sample bookings for testing purposes. In a real scenario, these would be your actual bookings.
        </div>
    `;
    
    const bookingsContainer = document.getElementById('bookings-container');
    if (bookingsContainer) {
        bookingsContainer.insertBefore(indicator, bookingsContainer.firstChild);
    }
    
    showMessage("Sample bookings loaded for testing", "info");
}

// Setup event listeners
function setupEventListeners() {
    // Close modals when clicking outside
    document.addEventListener('click', function(event) {
        const modal = document.getElementById('cancellation-modal');
        if (event.target === modal) {
            closeCancellationModal();
        }
        
        const detailsModal = document.getElementById('details-modal');
        if (event.target === detailsModal) {
            closeDetailsModal();
        }
    });
    
    // Refresh bookings button
    const refreshBtn = document.getElementById('refresh-bookings');
    if (refreshBtn) {
        refreshBtn.addEventListener('click', loadClientBookings);
    }
}

// Setup real-time subscriptions
function setupRealtimeSubscriptions() {
    // Subscribe to booking updates
    const subscription = supabase
        .channel('booking-cancellation-updates')
        .on('postgres_changes', 
            { 
                event: 'UPDATE', 
                schema: 'public', 
                table: 'booking',
                filter: `client_id=eq.${clientId}`
            }, 
            (payload) => {
                console.log('Real-time booking update:', payload);
                if (payload.new.booking_status === 'cancelled') {
                    updateBookingStatusInUI(payload.new.booking_id, 'cancelled');
                }
            }
        )
        .subscribe();
    
    console.log("✅ Real-time subscriptions setup for booking cancellation");
}

// Utility functions
function showLoading(show) {
    const loadingIndicator = document.getElementById('loading-indicator');
    if (loadingIndicator) {
        loadingIndicator.style.display = show ? 'block' : 'none';
    }
}

function showMessage(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.innerHTML = `
        <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : type === 'warning' ? 'exclamation-triangle' : 'info-circle'}"></i>
        <span>${message}</span>
    `;
    
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 15px 20px;
        border-radius: 5px;
        color: white;
        font-weight: 500;
        z-index: 1000;
        max-width: 400px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        display: flex;
        align-items: center;
        gap: 10px;
    `;
    
    switch (type) {
        case 'success':
            notification.style.backgroundColor = '#10b981';
            break;
        case 'error':
            notification.style.backgroundColor = '#ef4444';
            break;
        case 'warning':
            notification.style.backgroundColor = '#f59e0b';
            break;
        default:
            notification.style.backgroundColor = '#3b82f6';
    }
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, 5000);
}

// Make functions globally accessible
window.selectBookingForCancellation = selectBookingForCancellation;
window.viewBookingDetails = viewBookingDetails;
window.closeCancellationModal = closeCancellationModal;
window.confirmCancellation = confirmCancellation;
window.closeDetailsModal = closeDetailsModal;
