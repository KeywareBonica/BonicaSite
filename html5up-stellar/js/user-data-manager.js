/**
 * User Data Manager
 * Ensures all user data (except admin) is fetched from database
 * Eliminates hardcoded user information throughout the application
 */

class UserDataManager {
    constructor() {
        this.supabase = null;
        this.dbService = null;
        this.currentUser = null;
        this.userType = null;
        this.isInitialized = false;
    }

    /**
     * Initialize the user data manager
     */
    async initialize() {
        try {
            // Initialize Supabase if not already done
            if (!window.supabase) {
                const SUPABASE_URL = "https://spudtrptbyvwyhvistdf.supabase.co";
                const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwdWR0cnB0Ynl2d3lodmlzdGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2OTk4NjgsImV4cCI6MjA3MTI3NTg2OH0.GBo-RtgbRZCmhSAZi0c5oXynMiJNeyrs0nLsk3CaV8A";
                this.supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
            } else {
                this.supabase = window.supabase;
            }

            // Initialize Database Service
            if (!window.DatabaseService) {
                console.error('DatabaseService not loaded. Please include database-service.js');
                return false;
            }
            
            this.dbService = new DatabaseService(this.supabase);
            const { client, provider } = await this.dbService.initialize();
            
            if (client) {
                this.currentUser = client;
                this.userType = 'client';
            } else if (provider) {
                this.currentUser = provider;
                this.userType = 'service_provider';
            }

            this.isInitialized = true;
            console.log('✅ User Data Manager initialized');
            return true;
        } catch (error) {
            console.error('❌ Error initializing User Data Manager:', error);
            return false;
        }
    }

    /**
     * Get current user data from database
     */
    async getCurrentUserData() {
        if (!this.isInitialized) {
            await this.initialize();
        }

        return {
            user: this.currentUser,
            userType: this.userType,
            isAdmin: this.isAdminUser()
        };
    }

    /**
     * Check if current user is admin
     */
    isAdminUser() {
        return window.AdminAuth && window.AdminAuth.isAdminAuthenticated();
    }

    /**
     * Replace all hardcoded user data with database data
     */
    async replaceAllHardcodedData() {
        if (!this.isInitialized) {
            await this.initialize();
        }

        try {
            // Skip if admin (admin data is intentionally hardcoded)
            if (this.isAdminUser()) {
                console.log('ℹ️ Skipping data replacement for admin user');
                return;
            }

            if (this.userType === 'client') {
                await this.replaceClientData();
            } else if (this.userType === 'service_provider') {
                await this.replaceServiceProviderData();
            }

            // Replace common data
            await this.replaceBookingData();
            await this.replaceQuotationData();
            await this.replaceEventData();
            await this.replaceNotificationData();

            console.log('✅ All hardcoded data replaced with database data');
        } catch (error) {
            console.error('❌ Error replacing hardcoded data:', error);
        }
    }

    /**
     * Replace client data
     */
    async replaceClientData() {
        if (!this.currentUser || this.userType !== 'client') return;

        const client = this.currentUser;

        // Update client name in UI
        this.updateElementText('#user-name, .client-name, [data-client-name]', 
            `${client.client_name} ${client.client_surname}`);

        // Update client email
        this.updateElementText('[data-client-email]', client.client_email);

        // Update client contact
        this.updateElementText('[data-client-contact]', client.client_contact);

        // Update form fields
        this.updateFormFields({
            'input[name*="name"]:first-of-type': client.client_name,
            'input[name*="surname"]': client.client_surname,
            'input[type="email"]': client.client_email,
            'input[type="tel"]': client.client_contact,
            'input[name*="location"]': client.client_location || ''
        });

        console.log('✅ Client data replaced');
    }

    /**
     * Replace service provider data
     */
    async replaceServiceProviderData() {
        if (!this.currentUser || this.userType !== 'service_provider') return;

        const provider = this.currentUser;

        // Update provider name in UI
        this.updateElementText('#provider-name, #welcome-name, #sidebar-name, .provider-name', 
            `${provider.service_provider_name} ${provider.service_provider_surname}`);

        // Update provider avatar
        const avatar = document.getElementById('provider-avatar');
        if (avatar) {
            avatar.textContent = `${provider.service_provider_name.charAt(0)}${provider.service_provider_surname.charAt(0)}`;
        }

        // Update provider email
        this.updateElementText('[data-provider-email]', provider.service_provider_email);

        // Update provider contact
        this.updateElementText('[data-provider-contact]', provider.service_provider_contactno);

        // Update provider location
        this.updateElementText('[data-provider-location]', provider.service_provider_location || '');

        // Update form fields
        this.updateFormFields({
            'input[type="text"]:first-of-type': provider.service_provider_name,
            'input[name*="surname"]': provider.service_provider_surname,
            'input[type="email"]': provider.service_provider_email,
            'input[type="tel"]': provider.service_provider_contactno,
            'input[placeholder*="Location"]': provider.service_provider_location || ''
        });

        console.log('✅ Service provider data replaced');
    }

    /**
     * Replace booking data
     */
    async replaceBookingData() {
        try {
            let bookings = [];
            
            if (this.userType === 'client') {
                bookings = await this.dbService.getCurrentClientBookings();
            } else if (this.userType === 'service_provider') {
                // Get bookings through job carts
                const jobCarts = await this.dbService.getAllJobCarts();
                bookings = jobCarts.filter(cart => cart.event?.client);
            }

            // Update booking lists
            this.updateBookingContainers(bookings);
            
            console.log('✅ Booking data replaced');
        } catch (error) {
            console.error('Error replacing booking data:', error);
        }
    }

    /**
     * Replace quotation data
     */
    async replaceQuotationData() {
        try {
            let quotations = [];
            
            if (this.userType === 'client') {
                quotations = await this.dbService.getCurrentClientQuotations();
            } else if (this.userType === 'service_provider') {
                quotations = await this.dbService.getServiceProviderQuotations(this.currentUser.service_provider_id);
            }

            // Update quotation lists
            this.updateQuotationContainers(quotations);
            
            console.log('✅ Quotation data replaced');
        } catch (error) {
            console.error('Error replacing quotation data:', error);
        }
    }

    /**
     * Replace event data
     */
    async replaceEventData() {
        try {
            let events = [];
            
            if (this.userType === 'client') {
                events = await this.dbService.getCurrentClientEvents();
            } else {
                events = await this.dbService.getAllEvents();
            }

            // Update event lists
            this.updateEventContainers(events);
            
            console.log('✅ Event data replaced');
        } catch (error) {
            console.error('Error replacing event data:', error);
        }
    }

    /**
     * Replace notification data
     */
    async replaceNotificationData() {
        try {
            const notifications = await this.dbService.getCurrentUserNotifications();
            
            // Update notification count
            const unreadCount = notifications.filter(n => n.notification_status === 'unread').length;
            this.updateElementText('#notification-count, .notification-badge', unreadCount);

            // Update notification lists
            this.updateNotificationContainers(notifications);
            
            console.log('✅ Notification data replaced');
        } catch (error) {
            console.error('Error replacing notification data:', error);
        }
    }

    /**
     * Update element text content
     */
    updateElementText(selector, text) {
        const elements = document.querySelectorAll(selector);
        elements.forEach(element => {
            if (element && text !== undefined) {
                element.textContent = text;
            }
        });
    }

    /**
     * Update form fields
     */
    updateFormFields(fieldMappings) {
        Object.entries(fieldMappings).forEach(([selector, value]) => {
            const elements = document.querySelectorAll(selector);
            elements.forEach(element => {
                if (element && value !== undefined) {
                    element.value = value;
                }
            });
        });
    }

    /**
     * Update booking containers
     */
    updateBookingContainers(bookings) {
        const containers = [
            '.booking-list',
            '.recent-bookings',
            '#bookings-list',
            '.bookings-container'
        ];

        containers.forEach(selector => {
            const container = document.querySelector(selector);
            if (container) {
                container.innerHTML = bookings.slice(0, 10).map(booking => `
                    <div class="booking-item">
                        <h6>${booking.event?.event_name || 'Event'}</h6>
                        <p class="text-muted">${booking.event?.event_date || 'Date not available'}</p>
                        <p class="text-muted">Client: ${booking.event?.client?.client_name || 'N/A'} ${booking.event?.client?.client_surname || ''}</p>
                        <span class="badge bg-${this.getStatusColor(booking.booking_status)}">${booking.booking_status}</span>
                    </div>
                `).join('');
            }
        });
    }

    /**
     * Update quotation containers
     */
    updateQuotationContainers(quotations) {
        const containers = [
            '.quotation-list',
            '.recent-quotations',
            '#quotations-list',
            '.quotations-container'
        ];

        containers.forEach(selector => {
            const container = document.querySelector(selector);
            if (container) {
                container.innerHTML = quotations.slice(0, 10).map(quotation => `
                    <div class="quotation-item">
                        <h6>${quotation.job_cart?.job_cart_item || 'Service'}</h6>
                        <p class="text-muted">R ${quotation.quotation_price?.toLocaleString() || '0'}</p>
                        <p class="text-muted">Provider: ${quotation.service_provider?.service_provider_name || 'N/A'} ${quotation.service_provider?.service_provider_surname || ''}</p>
                        <span class="badge bg-${this.getQuotationStatusColor(quotation.quotation_status)}">${quotation.quotation_status}</span>
                    </div>
                `).join('');
            }
        });
    }

    /**
     * Update event containers
     */
    updateEventContainers(events) {
        const containers = [
            '.event-list',
            '.recent-events',
            '#events-list',
            '.events-container'
        ];

        containers.forEach(selector => {
            const container = document.querySelector(selector);
            if (container) {
                container.innerHTML = events.slice(0, 10).map(event => `
                    <div class="event-item">
                        <h6>${event.event_name || 'Event'}</h6>
                        <p class="text-muted">${event.event_date || 'Date not available'}</p>
                        <p class="text-muted">Location: ${event.event_location || 'N/A'}</p>
                        <span class="badge bg-${this.getEventStatusColor(event.event_status)}">${event.event_status || 'pending'}</span>
                    </div>
                `).join('');
            }
        });
    }

    /**
     * Update notification containers
     */
    updateNotificationContainers(notifications) {
        const containers = [
            '.notification-list',
            '#notifications-list',
            '.notifications-container'
        ];

        containers.forEach(selector => {
            const container = document.querySelector(selector);
            if (container) {
                container.innerHTML = notifications.slice(0, 10).map(notification => `
                    <div class="notification-item ${notification.notification_status === 'unread' ? 'unread' : ''}">
                        <h6>${notification.notification_title || 'Notification'}</h6>
                        <p class="text-muted">${notification.notification_message || ''}</p>
                        <small class="text-muted">${new Date(notification.created_at).toLocaleDateString()}</small>
                    </div>
                `).join('');
            }
        });
    }

    /**
     * Get status color for badges
     */
    getStatusColor(status) {
        switch (status) {
            case 'completed': return 'success';
            case 'pending': return 'warning';
            case 'cancelled': return 'danger';
            case 'accepted': return 'success';
            case 'rejected': return 'danger';
            default: return 'secondary';
        }
    }

    /**
     * Get quotation status color
     */
    getQuotationStatusColor(status) {
        switch (status) {
            case 'accepted': return 'success';
            case 'pending': return 'warning';
            case 'rejected': return 'danger';
            case 'confirmed': return 'info';
            default: return 'secondary';
        }
    }

    /**
     * Get event status color
     */
    getEventStatusColor(status) {
        switch (status) {
            case 'completed': return 'success';
            case 'active': return 'info';
            case 'pending': return 'warning';
            case 'cancelled': return 'danger';
            default: return 'secondary';
        }
    }

    /**
     * Auto-replace data on page load
     */
    autoReplaceOnLoad() {
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => {
                this.replaceAllHardcodedData();
            });
        } else {
            this.replaceAllHardcodedData();
        }
    }
}

// Create global instance
window.UserDataManager = new UserDataManager();

// Auto-run on page load
window.UserDataManager.autoReplaceOnLoad();

console.log('🔄 User Data Manager loaded - will auto-replace hardcoded data (except admin)');
