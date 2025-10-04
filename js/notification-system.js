/**
 * Real-Time Notification System
 * Handles all notifications for both clients and service providers
 * Provides real-time updates across the entire application
 */

class NotificationSystem {
    constructor(supabase, realtimeService) {
        this.supabase = supabase;
        this.realtimeService = realtimeService;
        this.subscriptions = new Map();
        this.notificationCallbacks = new Map();
        this.isInitialized = false;
        this.currentUser = null;
        this.userType = null;
        this.unreadCount = 0;
    }

    /**
     * Initialize the notification system
     */
    async initialize() {
        try {
            // Get current user information
            await this.getCurrentUser();
            
            if (!this.currentUser) {
                console.warn('⚠️ No user found, notification system will not initialize');
                return;
            }

            // Subscribe to all notification types
            this.subscribeToNotifications();
            this.subscribeToJobCartUpdates();
            this.subscribeToQuotationUpdates();
            this.subscribeToBookingUpdates();
            this.subscribeToCancellationUpdates();

            // Initialize notification UI
            this.initializeNotificationUI();
            
            // Load existing notifications
            await this.loadNotifications();

            this.isInitialized = true;
            console.log('✅ Notification System initialized for:', this.userType, this.currentUser.id);
        } catch (error) {
            console.error('❌ Failed to initialize Notification System:', error);
        }
    }

    /**
     * Get current user information
     */
    async getCurrentUser() {
        try {
            const { data: { user }, error: authError } = await this.supabase.auth.getUser();
            if (authError || !user) {
                return;
            }

            // Determine user type from localStorage
            const storedUserType = localStorage.getItem('userType');
            const storedUserId = localStorage.getItem(storedUserType === 'client' ? 'clientId' : 'serviceProviderId');
            
            if (storedUserType && storedUserId) {
                this.userType = storedUserType;
                this.currentUser = { id: storedUserId, type: storedUserType, email: user.email };
            }
        } catch (error) {
            console.error('❌ Error getting current user:', error);
        }
    }

    /**
     * Subscribe to notification table updates
     */
    subscribeToNotifications() {
        const subscription = this.realtimeService.subscribeToTable('notification', {
            event: '*',
            filter: `user_id=eq.${this.currentUser.id}`
        }, (payload) => {
            console.log('🔔 Real-time notification update:', payload);
            this.handleNotificationUpdate(payload);
        });

        this.subscriptions.set('notifications', subscription);
    }

    /**
     * Subscribe to job cart updates
     */
    subscribeToJobCartUpdates() {
        const subscription = this.realtimeService.subscribeToTable('job_cart', {
            event: '*'
        }, (payload) => {
            console.log('🛒 Real-time job cart update:', payload);
            this.handleJobCartUpdate(payload);
        });

        this.subscriptions.set('job_carts', subscription);
    }

    /**
     * Subscribe to quotation updates
     */
    subscribeToQuotationUpdates() {
        const subscription = this.realtimeService.subscribeToTable('quotation', {
            event: '*'
        }, (payload) => {
            console.log('💰 Real-time quotation update:', payload);
            this.handleQuotationUpdate(payload);
        });

        this.subscriptions.set('quotations', subscription);
    }

    /**
     * Subscribe to booking updates
     */
    subscribeToBookingUpdates() {
        const subscription = this.realtimeService.subscribeToTable('booking', {
            event: '*'
        }, (payload) => {
            console.log('📅 Real-time booking update:', payload);
            this.handleBookingUpdate(payload);
        });

        this.subscriptions.set('bookings', subscription);
    }

    /**
     * Subscribe to cancellation updates
     */
    subscribeToCancellationUpdates() {
        // This would be handled through the other subscriptions
        // but we can add specific cancellation logic here if needed
    }

    /**
     * Handle notification table updates
     */
    handleNotificationUpdate(payload) {
        const { eventType, new: newRecord, old: oldRecord } = payload;

        switch (eventType) {
            case 'INSERT':
                this.handleNewNotification(newRecord);
                break;
            case 'UPDATE':
                this.handleNotificationUpdate(newRecord);
                break;
            case 'DELETE':
                this.handleNotificationDelete(oldRecord);
                break;
        }
    }

    /**
     * Handle new notification
     */
    handleNewNotification(notification) {
        // Add to UI
        this.addNotificationToUI(notification);
        
        // Update unread count
        if (notification.notification_status === 'unread') {
            this.incrementUnreadCount();
        }

        // Show toast notification
        this.showToastNotification(notification);

        // Trigger callback if registered
        const callback = this.notificationCallbacks.get('new_notification');
        if (callback) {
            callback(notification);
        }
    }

    /**
     * Handle job cart updates
     */
    handleJobCartUpdate(payload) {
        const { eventType, new: newRecord, old: oldRecord } = payload;

        if (eventType === 'INSERT') {
            // New job cart created - notify relevant service providers
            if (this.userType === 'service_provider') {
                this.checkAndNotifyJobCart(newRecord);
            }
        } else if (eventType === 'UPDATE') {
            // Job cart status changed
            this.handleJobCartStatusChange(newRecord, oldRecord);
        }

        // Trigger callback if registered
        const callback = this.notificationCallbacks.get('job_cart_update');
        if (callback) {
            callback(payload);
        }
    }

    /**
     * Handle quotation updates
     */
    handleQuotationUpdate(payload) {
        const { eventType, new: newRecord, old: oldRecord } = payload;

        if (eventType === 'INSERT') {
            // New quotation submitted - notify client
            if (this.userType === 'client') {
                this.notifyClientOfNewQuotation(newRecord);
            }
        } else if (eventType === 'UPDATE') {
            // Quotation status changed
            this.handleQuotationStatusChange(newRecord, oldRecord);
        }

        // Trigger callback if registered
        const callback = this.notificationCallbacks.get('quotation_update');
        if (callback) {
            callback(payload);
        }
    }

    /**
     * Handle booking updates
     */
    handleBookingUpdate(payload) {
        const { eventType, new: newRecord, old: oldRecord } = payload;

        if (eventType === 'UPDATE') {
            // Booking status changed
            this.handleBookingStatusChange(newRecord, oldRecord);
        }

        // Trigger callback if registered
        const callback = this.notificationCallbacks.get('booking_update');
        if (callback) {
            callback(payload);
        }
    }

    /**
     * Check and notify about new job cart
     */
    async checkAndNotifyJobCart(jobCart) {
        try {
            // Check if this service provider is relevant for this job cart
            const isRelevant = await this.isJobCartRelevant(jobCart);
            
            if (isRelevant) {
                // Create notification for this service provider
                await this.createNotification({
                    notification_type: 'new_job_cart',
                    notification_title: 'New Job Available',
                    notification_message: `A new job cart has been created for "${jobCart.job_cart_item}". Click to view details.`,
                    notification_date: new Date().toISOString().split('T')[0],
                    notification_time: new Date().toLocaleTimeString('en-ZA', { hour12: false }),
                    notification_status: 'unread',
                    user_type: this.userType,
                    user_id: this.currentUser.id,
                    job_cart_id: jobCart.job_cart_id,
                    event_id: jobCart.event_id
                });
            }
        } catch (error) {
            console.error('❌ Error checking job cart relevance:', error);
        }
    }

    /**
     * Check if job cart is relevant for current service provider
     */
    async isJobCartRelevant(jobCart) {
        try {
            // Get service provider's services
            const { data: services, error } = await this.supabase
                .from('service_provider')
                .select('service_provider_services')
                .eq('service_provider_id', this.currentUser.id)
                .single();

            if (error || !services) return false;

            const providerServices = services.service_provider_services || [];
            const jobCartService = jobCart.job_cart_item;

            // Check if provider offers this service
            return providerServices.some(service => 
                service.toLowerCase().includes(jobCartService.toLowerCase()) ||
                jobCartService.toLowerCase().includes(service.toLowerCase())
            );
        } catch (error) {
            console.error('❌ Error checking service relevance:', error);
            return false;
        }
    }

    /**
     * Notify client of new quotation
     */
    async notifyClientOfNewQuotation(quotation) {
        try {
            // Get job cart details to find the client
            const { data: jobCart, error } = await this.supabase
                .from('job_cart')
                .select(`
                    job_cart_item,
                    event_id,
                    event:event_id (
                        client_id,
                        event_name
                    )
                `)
                .eq('job_cart_id', quotation.job_cart_id)
                .single();

            if (error || !jobCart) return;

            // Only notify if this is the client's quotation
            if (jobCart.event.client_id === this.currentUser.id) {
                await this.createNotification({
                    notification_type: 'new_quotation',
                    notification_title: 'New Quotation Received',
                    notification_message: `A new quotation has been submitted for "${jobCart.job_cart_item}" in your event "${jobCart.event.event_name}".`,
                    notification_date: new Date().toISOString().split('T')[0],
                    notification_time: new Date().toLocaleTimeString('en-ZA', { hour12: false }),
                    notification_status: 'unread',
                    user_type: this.userType,
                    user_id: this.currentUser.id,
                    quotation_id: quotation.quotation_id,
                    job_cart_id: quotation.job_cart_id,
                    event_id: jobCart.event_id
                });
            }
        } catch (error) {
            console.error('❌ Error notifying client of new quotation:', error);
        }
    }

    /**
     * Handle job cart status changes
     */
    handleJobCartStatusChange(newRecord, oldRecord) {
        if (newRecord.job_cart_status !== oldRecord.job_cart_status) {
            // Job cart status changed
            this.createStatusChangeNotification(newRecord, oldRecord, 'job_cart');
        }
    }

    /**
     * Handle quotation status changes
     */
    handleQuotationStatusChange(newRecord, oldRecord) {
        if (newRecord.quotation_status !== oldRecord.quotation_status) {
            // Quotation status changed
            this.createStatusChangeNotification(newRecord, oldRecord, 'quotation');
        }
    }

    /**
     * Handle booking status changes
     */
    handleBookingStatusChange(newRecord, oldRecord) {
        if (newRecord.booking_status !== oldRecord.booking_status) {
            // Booking status changed
            this.createStatusChangeNotification(newRecord, oldRecord, 'booking');
        }
    }

    /**
     * Create status change notification
     */
    async createStatusChangeNotification(newRecord, oldRecord, type) {
        try {
            let notification = null;

            switch (type) {
                case 'job_cart':
                    notification = {
                        notification_type: 'job_cart_status_changed',
                        notification_title: 'Job Cart Status Updated',
                        notification_message: `Job cart status changed from "${oldRecord.job_cart_status}" to "${newRecord.job_cart_status}".`,
                        job_cart_id: newRecord.job_cart_id
                    };
                    break;
                case 'quotation':
                    notification = {
                        notification_type: 'quotation_status_changed',
                        notification_title: 'Quotation Status Updated',
                        notification_message: `Your quotation status changed from "${oldRecord.quotation_status}" to "${newRecord.quotation_status}".`,
                        quotation_id: newRecord.quotation_id
                    };
                    break;
                case 'booking':
                    notification = {
                        notification_type: 'booking_status_changed',
                        notification_title: 'Booking Status Updated',
                        notification_message: `Booking status changed from "${oldRecord.booking_status}" to "${newRecord.booking_status}".`,
                        booking_id: newRecord.booking_id
                    };
                    break;
            }

            if (notification) {
                await this.createNotification({
                    ...notification,
                    notification_date: new Date().toISOString().split('T')[0],
                    notification_time: new Date().toLocaleTimeString('en-ZA', { hour12: false }),
                    notification_status: 'unread',
                    user_type: this.userType,
                    user_id: this.currentUser.id
                });
            }
        } catch (error) {
            console.error('❌ Error creating status change notification:', error);
        }
    }

    /**
     * Create a new notification
     */
    async createNotification(notificationData) {
        try {
            const { error } = await this.supabase
                .from('notification')
                .insert(notificationData);

            if (error) {
                console.error('❌ Error creating notification:', error);
            } else {
                console.log('✅ Notification created:', notificationData.notification_type);
            }
        } catch (error) {
            console.error('❌ Error creating notification:', error);
        }
    }

    /**
     * Load existing notifications
     */
    async loadNotifications() {
        try {
            const { data: notifications, error } = await this.supabase
                .from('notification')
                .select('*')
                .eq('user_id', this.currentUser.id)
                .eq('user_type', this.userType)
                .order('created_at', { ascending: false })
                .limit(50);

            if (error) throw error;

            this.notifications = notifications || [];
            this.updateUnreadCount();
            this.displayNotifications();
            
        } catch (error) {
            console.error('❌ Error loading notifications:', error);
        }
    }

    /**
     * Update unread count
     */
    updateUnreadCount() {
        this.unreadCount = this.notifications.filter(n => n.notification_status === 'unread').length;
        this.updateUnreadBadge();
    }

    /**
     * Increment unread count
     */
    incrementUnreadCount() {
        this.unreadCount++;
        this.updateUnreadBadge();
    }

    /**
     * Decrement unread count
     */
    decrementUnreadCount() {
        if (this.unreadCount > 0) {
            this.unreadCount--;
            this.updateUnreadBadge();
        }
    }

    /**
     * Update unread badge in UI
     */
    updateUnreadBadge() {
        const badges = document.querySelectorAll('.notification-badge');
        badges.forEach(badge => {
            if (this.unreadCount > 0) {
                badge.textContent = this.unreadCount;
                badge.style.display = 'block';
            } else {
                badge.style.display = 'none';
            }
        });
    }

    /**
     * Initialize notification UI elements
     */
    initializeNotificationUI() {
        // Create notification dropdown if it doesn't exist
        this.createNotificationDropdown();
        
        // Create toast container if it doesn't exist
        this.createToastContainer();
    }

    /**
     * Create notification dropdown
     */
    createNotificationDropdown() {
        // Check if notification dropdown already exists
        if (document.getElementById('notification-dropdown')) return;

        // Find navbar or create notification area
        const navbar = document.querySelector('.navbar') || document.querySelector('nav') || document.body;
        
        const notificationHTML = `
            <div class="dropdown notification-dropdown" id="notification-dropdown">
                <button class="btn btn-link position-relative" type="button" data-bs-toggle="dropdown">
                    <i class="fas fa-bell fa-lg"></i>
                    <span class="notification-badge position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="display: none;">
                        0
                    </span>
                </button>
                <ul class="dropdown-menu dropdown-menu-end notification-menu" style="width: 350px; max-height: 400px; overflow-y: auto;">
                    <li class="dropdown-header">
                        <div class="d-flex justify-content-between align-items-center">
                            <span>Notifications</span>
                            <button class="btn btn-sm btn-outline-secondary" onclick="notificationSystem.markAllAsRead()">
                                Mark All Read
                            </button>
                        </div>
                    </li>
                    <li><hr class="dropdown-divider"></li>
                    <div id="notifications-list">
                        <li class="dropdown-item-text text-center text-muted">
                            <i class="fas fa-spinner fa-spin"></i> Loading notifications...
                        </li>
                    </div>
                </ul>
            </div>
        `;

        // Insert into navbar
        if (navbar.classList.contains('navbar')) {
            const navbarNav = navbar.querySelector('.navbar-nav') || navbar.querySelector('.nav-links');
            if (navbarNav) {
                navbarNav.insertAdjacentHTML('beforeend', `<li class="nav-item">${notificationHTML}</li>`);
            } else {
                navbar.insertAdjacentHTML('beforeend', notificationHTML);
            }
        } else {
            document.body.insertAdjacentHTML('afterbegin', notificationHTML);
        }
    }

    /**
     * Create toast container
     */
    createToastContainer() {
        if (document.getElementById('toast-container')) return;

        const toastContainer = document.createElement('div');
        toastContainer.id = 'toast-container';
        toastContainer.className = 'toast-container position-fixed top-0 end-0 p-3';
        toastContainer.style.zIndex = '9999';
        document.body.appendChild(toastContainer);
    }

    /**
     * Display notifications in dropdown
     */
    displayNotifications() {
        const notificationsList = document.getElementById('notifications-list');
        if (!notificationsList) return;

        if (this.notifications.length === 0) {
            notificationsList.innerHTML = `
                <li class="dropdown-item-text text-center text-muted">
                    <i class="fas fa-bell-slash"></i><br>
                    No notifications yet
                </li>
            `;
            return;
        }

        notificationsList.innerHTML = this.notifications.map(notification => `
            <li class="dropdown-item notification-item ${notification.notification_status === 'unread' ? 'unread' : ''}" 
                data-notification-id="${notification.notification_id}">
                <div class="notification-content">
                    <div class="d-flex justify-content-between align-items-start">
                        <div class="notification-body">
                            <h6 class="notification-title mb-1">${notification.notification_title}</h6>
                            <p class="notification-message mb-1">${notification.notification_message}</p>
                            <small class="text-muted">
                                ${this.formatNotificationTime(notification.notification_date, notification.notification_time)}
                            </small>
                        </div>
                        ${notification.notification_status === 'unread' ? '<span class="badge bg-primary rounded-pill">New</span>' : ''}
                    </div>
                </div>
            </li>
        `).join('');

        // Add click handlers
        this.addNotificationClickHandlers();
    }

    /**
     * Add click handlers to notifications
     */
    addNotificationClickHandlers() {
        const notificationItems = document.querySelectorAll('.notification-item');
        notificationItems.forEach(item => {
            item.addEventListener('click', () => {
                const notificationId = item.dataset.notificationId;
                this.markAsRead(notificationId);
                this.handleNotificationClick(item.dataset.notificationId);
            });
        });
    }

    /**
     * Handle notification click
     */
    handleNotificationClick(notificationId) {
        const notification = this.notifications.find(n => n.notification_id === notificationId);
        if (!notification) return;

        // Navigate based on notification type
        switch (notification.notification_type) {
            case 'new_job_cart':
                if (this.userType === 'service_provider') {
                    window.location.href = 'service-provider-dashboard.html';
                }
                break;
            case 'new_quotation':
                if (this.userType === 'client') {
                    window.location.href = 'client-waiting-interface.html';
                }
                break;
            case 'booking_status_changed':
                window.location.href = 'cancel-booking.html';
                break;
            case 'quotation_status_changed':
                if (this.userType === 'service_provider') {
                    window.location.href = 'service-provider-dashboard.html';
                }
                break;
            default:
                // Default action - could be dashboard
                window.location.href = 'dashboard.html';
        }
    }

    /**
     * Mark notification as read
     */
    async markAsRead(notificationId) {
        try {
            const { error } = await this.supabase
                .from('notification')
                .update({ notification_status: 'read' })
                .eq('notification_id', notificationId)
                .eq('user_id', this.currentUser.id);

            if (error) throw error;

            // Update local data
            const notification = this.notifications.find(n => n.notification_id === notificationId);
            if (notification && notification.notification_status === 'unread') {
                notification.notification_status = 'read';
                this.decrementUnreadCount();
                this.displayNotifications();
            }

        } catch (error) {
            console.error('❌ Error marking notification as read:', error);
        }
    }

    /**
     * Mark all notifications as read
     */
    async markAllAsRead() {
        try {
            const unreadNotifications = this.notifications.filter(n => n.notification_status === 'unread');
            if (unreadNotifications.length === 0) return;

            const notificationIds = unreadNotifications.map(n => n.notification_id);

            const { error } = await this.supabase
                .from('notification')
                .update({ notification_status: 'read' })
                .in('notification_id', notificationIds)
                .eq('user_id', this.currentUser.id);

            if (error) throw error;

            // Update local data
            unreadNotifications.forEach(notification => {
                notification.notification_status = 'read';
            });

            this.unreadCount = 0;
            this.updateUnreadBadge();
            this.displayNotifications();

        } catch (error) {
            console.error('❌ Error marking all notifications as read:', error);
        }
    }

    /**
     * Show toast notification
     */
    showToastNotification(notification) {
        const toastContainer = document.getElementById('toast-container');
        if (!toastContainer) return;

        const toastId = `toast-${notification.notification_id}`;
        const toastHTML = `
            <div class="toast" id="${toastId}" role="alert" aria-live="assertive" aria-atomic="true">
                <div class="toast-header">
                    <i class="fas fa-bell text-primary me-2"></i>
                    <strong class="me-auto">${notification.notification_title}</strong>
                    <small class="text-muted">now</small>
                    <button type="button" class="btn-close" data-bs-dismiss="toast"></button>
                </div>
                <div class="toast-body">
                    ${notification.notification_message}
                </div>
            </div>
        `;

        toastContainer.insertAdjacentHTML('beforeend', toastHTML);

        // Show toast
        const toastElement = document.getElementById(toastId);
        const toast = new bootstrap.Toast(toastElement, {
            autohide: true,
            delay: 5000
        });
        toast.show();

        // Remove from DOM after hiding
        toastElement.addEventListener('hidden.bs.toast', () => {
            toastElement.remove();
        });
    }

    /**
     * Add notification to UI
     */
    addNotificationToUI(notification) {
        this.notifications.unshift(notification);
        
        // Keep only last 50 notifications
        if (this.notifications.length > 50) {
            this.notifications = this.notifications.slice(0, 50);
        }

        this.displayNotifications();
    }

    /**
     * Format notification time
     */
    formatNotificationTime(date, time) {
        try {
            const notificationDate = new Date(`${date}T${time}`);
            const now = new Date();
            const diffMs = now - notificationDate;
            const diffMins = Math.floor(diffMs / 60000);
            const diffHours = Math.floor(diffMins / 60);
            const diffDays = Math.floor(diffHours / 24);

            if (diffMins < 1) return 'Just now';
            if (diffMins < 60) return `${diffMins}m ago`;
            if (diffHours < 24) return `${diffHours}h ago`;
            if (diffDays < 7) return `${diffDays}d ago`;
            
            return notificationDate.toLocaleDateString();
        } catch (error) {
            return 'Recently';
        }
    }

    /**
     * Register callback for specific events
     */
    on(eventType, callback) {
        this.notificationCallbacks.set(eventType, callback);
    }

    /**
     * Unregister callback
     */
    off(eventType) {
        this.notificationCallbacks.delete(eventType);
    }

    /**
     * Get unread count
     */
    getUnreadCount() {
        return this.unreadCount;
    }

    /**
     * Get all notifications
     */
    getNotifications() {
        return this.notifications || [];
    }

    /**
     * Cleanup subscriptions
     */
    cleanup() {
        this.subscriptions.forEach((subscription, key) => {
            if (subscription && typeof subscription.unsubscribe === 'function') {
                subscription.unsubscribe();
            }
        });
        this.subscriptions.clear();
        this.notificationCallbacks.clear();
        console.log('🧹 Notification System cleaned up');
    }
}

// Global instance
window.notificationSystem = null;

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', async function() {
    // Wait for other services to be available
    setTimeout(async () => {
        if (window.supabase && window.RealtimeService) {
            window.notificationSystem = new NotificationSystem(window.supabase, window.RealtimeService);
            await window.notificationSystem.initialize();
        }
    }, 1000);
});
