/**
 * Real-time Database Synchronization System
 * Handles real-time updates across all tables for the booking system
 */

class RealtimeDatabaseSync {
    constructor(supabaseClient) {
        this.supabase = supabaseClient;
        this.channels = new Map();
        this.callbacks = new Map();
        this.isInitialized = false;
        this.userType = null; // 'client' or 'service_provider'
        this.userId = null;
    }

    /**
     * Initialize the real-time database sync system
     */
    async initialize(userType, userId, serviceType = null) {
        try {
            this.userType = userType;
            this.userId = userId;
            this.serviceType = serviceType;

            // Set up subscriptions for all relevant tables
            await this.setupTableSubscriptions();
            
            this.isInitialized = true;
            console.log(`RealtimeDatabaseSync initialized for ${userType}:`, userId);
            
            return true;
        } catch (error) {
            console.error('Failed to initialize RealtimeDatabaseSync:', error);
            return false;
        }
    }

    /**
     * Set up real-time subscriptions for all relevant tables
     */
    async setupTableSubscriptions() {
        const tables = [
            'job_cart',
            'quotation', 
            'booking',
            'event',
            'notification'
        ];

        for (const table of tables) {
            await this.setupTableSubscription(table);
        }
    }

    /**
     * Set up subscription for a specific table
     */
    async setupTableSubscription(tableName) {
        try {
            const channel = this.supabase
                .channel(`${tableName}-changes`)
                .on('postgres_changes', 
                    { 
                        event: '*', 
                        schema: 'public', 
                        table: tableName 
                    }, 
                    (payload) => {
                        this.handleTableChange(tableName, payload);
                    }
                )
                .subscribe();

            this.channels.set(tableName, channel);
            console.log(`Subscription established for ${tableName}`);
        } catch (error) {
            console.error(`Failed to set up subscription for ${tableName}:`, error);
        }
    }

    /**
     * Handle changes from any table
     */
    handleTableChange(tableName, payload) {
        const { eventType, new: newRecord, old: oldRecord } = payload;
        
        console.log(`${tableName} change detected:`, { eventType, newRecord, oldRecord });

        // Filter records based on user type and relevance
        if (this.isRecordRelevant(tableName, newRecord || oldRecord)) {
            this.notifyCallbacks(tableName, {
                table: tableName,
                eventType,
                newRecord,
                oldRecord,
                timestamp: new Date()
            });
        }
    }

    /**
     * Check if a record is relevant to the current user
     */
    isRecordRelevant(tableName, record) {
        if (!record) return false;

        switch (tableName) {
            case 'job_cart':
                return this.isJobCartRelevant(record);
            case 'quotation':
                return this.isQuotationRelevant(record);
            case 'booking':
                return this.isBookingRelevant(record);
            case 'event':
                return this.isEventRelevant(record);
            case 'notification':
                return this.isNotificationRelevant(record);
            default:
                return true; // For other tables, show all changes
        }
    }

    /**
     * Check if job cart is relevant
     */
    async isJobCartRelevant(jobCart) {
        if (this.userType === 'client') {
            return jobCart.client_id === this.userId;
        } else if (this.userType === 'service_provider') {
            // Check if the service matches the service provider's type
            return await this.checkServiceMatch(jobCart.service_id);
        }
        return false;
    }

    /**
     * Check if quotation is relevant
     */
    async isQuotationRelevant(quotation) {
        if (this.userType === 'client') {
            // Get the job cart to check if it belongs to this client
            const jobCart = await this.getJobCartById(quotation.job_cart_id);
            return jobCart && jobCart.client_id === this.userId;
        } else if (this.userType === 'service_provider') {
            return quotation.service_provider_id === this.userId;
        }
        return false;
    }

    /**
     * Check if booking is relevant
     */
    async isBookingRelevant(booking) {
        if (this.userType === 'client') {
            return booking.client_id === this.userId;
        } else if (this.userType === 'service_provider') {
            // Check if this service provider has quotations for this booking
            return await this.checkBookingRelevance(booking.booking_id);
        }
        return false;
    }

    /**
     * Check if event is relevant
     */
    async isEventRelevant(event) {
        if (this.userType === 'client') {
            // Check if client has bookings for this event
            return await this.checkEventRelevance(event.event_id, 'client');
        } else if (this.userType === 'service_provider') {
            // Check if service provider has quotations for this event
            return await this.checkEventRelevance(event.event_id, 'service_provider');
        }
        return false;
    }

    /**
     * Check if notification is relevant
     */
    isNotificationRelevant(notification) {
        return notification.user_id === this.userId && notification.user_type === this.userType;
    }

    /**
     * Check if service matches service provider's type
     */
    async checkServiceMatch(serviceId) {
        try {
            const { data, error } = await this.supabase
                .from('service')
                .select('service_type')
                .eq('service_id', serviceId)
                .single();

            if (error || !data) return false;

            return data.service_type && 
                   data.service_type.toLowerCase().includes(this.serviceType.toLowerCase());
        } catch (error) {
            console.error('Error checking service match:', error);
            return false;
        }
    }

    /**
     * Get job cart by ID
     */
    async getJobCartById(jobCartId) {
        try {
            const { data, error } = await this.supabase
                .from('job_cart')
                .select('*')
                .eq('job_cart_id', jobCartId)
                .single();

            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Error getting job cart:', error);
            return null;
        }
    }

    /**
     * Check if booking is relevant to service provider
     */
    async checkBookingRelevance(bookingId) {
        try {
            const { data, error } = await this.supabase
                .from('quotation')
                .select('quotation_id')
                .eq('booking_id', bookingId)
                .eq('service_provider_id', this.userId)
                .limit(1);

            if (error) throw error;
            return data && data.length > 0;
        } catch (error) {
            console.error('Error checking booking relevance:', error);
            return false;
        }
    }

    /**
     * Check if event is relevant to user
     */
    async checkEventRelevance(eventId, userType) {
        try {
            if (userType === 'client') {
                const { data, error } = await this.supabase
                    .from('booking')
                    .select('booking_id')
                    .eq('event_id', eventId)
                    .eq('client_id', this.userId)
                    .limit(1);

                if (error) throw error;
                return data && data.length > 0;
            } else if (userType === 'service_provider') {
                const { data, error } = await this.supabase
                    .from('quotation')
                    .select('quotation_id')
                    .eq('event_id', eventId)
                    .eq('service_provider_id', this.userId)
                    .limit(1);

                if (error) throw error;
                return data && data.length > 0;
            }
            return false;
        } catch (error) {
            console.error('Error checking event relevance:', error);
            return false;
        }
    }

    /**
     * Subscribe to changes for a specific table
     */
    onTableChange(tableName, callback) {
        if (!this.callbacks.has(tableName)) {
            this.callbacks.set(tableName, []);
        }
        this.callbacks.get(tableName).push(callback);
    }

    /**
     * Notify callbacks for a table change
     */
    notifyCallbacks(tableName, changeData) {
        const callbacks = this.callbacks.get(tableName) || [];
        callbacks.forEach(callback => {
            try {
                callback(changeData);
            } catch (error) {
                console.error(`Error in callback for ${tableName}:`, error);
            }
        });
    }

    /**
     * Create a job cart (client side)
     */
    async createJobCart(jobCartData) {
        try {
            const { data, error } = await this.supabase
                .from('job_cart')
                .insert({
                    client_id: this.userId,
                    service_id: jobCartData.serviceId,
                    event_id: jobCartData.eventId,
                    job_cart_status: 'pending',
                    job_cart_created_date: new Date().toISOString().split('T')[0],
                    job_cart_created_time: new Date().toTimeString().split(' ')[0]
                })
                .select();

            if (error) throw error;

            console.log('Job cart created:', data);
            return { success: true, data };
        } catch (error) {
            console.error('Error creating job cart:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Accept a job cart (service provider side)
     */
    async acceptJobCart(jobCartId) {
        try {
            const { data, error } = await this.supabase
                .from('job_cart')
                .update({ 
                    job_cart_status: 'accepted',
                    updated_at: new Date().toISOString()
                })
                .eq('job_cart_id', jobCartId)
                .select();

            if (error) throw error;

            // Create notification for client
            await this.createNotification(
                'Job Accepted',
                'A service provider has accepted your job request',
                'success',
                'client'
            );

            console.log('Job cart accepted:', data);
            return { success: true, data };
        } catch (error) {
            console.error('Error accepting job cart:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Reject a job cart (service provider side)
     */
    async rejectJobCart(jobCartId) {
        try {
            const { data, error } = await this.supabase
                .from('job_cart')
                .update({ 
                    job_cart_status: 'rejected',
                    updated_at: new Date().toISOString()
                })
                .eq('job_cart_id', jobCartId)
                .select();

            if (error) throw error;

            // Create notification for client
            await this.createNotification(
                'Job Rejected',
                'A service provider has declined your job request',
                'info',
                'client'
            );

            console.log('Job cart rejected:', data);
            return { success: true, data };
        } catch (error) {
            console.error('Error rejecting job cart:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Upload quotation (service provider side)
     */
    async uploadQuotation(quotationData) {
        try {
            const quotation = {
                service_provider_id: this.userId,
                job_cart_id: quotationData.jobCartId,
                quotation_price: quotationData.price,
                quotation_details: quotationData.details,
                quotation_file_path: quotationData.filePath || `/quotations/${this.generateQuotationFileName(quotationData.jobCartId)}`,
                quotation_file_name: quotationData.fileName || this.generateQuotationFileName(quotationData.jobCartId),
                quotation_submission_date: new Date().toISOString().split('T')[0],
                quotation_submission_time: new Date().toTimeString().split(' ')[0],
                quotation_status: 'submitted',
                event_id: quotationData.eventId,
                booking_id: quotationData.bookingId
            };

            const { data, error } = await this.supabase
                .from('quotation')
                .insert(quotation)
                .select();

            if (error) throw error;

            // Create notification for client
            await this.createNotification(
                'New Quotation Available',
                'A service provider has submitted a quotation for your job',
                'info',
                'client'
            );

            console.log('Quotation uploaded:', data);
            return { success: true, data };
        } catch (error) {
            console.error('Error uploading quotation:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Accept quotation (client side)
     */
    async acceptQuotation(quotationId) {
        try {
            const { data, error } = await this.supabase
                .from('quotation')
                .update({ 
                    quotation_status: 'accepted',
                    updated_at: new Date().toISOString()
                })
                .eq('quotation_id', quotationId)
                .select();

            if (error) throw error;

            // Create notification for service provider
            await this.createNotification(
                'Quotation Accepted',
                'Your quotation has been accepted by the client',
                'success',
                'service_provider'
            );

            console.log('Quotation accepted:', data);
            return { success: true, data };
        } catch (error) {
            console.error('Error accepting quotation:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Create notification
     */
    async createNotification(title, message, type, targetUserType) {
        try {
            // Get the target user ID based on the quotation or job cart
            let targetUserId = null;
            
            if (targetUserType === 'client') {
                // Find client from job cart
                const { data: jobCart } = await this.supabase
                    .from('job_cart')
                    .select('client_id')
                    .eq('job_cart_id', this.currentJobCartId)
                    .single();
                targetUserId = jobCart?.client_id;
            } else if (targetUserType === 'service_provider') {
                // Find service provider from quotation
                const { data: quotation } = await this.supabase
                    .from('quotation')
                    .select('service_provider_id')
                    .eq('quotation_id', this.currentQuotationId)
                    .single();
                targetUserId = quotation?.service_provider_id;
            }

            if (!targetUserId) return;

            const { error } = await this.supabase
                .from('notification')
                .insert({
                    user_id: targetUserId,
                    user_type: targetUserType,
                    title,
                    message,
                    type,
                    is_read: false
                });

            if (error) throw error;
        } catch (error) {
            console.error('Error creating notification:', error);
        }
    }

    /**
     * Get job carts for service provider
     */
    async getJobCartsForServiceProvider() {
        try {
            // First get the service IDs that match this service provider's type
            const { data: services, error: serviceError } = await this.supabase
                .from('service')
                .select('service_id, service_name, service_type')
                .ilike('service_type', `%${this.serviceType}%`);

            if (serviceError) throw serviceError;

            if (!services || services.length === 0) {
                return { success: true, data: [] };
            }

            const serviceIds = services.map(s => s.service_id);

            // Get job carts for these services
            const { data: jobCarts, error: jobCartError } = await this.supabase
                .from('job_cart')
                .select(`
                    *,
                    service:service_id(service_name, service_type),
                    event:event_id(event_type, event_date, event_location),
                    client:client_id(client_name, client_surname, client_email, client_contact)
                `)
                .in('service_id', serviceIds)
                .order('created_at', { ascending: false });

            if (jobCartError) throw jobCartError;

            return { success: true, data: jobCarts || [] };
        } catch (error) {
            console.error('Error getting job carts for service provider:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Get quotations for service provider
     */
    async getQuotationsForServiceProvider() {
        try {
            const { data: quotations, error } = await this.supabase
                .from('quotation')
                .select(`
                    *,
                    job_cart:job_cart_id(
                        service:service_id(service_name, service_type),
                        event:event_id(event_type, event_date, event_location),
                        client:client_id(client_name, client_surname)
                    )
                `)
                .eq('service_provider_id', this.userId)
                .order('created_at', { ascending: false });

            if (error) throw error;

            return { success: true, data: quotations || [] };
        } catch (error) {
            console.error('Error getting quotations for service provider:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Generate quotation file name
     */
    generateQuotationFileName(jobCartId) {
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        return `quotation_${jobCartId}_${timestamp}.pdf`;
    }

    /**
     * Clean up all subscriptions
     */
    async cleanup() {
        try {
            for (const [tableName, channel] of this.channels) {
                await this.supabase.removeChannel(channel);
            }
            this.channels.clear();
            this.callbacks.clear();
            this.isInitialized = false;
            console.log('RealtimeDatabaseSync cleaned up');
        } catch (error) {
            console.error('Error cleaning up RealtimeDatabaseSync:', error);
        }
    }
}

// Export for use in other files
window.RealtimeDatabaseSync = RealtimeDatabaseSync;
