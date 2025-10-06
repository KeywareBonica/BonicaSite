// Real-time Service for Bonica Event Management System
class RealtimeService {
    constructor() {
        this.supabase = null;
        this.subscriptions = new Map();
        this.listeners = new Map();
        this.isConnected = false;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.reconnectDelay = 1000;
    }

    // Initialize real-time service
    async initialize(supabaseClient) {
        this.supabase = supabaseClient;
        await this.connect();
        this.setupConnectionMonitoring();
    }

    // Connect to real-time
    async connect() {
        try {
            if (this.supabase) {
                this.isConnected = true;
                console.log('✅ Real-time service connected');
                this.reconnectAttempts = 0;
                this.notifyListeners('connection', { status: 'connected' });
            }
        } catch (error) {
            console.error('❌ Failed to connect to real-time service:', error);
            this.handleConnectionError(error);
        }
    }

    // Setup connection monitoring
    setupConnectionMonitoring() {
        // Monitor connection status
        setInterval(() => {
            if (!this.isConnected && this.reconnectAttempts < this.maxReconnectAttempts) {
                this.reconnect();
            }
        }, 5000);
    }

    // Handle connection errors
    handleConnectionError(error) {
        this.isConnected = false;
        this.notifyListeners('connection', { status: 'disconnected', error });
        
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
            setTimeout(() => this.reconnect(), this.reconnectDelay * this.reconnectAttempts);
        }
    }

    // Reconnect to real-time
    async reconnect() {
        this.reconnectAttempts++;
        console.log(`🔄 Attempting to reconnect (${this.reconnectAttempts}/${this.maxReconnectAttempts})`);
        
        try {
            await this.connect();
            this.resubscribe();
        } catch (error) {
            console.error('❌ Reconnection failed:', error);
        }
    }

    // Resubscribe to all channels
    resubscribe() {
        this.subscriptions.forEach((subscription, table) => {
            this.subscribeToTable(table, subscription.config, subscription.callback);
        });
    }

    // Subscribe to table changes
    subscribeToTable(table, config = {}, callback) {
        if (!this.supabase || !this.isConnected) {
            console.warn('⚠️ Cannot subscribe: Real-time service not connected');
            return null;
        }

        try {
            // Cancel existing subscription if any
            if (this.subscriptions.has(table)) {
                this.subscriptions.get(table).subscription.unsubscribe();
            }

            const subscription = this.supabase
                .channel(`${table}_changes_${Date.now()}`)
                .on('postgres_changes', {
                    event: '*', // Listen to all events (INSERT, UPDATE, DELETE)
                    schema: 'public',
                    table: table,
                    ...config
                }, callback)
                .subscribe((status) => {
                    if (status === 'SUBSCRIBED') {
                        console.log(`✅ Subscribed to ${table} changes`);
                    } else if (status === 'CHANNEL_ERROR') {
                        console.error(`❌ Error subscribing to ${table}`);
                    }
                });

            // Store subscription
            this.subscriptions.set(table, {
                subscription,
                config,
                callback
            });

            return subscription;
        } catch (error) {
            console.error(`❌ Failed to subscribe to ${table}:`, error);
            return null;
        }
    }

    // Subscribe to quotations
    subscribeToQuotations(callback) {
        return this.subscribeToTable('quotation', {}, (payload) => {
            console.log('📄 Quotation update:', payload);
            callback(payload);
        });
    }

    // Subscribe to job carts
    subscribeToJobCarts(callback) {
        return this.subscribeToTable('job_cart', {}, (payload) => {
            console.log('🛒 Job cart update:', payload);
            callback(payload);
        });
    }

    // Subscribe to bookings
    subscribeToBookings(callback) {
        return this.subscribeToTable('booking', {}, (payload) => {
            console.log('📅 Booking update:', payload);
            callback(payload);
        });
    }

    // Subscribe to cancellations
    subscribeToCancellations(callback) {
        return this.subscribeToTable('cancellation', {}, (payload) => {
            console.log('❌ Cancellation update:', payload);
            callback(payload);
        });
    }

    // Subscribe to notifications
    subscribeToNotifications(callback) {
        return this.subscribeToTable('notification', {}, (payload) => {
            console.log('🔔 Notification update:', payload);
            callback(payload);
        });
    }

    // Subscribe to service provider specific events
    subscribeToServiceProviderEvents(serviceProviderId, callback) {
        return this.subscribeToTable('quotation', {
            filter: `service_provider_id=eq.${serviceProviderId}`
        }, callback);
    }

    // Subscribe to client specific events
    subscribeToClientEvents(clientId, callback) {
        return this.subscribeToTable('booking', {
            filter: `client_id=eq.${clientId}`
        }, callback);
    }

    // Add event listener
    addEventListener(event, callback) {
        if (!this.listeners.has(event)) {
            this.listeners.set(event, []);
        }
        this.listeners.get(event).push(callback);
    }

    // Remove event listener
    removeEventListener(event, callback) {
        if (this.listeners.has(event)) {
            const callbacks = this.listeners.get(event);
            const index = callbacks.indexOf(callback);
            if (index > -1) {
                callbacks.splice(index, 1);
            }
        }
    }

    // Notify listeners
    notifyListeners(event, data) {
        if (this.listeners.has(event)) {
            this.listeners.get(event).forEach(callback => {
                try {
                    callback(data);
                } catch (error) {
                    console.error(`❌ Error in event listener for ${event}:`, error);
                }
            });
        }
    }

    // Send real-time notification
    async sendNotification(userId, userType, message, type = 'info') {
        try {
            const { error } = await this.supabase
                .from('notification')
                .insert({
                    user_id: userId,
                    user_type: userType,
                    message: message,
                    notification_type: type,
                    created_at: new Date().toISOString()
                });

            if (error) throw error;
            console.log('📤 Notification sent:', message);
        } catch (error) {
            console.error('❌ Failed to send notification:', error);
        }
    }

    // Broadcast to all users
    async broadcast(message, type = 'info') {
        try {
            // Send to all clients
            const { data: clients } = await this.supabase
                .from('client')
                .select('client_id');

            // Send to all service providers
            const { data: providers } = await this.supabase
                .from('service_provider')
                .select('service_provider_id');

            // Send notifications to all users
            const notifications = [
                ...clients.map(c => ({
                    user_id: c.client_id,
                    user_type: 'client',
                    message: message,
                    notification_type: type,
                    created_at: new Date().toISOString()
                })),
                ...providers.map(p => ({
                    user_id: p.service_provider_id,
                    user_type: 'service_provider',
                    message: message,
                    notification_type: type,
                    created_at: new Date().toISOString()
                }))
            ];

            const { error } = await this.supabase
                .from('notification')
                .insert(notifications);

            if (error) throw error;
            console.log('📢 Broadcast sent:', message);
        } catch (error) {
            console.error('❌ Failed to broadcast:', error);
        }
    }

    // Get connection status
    getStatus() {
        return {
            connected: this.isConnected,
            subscriptions: this.subscriptions.size,
            reconnectAttempts: this.reconnectAttempts
        };
    }

    // Cleanup
    destroy() {
        this.subscriptions.forEach(({ subscription }) => {
            subscription.unsubscribe();
        });
        this.subscriptions.clear();
        this.listeners.clear();
        this.isConnected = false;
        console.log('🧹 Real-time service destroyed');
    }
}

// Export RealtimeService class to window
window.RealtimeService = RealtimeService;

// Notification types
window.NotificationTypes = {
    NEW_QUOTATION: 'new_quotation',
    QUOTATION_ACCEPTED: 'quotation_accepted',
    QUOTATION_REJECTED: 'quotation_rejected',
    NEW_BOOKING: 'new_booking',
    BOOKING_CANCELLED: 'booking_cancelled',
    PAYMENT_RECEIVED: 'payment_received',
    SYSTEM_UPDATE: 'system_update',
    GENERAL: 'general'
};
