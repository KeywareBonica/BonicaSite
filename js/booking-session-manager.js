/**
 * Booking Session Manager
 * Manages the complete booking flow state across multiple pages
 * Ensures consistent data access without requiring re-authentication
 */

class BookingSessionManager {
    constructor() {
        this.SESSION_KEY = 'bonicaBookingSession';
        this.session = this.loadSession();
    }

    /**
     * Initialize a new booking session
     * Called when user starts a new booking from bookings.html
     */
    initializeSession(clientId, userName = null, userType = 'client') {
        console.log('🆕 Initializing new booking session for client:', clientId);
        
        this.session = {
            // User Authentication
            clientId: clientId,
            userName: userName,
            userType: userType,
            
            // Session Metadata
            sessionStartTime: new Date().toISOString(),
            lastActivityTime: new Date().toISOString(),
            
            // Booking Flow Data
            eventId: null,
            jobCartIds: [],
            selectedServiceIds: [],
            quotationIds: [],
            acceptedQuotationIds: [],
            bookingId: null,
            paymentId: null,
            
            // Additional Data
            eventDetails: null,
            serviceDetails: [],
            quotationDetails: [],
            totalAmount: 0,
            
            // Flow Control
            currentStep: 1,
            completedSteps: [],
            
            // Flags
            isActive: true,
            needsPayment: false
        };
        
        this.saveSession();
        return this.session;
    }

    /**
     * Load existing session from localStorage
     */
    loadSession() {
        try {
            const stored = localStorage.getItem(this.SESSION_KEY);
            if (stored) {
                const session = JSON.parse(stored);
                console.log('✅ Loaded existing booking session:', session.clientId);
                return session;
            }
        } catch (error) {
            console.error('❌ Error loading session:', error);
        }
        return null;
    }

    /**
     * Save current session to localStorage
     */
    saveSession() {
        try {
            if (this.session) {
                this.session.lastActivityTime = new Date().toISOString();
                localStorage.setItem(this.SESSION_KEY, JSON.stringify(this.session));
                console.log('💾 Session saved');
            }
        } catch (error) {
            console.error('❌ Error saving session:', error);
        }
    }

    /**
     * Get current session or create from legacy localStorage keys
     */
    getSession() {
        // If no session exists, try to reconstruct from legacy localStorage
        if (!this.session || !this.session.clientId) {
            const clientId = localStorage.getItem('clientId') || 
                           localStorage.getItem('quotationClientId');
            
            if (clientId) {
                console.log('🔄 Reconstructing session from legacy localStorage');
                this.initializeSession(
                    clientId,
                    localStorage.getItem('userName'),
                    localStorage.getItem('userType') || 'client'
                );
                
                // Try to load existing booking data
                const eventId = localStorage.getItem('currentEventId');
                if (eventId) {
                    this.setEventId(eventId);
                }
            }
        }
        
        return this.session;
    }

    /**
     * Check if user is authenticated
     */
    isAuthenticated() {
        const session = this.getSession();
        return session && session.clientId && session.isActive;
    }

    /**
     * Get client ID (for backward compatibility)
     */
    getClientId() {
        const session = this.getSession();
        return session ? session.clientId : null;
    }

    /**
     * Get user name
     */
    getUserName() {
        const session = this.getSession();
        return session ? session.userName : null;
    }

    /**
     * Set event ID (Step 2 completed)
     */
    setEventId(eventId, eventDetails = null) {
        if (this.session) {
            this.session.eventId = eventId;
            this.session.eventDetails = eventDetails;
            this.session.currentStep = Math.max(this.session.currentStep, 3);
            if (!this.session.completedSteps.includes(2)) {
                this.session.completedSteps.push(2);
            }
            this.saveSession();
            console.log('✅ Event ID set:', eventId);
        }
    }

    /**
     * Get event ID
     */
    getEventId() {
        return this.session ? this.session.eventId : null;
    }

    /**
     * Add job cart ID (Step 3)
     */
    addJobCartId(jobCartId, serviceId = null) {
        if (this.session) {
            if (!this.session.jobCartIds.includes(jobCartId)) {
                this.session.jobCartIds.push(jobCartId);
            }
            if (serviceId && !this.session.selectedServiceIds.includes(serviceId)) {
                this.session.selectedServiceIds.push(serviceId);
            }
            this.session.currentStep = Math.max(this.session.currentStep, 4);
            if (!this.session.completedSteps.includes(3)) {
                this.session.completedSteps.push(3);
            }
            this.saveSession();
            console.log('✅ Job cart added:', jobCartId);
        }
    }

    /**
     * Get job cart IDs
     */
    getJobCartIds() {
        return this.session ? this.session.jobCartIds : [];
    }

    /**
     * Get selected service IDs
     */
    getSelectedServiceIds() {
        return this.session ? this.session.selectedServiceIds : [];
    }

    /**
     * Add accepted quotation (Step 5)
     */
    addAcceptedQuotation(quotationId, quotationDetails = null) {
        if (this.session) {
            if (!this.session.acceptedQuotationIds.includes(quotationId)) {
                this.session.acceptedQuotationIds.push(quotationId);
            }
            if (quotationDetails) {
                this.session.quotationDetails.push(quotationDetails);
            }
            this.session.currentStep = Math.max(this.session.currentStep, 6);
            if (!this.session.completedSteps.includes(5)) {
                this.session.completedSteps.push(5);
            }
            this.saveSession();
            console.log('✅ Quotation accepted:', quotationId);
        }
    }

    /**
     * Get accepted quotation IDs
     */
    getAcceptedQuotationIds() {
        return this.session ? this.session.acceptedQuotationIds : [];
    }

    /**
     * Set booking ID (Step 6 completed)
     */
    setBookingId(bookingId) {
        if (this.session) {
            this.session.bookingId = bookingId;
            this.session.currentStep = Math.max(this.session.currentStep, 7);
            if (!this.session.completedSteps.includes(6)) {
                this.session.completedSteps.push(6);
            }
            this.saveSession();
            console.log('✅ Booking ID set:', bookingId);
        }
    }

    /**
     * Get booking ID
     */
    getBookingId() {
        return this.session ? this.session.bookingId : null;
    }

    /**
     * Set payment ID (Step 7 completed)
     */
    setPaymentId(paymentId) {
        if (this.session) {
            this.session.paymentId = paymentId;
            this.session.currentStep = 8;
            if (!this.session.completedSteps.includes(7)) {
                this.session.completedSteps.push(7);
            }
            this.saveSession();
            console.log('✅ Payment ID set:', paymentId);
        }
    }

    /**
     * Get payment ID
     */
    getPaymentId() {
        return this.session ? this.session.paymentId : null;
    }

    /**
     * Set total booking amount
     */
    setTotalAmount(amount) {
        if (this.session) {
            this.session.totalAmount = amount;
            this.saveSession();
        }
    }

    /**
     * Get total booking amount
     */
    getTotalAmount() {
        return this.session ? this.session.totalAmount : 0;
    }

    /**
     * Complete the booking session
     */
    completeSession() {
        if (this.session) {
            this.session.isActive = false;
            this.session.completedSteps.push(8);
            this.saveSession();
            console.log('✅ Booking session completed');
        }
    }

    /**
     * Clear the current session (logout or new booking)
     */
    clearSession() {
        localStorage.removeItem(this.SESSION_KEY);
        this.session = null;
        console.log('🗑️ Session cleared');
    }

    /**
     * Get full session data (for debugging)
     */
    getFullSession() {
        return this.session;
    }

    /**
     * Check if session is expired (older than 24 hours)
     */
    isSessionExpired() {
        if (!this.session || !this.session.lastActivityTime) {
            return true;
        }
        
        const lastActivity = new Date(this.session.lastActivityTime);
        const now = new Date();
        const hoursSinceActivity = (now - lastActivity) / (1000 * 60 * 60);
        
        return hoursSinceActivity > 24;
    }

    /**
     * Export session data for API calls
     */
    exportForAPI() {
        if (!this.session) {
            return null;
        }
        
        return {
            client_id: this.session.clientId,
            event_id: this.session.eventId,
            job_cart_ids: this.session.jobCartIds,
            quotation_ids: this.session.acceptedQuotationIds,
            booking_id: this.session.bookingId,
            payment_id: this.session.paymentId,
            total_amount: this.session.totalAmount
        };
    }

    /**
     * Debug: Print current session state
     */
    debugSession() {
        console.group('🔍 Booking Session Debug');
        console.log('Session Active:', this.isAuthenticated());
        console.log('Client ID:', this.getClientId());
        console.log('User Name:', this.getUserName());
        console.log('Event ID:', this.getEventId());
        console.log('Job Cart IDs:', this.getJobCartIds());
        console.log('Quotation IDs:', this.getAcceptedQuotationIds());
        console.log('Booking ID:', this.getBookingId());
        console.log('Payment ID:', this.getPaymentId());
        console.log('Total Amount:', this.getTotalAmount());
        console.log('Current Step:', this.session?.currentStep);
        console.log('Completed Steps:', this.session?.completedSteps);
        console.log('Full Session:', this.getFullSession());
        console.groupEnd();
    }
}

// Create global instance
window.BookingSession = new BookingSessionManager();

// Backward compatibility: Sync with legacy localStorage
window.addEventListener('storage', (e) => {
    if (e.key === 'clientId' && e.newValue) {
        const session = window.BookingSession.getSession();
        if (!session || session.clientId !== e.newValue) {
            window.BookingSession.initializeSession(e.newValue);
        }
    }
});

console.log('✅ Booking Session Manager loaded');

