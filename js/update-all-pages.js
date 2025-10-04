/**
 * Universal Database Integration Script
 * This script updates ALL pages to use database-driven data instead of hardcoded values
 * Run this script on any page to ensure database integration
 */

class UniversalDatabaseIntegration {
    constructor() {
        this.supabase = null;
        this.dbService = null;
        this.currentUser = null;
        this.userType = null;
        this.isInitialized = false;
    }

    /**
     * Initialize the universal database integration
     */
    async initialize() {
        try {
            // Initialize Supabase
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
            console.log('✅ Universal Database Integration initialized');
            return true;
        } catch (error) {
            console.error('❌ Error initializing Universal Database Integration:', error);
            return false;
        }
    }

    /**
     * Replace hardcoded service provider data with database data
     */
    async replaceServiceProviderData() {
        if (!this.isInitialized) return;

        try {
            // Replace hardcoded provider names in service provider dashboard
            if (this.userType === 'service_provider' && this.currentUser) {
                const provider = this.currentUser;
                
                // Update all provider name references
                this.replaceTextInElements('.provider-name, #provider-name, #welcome-name, #sidebar-name', 
                    `${provider.service_provider_name} ${provider.service_provider_surname}`);
                
                // Update provider avatar
                const avatar = document.getElementById('provider-avatar');
                if (avatar) {
                    avatar.textContent = `${provider.service_provider_name.charAt(0)}${provider.service_provider_surname.charAt(0)}`;
                }

                // Update profile form data
                this.updateFormFields({
                    'input[type="text"]': provider.service_provider_name,
                    'input[type="email"]': provider.service_provider_email,
                    'input[type="tel"]': provider.service_provider_contact,
                    'input[placeholder*="Location"]': provider.service_provider_location || ''
                });
            }

            // Replace hardcoded client names with real client data
            await this.replaceClientData();
            
            console.log('✅ Service provider data replaced with database data');
        } catch (error) {
            console.error('❌ Error replacing service provider data:', error);
        }
    }

    /**
     * Replace hardcoded client data with database data
     */
    async replaceClientData() {
        if (!this.isInitialized) return;

        try {
            if (this.userType === 'client' && this.currentUser) {
                const client = this.currentUser;
                
                // Update client name references
                this.replaceTextInElements('#user-name, .client-name', 
                    `${client.client_name} ${client.client_surname}`);
                
                // Update profile information
                this.updateFormFields({
                    'input[name*="name"]': client.client_name,
                    'input[name*="surname"]': client.client_surname,
                    'input[type="email"]': client.client_email,
                    'input[type="tel"]': client.client_contact,
                    'input[name*="location"]': client.client_location || ''
                });
            }

            console.log('✅ Client data replaced with database data');
        } catch (error) {
            console.error('❌ Error replacing client data:', error);
        }
    }

    /**
     * Replace hardcoded booking data with real booking data
     */
    async replaceBookingData() {
        if (!this.isInitialized) return;

        try {
            let bookings = [];
            
            if (this.userType === 'client') {
                bookings = await this.dbService.getCurrentClientBookings();
            } else if (this.userType === 'service_provider') {
                // Get bookings for service provider through job carts
                const jobCarts = await this.dbService.getAllJobCarts();
                bookings = jobCarts.filter(cart => cart.event?.client);
            }

            // Replace hardcoded booking entries
            await this.updateBookingList(bookings);
            
            console.log('✅ Booking data replaced with database data');
        } catch (error) {
            console.error('❌ Error replacing booking data:', error);
        }
    }

    /**
     * Replace hardcoded quotation data with real quotation data
     */
    async replaceQuotationData() {
        if (!this.isInitialized) return;

        try {
            let quotations = [];
            
            if (this.userType === 'client') {
                quotations = await this.dbService.getCurrentClientQuotations();
            } else if (this.userType === 'service_provider') {
                quotations = await this.dbService.getServiceProviderQuotations(this.currentUser.service_provider_id);
            }

            // Replace hardcoded quotation entries
            await this.updateQuotationList(quotations);
            
            console.log('✅ Quotation data replaced with database data');
        } catch (error) {
            console.error('❌ Error replacing quotation data:', error);
        }
    }

    /**
     * Replace hardcoded notification data with real notification data
     */
    async replaceNotificationData() {
        if (!this.isInitialized) return;

        try {
            const notifications = await this.dbService.getCurrentUserNotifications();
            
            // Update notification count
            const notificationBadge = document.getElementById('notification-count');
            if (notificationBadge) {
                notificationBadge.textContent = notifications.filter(n => n.notification_status === 'unread').length;
            }

            // Update notification list
            await this.updateNotificationList(notifications);
            
            console.log('✅ Notification data replaced with database data');
        } catch (error) {
            console.error('❌ Error replacing notification data:', error);
        }
    }

    /**
     * Update booking list with real data
     */
    async updateBookingList(bookings) {
        const bookingContainers = [
            '.booking-list',
            '.recent-bookings',
            '#bookings-list',
            '.bookings-container'
        ];

        bookingContainers.forEach(selector => {
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
     * Update quotation list with real data
     */
    async updateQuotationList(quotations) {
        const quotationContainers = [
            '.quotation-list',
            '.recent-quotations',
            '#quotations-list',
            '.quotations-container'
        ];

        quotationContainers.forEach(selector => {
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
     * Update notification list with real data
     */
    async updateNotificationList(notifications) {
        const notificationContainers = [
            '.notification-list',
            '#notifications-list',
            '.notifications-container'
        ];

        notificationContainers.forEach(selector => {
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
     * Replace text in elements matching selector
     */
    replaceTextInElements(selector, newText) {
        const elements = document.querySelectorAll(selector);
        elements.forEach(element => {
            if (element && element.textContent.trim()) {
                element.textContent = newText;
            }
        });
    }

    /**
     * Update form fields with data
     */
    updateFormFields(fieldMappings) {
        Object.entries(fieldMappings).forEach(([selector, value]) => {
            const elements = document.querySelectorAll(selector);
            elements.forEach(element => {
                if (element && value) {
                    element.value = value;
                }
            });
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
     * Run complete data replacement for current page
     */
    async runCompleteReplacement() {
        if (!await this.initialize()) {
            console.error('❌ Failed to initialize database integration');
            return false;
        }

        try {
            await this.replaceServiceProviderData();
            await this.replaceBookingData();
            await this.replaceQuotationData();
            await this.replaceNotificationData();
            
            console.log('✅ Complete data replacement finished');
            return true;
        } catch (error) {
            console.error('❌ Error in complete data replacement:', error);
            return false;
        }
    }

    /**
     * Auto-replace data on page load
     */
    autoReplaceOnLoad() {
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => {
                this.runCompleteReplacement();
            });
        } else {
            this.runCompleteReplacement();
        }
    }
}

// Auto-initialize if script is loaded
const universalDBIntegration = new UniversalDatabaseIntegration();

// Make it available globally
window.UniversalDBIntegration = universalDBIntegration;

// Auto-run on page load
universalDBIntegration.autoReplaceOnLoad();

console.log('🔄 Universal Database Integration loaded - will auto-replace hardcoded data');
