/**
 * Job Cart Notification Service
 * Handles real-time notifications when job carts are created
 * Notifies relevant service providers based on service type and location
 */

class JobCartNotificationService {
    constructor(supabase, realtimeService) {
        this.supabase = supabase;
        this.realtimeService = realtimeService;
        this.subscriptions = new Map();
        this.isInitialized = false;
    }

    /**
     * Initialize the notification service
     */
    async initialize() {
        try {
            // Subscribe to job cart creation events
            this.subscribeToJobCartCreation();
            
            // Subscribe to quotation updates
            this.subscribeToQuotationUpdates();
            
            this.isInitialized = true;
            console.log('✅ Job Cart Notification Service initialized');
        } catch (error) {
            console.error('❌ Failed to initialize Job Cart Notification Service:', error);
        }
    }

    /**
     * Subscribe to job cart creation events
     */
    subscribeToJobCartCreation() {
        const subscription = this.realtimeService.subscribeToTable('job_cart', {
            event: 'INSERT'
        }, async (payload) => {
            console.log('🛒 New job cart created:', payload);
            await this.handleNewJobCart(payload.new);
        });

        this.subscriptions.set('job_cart_creation', subscription);
    }

    /**
     * Subscribe to quotation updates
     */
    subscribeToQuotationUpdates() {
        const subscription = this.realtimeService.subscribeToTable('quotation', {
            event: 'INSERT'
        }, async (payload) => {
            console.log('📄 New quotation submitted:', payload);
            await this.handleNewQuotation(payload.new);
        });

        this.subscriptions.set('quotation_updates', subscription);
    }

    /**
     * Handle new job cart creation
     * @param {Object} jobCart - The new job cart data
     */
    async handleNewJobCart(jobCart) {
        try {
            // Get job cart details with event and service information
            const { data: jobCartDetails, error } = await this.supabase
                .from('job_cart')
                .select(`
                    *,
                    event:event_id (
                        event_name,
                        event_date,
                        event_location,
                        event_service!inner (
                            service_id
                        )
                    )
                `)
                .eq('job_cart_id', jobCart.job_cart_id)
                .single();

            if (error) throw error;

            // Find service providers who can handle this service type
            const { data: serviceProviders, error: providerError } = await this.supabase
                .from('service_provider')
                .select(`
                    service_provider_id,
                    service_provider_name,
                    service_provider_surname,
                    service_provider_email,
                    service_provider_location,
                    service_id
                `)
                .eq('service_id', jobCartDetails.event.event_service.service_id);

            if (providerError) throw providerError;

            // Send notifications to relevant service providers
            await this.notifyServiceProviders(jobCartDetails, serviceProviders);

            // Create notification for the client
            await this.notifyClient(jobCartDetails);

        } catch (error) {
            console.error('❌ Error handling new job cart:', error);
        }
    }

    /**
     * Handle new quotation submission
     * @param {Object} quotation - The new quotation data
     */
    async handleNewQuotation(quotation) {
        try {
            // Get quotation details with job cart and client information
            const { data: quotationDetails, error } = await this.supabase
                .from('quotation')
                .select(`
                    *,
                    service_provider:service_provider_id (
                        service_provider_name,
                        service_provider_surname
                    ),
                    job_cart:job_cart_id (
                        event:event_id (
                            client_id
                        )
                    )
                `)
                .eq('quotation_id', quotation.quotation_id)
                .single();

            if (error) throw error;

            // Notify the client about the new quotation
            await this.notifyClientNewQuotation(quotationDetails);

        } catch (error) {
            console.error('❌ Error handling new quotation:', error);
        }
    }

    /**
     * Notify service providers about new job cart
     * @param {Object} jobCartDetails - Job cart details
     * @param {Array} serviceProviders - Array of relevant service providers
     */
    async notifyServiceProviders(jobCartDetails, serviceProviders) {
        try {
            const notifications = serviceProviders.map(provider => ({
                service_provider_id: provider.service_provider_id,
                notification_type: 'new_job_cart',
                notification_title: 'New Job Available',
                notification_message: `New ${jobCartDetails.job_cart_item} job for ${jobCartDetails.event.event_name} on ${jobCartDetails.event.event_date}`,
                notification_data: {
                    job_cart_id: jobCartDetails.job_cart_id,
                    event_name: jobCartDetails.event.event_name,
                    event_date: jobCartDetails.event.event_date,
                    event_location: jobCartDetails.event.event_location,
                    job_cart_item: jobCartDetails.job_cart_item
                },
                created_at: new Date().toISOString()
            }));

            // Insert notifications
            const { error } = await this.supabase
                .from('notification')
                .insert(notifications);

            if (error) throw error;

            console.log(`📤 Notified ${serviceProviders.length} service providers about job cart ${jobCartDetails.job_cart_id}`);

            // Send real-time updates
            serviceProviders.forEach(provider => {
                this.realtimeService.notifyListeners('new_job_cart', {
                    provider_id: provider.service_provider_id,
                    job_cart: jobCartDetails
                });
            });

        } catch (error) {
            console.error('❌ Error notifying service providers:', error);
        }
    }

    /**
     * Notify client about job cart creation
     * @param {Object} jobCartDetails - Job cart details
     */
    async notifyClient(jobCartDetails) {
        try {
            const notification = {
                client_id: jobCartDetails.event.client_id,
                notification_type: 'job_cart_created',
                notification_title: 'Job Cart Created',
                notification_message: `Your ${jobCartDetails.job_cart_item} request has been sent to service providers. You'll receive quotations soon.`,
                notification_data: {
                    job_cart_id: jobCartDetails.job_cart_id,
                    job_cart_item: jobCartDetails.job_cart_item
                },
                created_at: new Date().toISOString()
            };

            const { error } = await this.supabase
                .from('notification')
                .insert(notification);

            if (error) throw error;

            console.log(`📤 Notified client about job cart creation`);

        } catch (error) {
            console.error('❌ Error notifying client:', error);
        }
    }

    /**
     * Notify client about new quotation
     * @param {Object} quotationDetails - Quotation details
     */
    async notifyClientNewQuotation(quotationDetails) {
        try {
            const notification = {
                client_id: quotationDetails.job_cart.event.client_id,
                notification_type: 'new_quotation',
                notification_title: 'New Quotation Received',
                notification_message: `You have received a new quotation from ${quotationDetails.service_provider.service_provider_name} ${quotationDetails.service_provider.service_provider_surname}`,
                notification_data: {
                    quotation_id: quotationDetails.quotation_id,
                    service_provider_name: `${quotationDetails.service_provider.service_provider_name} ${quotationDetails.service_provider.service_provider_surname}`,
                    quotation_price: quotationDetails.quotation_price
                },
                created_at: new Date().toISOString()
            };

            const { error } = await this.supabase
                .from('notification')
                .insert(notification);

            if (error) throw error;

            console.log(`📤 Notified client about new quotation from ${quotationDetails.service_provider.service_provider_name}`);

            // Send real-time update to client
            this.realtimeService.notifyListeners('new_quotation', {
                client_id: quotationDetails.job_cart.event.client_id,
                quotation: quotationDetails
            });

        } catch (error) {
            console.error('❌ Error notifying client about new quotation:', error);
        }
    }

    /**
     * Get notifications for a user
     * @param {string} userId - User ID
     * @param {string} userType - 'client' or 'service_provider'
     * @returns {Promise<Array>} Array of notifications
     */
    async getUserNotifications(userId, userType) {
        try {
            const { data: notifications, error } = await this.supabase
                .from('notification')
                .select('*')
                .eq(`${userType}_id`, userId)
                .order('created_at', { ascending: false })
                .limit(20);

            if (error) throw error;
            return notifications || [];

        } catch (error) {
            console.error('❌ Error fetching user notifications:', error);
            return [];
        }
    }

    /**
     * Mark notification as read
     * @param {string} notificationId - Notification ID
     */
    async markNotificationAsRead(notificationId) {
        try {
            const { error } = await this.supabase
                .from('notification')
                .update({ notification_read: true, read_at: new Date().toISOString() })
                .eq('notification_id', notificationId);

            if (error) throw error;

        } catch (error) {
            console.error('❌ Error marking notification as read:', error);
        }
    }

    /**
     * Get service providers for a specific service type
     * @param {string} serviceId - Service ID
     * @param {string} location - Optional location filter
     * @returns {Promise<Array>} Array of service providers
     */
    async getServiceProvidersForService(serviceId, location = null) {
        try {
            let query = this.supabase
                .from('service_provider')
                .select(`
                    service_provider_id,
                    service_provider_name,
                    service_provider_surname,
                    service_provider_email,
                    service_provider_location,
                    service_provider_rating,
                    service_id
                `)
                .eq('service_id', serviceId);

            if (location) {
                query = query.ilike('service_provider_location', `%${location}%`);
            }

            const { data: providers, error } = await query;

            if (error) throw error;
            return providers || [];

        } catch (error) {
            console.error('❌ Error fetching service providers:', error);
            return [];
        }
    }

    /**
     * Cleanup subscriptions
     */
    destroy() {
        this.subscriptions.forEach((subscription, key) => {
            if (subscription && subscription.unsubscribe) {
                subscription.unsubscribe();
            }
        });
        this.subscriptions.clear();
        this.isInitialized = false;
        console.log('🧹 Job Cart Notification Service destroyed');
    }
}

// Export for use in other modules
window.JobCartNotificationService = JobCartNotificationService;
