/**
 * Real-time Job Cart Management System
 * Handles real-time updates for job carts and quotations between clients and service providers
 */

class RealtimeJobCartManager {
    constructor(supabaseClient) {
        this.supabase = supabaseClient;
        this.channel = null;
        this.isInitialized = false;
        this.currentServiceProvider = null;
        this.jobCartCallbacks = [];
        this.quotationCallbacks = [];
    }

    /**
     * Initialize the real-time job cart system
     */
    async initialize(serviceProviderId, serviceType) {
        try {
            this.currentServiceProvider = {
                id: serviceProviderId,
                serviceType: serviceType
            };

            // Set up real-time subscriptions
            await this.setupJobCartSubscription();
            await this.setupQuotationSubscription();
            
            this.isInitialized = true;
            console.log('RealtimeJobCartManager initialized for service provider:', serviceProviderId);
            
            return true;
        } catch (error) {
            console.error('Failed to initialize RealtimeJobCartManager:', error);
            return false;
        }
    }

    /**
     * Set up real-time subscription for job cart changes
     */
    async setupJobCartSubscription() {
        if (!this.supabase) {
            console.error('Supabase client not available');
            return;
        }

        try {
            this.channel = this.supabase
                .channel('job-cart-changes')
                .on('postgres_changes', 
                    { 
                        event: '*', 
                        schema: 'public', 
                        table: 'job_cart' 
                    }, 
                    (payload) => {
                        console.log('Job cart change detected:', payload);
                        this.handleJobCartChange(payload);
                    }
                )
                .subscribe();

            console.log('Job cart subscription established');
        } catch (error) {
            console.error('Failed to set up job cart subscription:', error);
        }
    }

    /**
     * Set up real-time subscription for quotation changes
     */
    async setupQuotationSubscription() {
        if (!this.supabase) {
            console.error('Supabase client not available');
            return;
        }

        try {
            const quotationChannel = this.supabase
                .channel('quotation-changes')
                .on('postgres_changes', 
                    { 
                        event: '*', 
                        schema: 'public', 
                        table: 'quotation' 
                    }, 
                    (payload) => {
                        console.log('Quotation change detected:', payload);
                        this.handleQuotationChange(payload);
                    }
                )
                .subscribe();

            console.log('Quotation subscription established');
        } catch (error) {
            console.error('Failed to set up quotation subscription:', error);
        }
    }

    /**
     * Handle job cart changes
     */
    handleJobCartChange(payload) {
        const { eventType, new: newRecord, old: oldRecord } = payload;
        
        // Only process job carts relevant to this service provider
        if (this.isJobCartRelevant(newRecord || oldRecord)) {
            this.jobCartCallbacks.forEach(callback => {
                callback({
                    eventType,
                    newRecord,
                    oldRecord,
                    timestamp: new Date()
                });
            });
        }
    }

    /**
     * Handle quotation changes
     */
    handleQuotationChange(payload) {
        const { eventType, new: newRecord, old: oldRecord } = payload;
        
        // Only process quotations relevant to this service provider
        if (this.isQuotationRelevant(newRecord || oldRecord)) {
            this.quotationCallbacks.forEach(callback => {
                callback({
                    eventType,
                    newRecord,
                    oldRecord,
                    timestamp: new Date()
                });
            });
        }
    }

    /**
     * Check if a job cart is relevant to this service provider
     */
    isJobCartRelevant(jobCart) {
        if (!jobCart || !this.currentServiceProvider) return false;
        
        // Get the service type for this job cart
        return this.getServiceTypeForJobCart(jobCart.service_id)
            .then(serviceType => {
                return serviceType && serviceType.toLowerCase() === this.currentServiceProvider.serviceType.toLowerCase();
            })
            .catch(() => false);
    }

    /**
     * Check if a quotation is relevant to this service provider
     */
    isQuotationRelevant(quotation) {
        if (!quotation || !this.currentServiceProvider) return false;
        
        return quotation.service_provider_id === this.currentServiceProvider.id;
    }

    /**
     * Get service type for a job cart
     */
    async getServiceTypeForJobCart(serviceId) {
        try {
            const { data, error } = await this.supabase
                .from('service')
                .select('service_type')
                .eq('service_id', serviceId)
                .single();

            if (error) throw error;
            return data?.service_type;
        } catch (error) {
            console.error('Error getting service type:', error);
            return null;
        }
    }

    /**
     * Accept a job cart (change status to 'accepted')
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

            console.log('Job cart accepted:', data);
            return { success: true, data };
        } catch (error) {
            console.error('Error accepting job cart:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Reject a job cart (change status to 'rejected')
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

            console.log('Job cart rejected:', data);
            return { success: true, data };
        } catch (error) {
            console.error('Error rejecting job cart:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Upload a quotation for a job cart
     */
    async uploadQuotation(jobCartId, quotationData) {
        try {
            const quotation = {
                service_provider_id: this.currentServiceProvider.id,
                job_cart_id: jobCartId,
                quotation_price: quotationData.price,
                quotation_details: quotationData.details,
                quotation_file_path: quotationData.filePath || `/quotations/${this.generateQuotationFileName(jobCartId)}`,
                quotation_file_name: quotationData.fileName || this.generateQuotationFileName(jobCartId),
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

            console.log('Quotation uploaded:', data);
            return { success: true, data };
        } catch (error) {
            console.error('Error uploading quotation:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Generate a quotation file name
     */
    generateQuotationFileName(jobCartId) {
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        return `quotation_${jobCartId}_${timestamp}.pdf`;
    }

    /**
     * Get job carts for this service provider
     */
    async getJobCartsForServiceProvider() {
        try {
            // First get the service IDs that match this service provider's type
            const { data: services, error: serviceError } = await this.supabase
                .from('service')
                .select('service_id, service_name, service_type')
                .ilike('service_type', `%${this.currentServiceProvider.serviceType}%`);

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
            console.error('Error getting job carts:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Get quotations for this service provider
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
                .eq('service_provider_id', this.currentServiceProvider.id)
                .order('created_at', { ascending: false });

            if (error) throw error;

            return { success: true, data: quotations || [] };
        } catch (error) {
            console.error('Error getting quotations:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Subscribe to job cart changes
     */
    onJobCartChange(callback) {
        this.jobCartCallbacks.push(callback);
    }

    /**
     * Subscribe to quotation changes
     */
    onQuotationChange(callback) {
        this.quotationCallbacks.push(callback);
    }

    /**
     * Clean up subscriptions
     */
    async cleanup() {
        try {
            if (this.channel) {
                await this.supabase.removeChannel(this.channel);
            }
            this.jobCartCallbacks = [];
            this.quotationCallbacks = [];
            this.isInitialized = false;
            console.log('RealtimeJobCartManager cleaned up');
        } catch (error) {
            console.error('Error cleaning up RealtimeJobCartManager:', error);
        }
    }
}

// Export for use in other files
window.RealtimeJobCartManager = RealtimeJobCartManager;

