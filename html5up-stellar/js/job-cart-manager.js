/**
 * Job Cart Manager - Handles concurrent access and job cart acceptance
 * Provides safe concurrent access control for multiple service providers
 */

class JobCartManager {
    constructor(supabase) {
        this.supabase = supabase;
        this.pendingOperations = new Map(); // Track pending operations to prevent duplicates
    }

    /**
     * Accept a job cart with concurrent access control
     * @param {string} jobCartId - The job cart ID
     * @param {string} serviceProviderId - The service provider ID
     * @returns {Promise<Object>} - Result object with success status and message
     */
    async acceptJobCart(jobCartId, serviceProviderId) {
        const operationKey = `${jobCartId}-${serviceProviderId}-accept`;
        
        // Prevent duplicate operations
        if (this.pendingOperations.has(operationKey)) {
            return {
                success: false,
                message: 'Operation already in progress'
            };
        }

        this.pendingOperations.set(operationKey, true);

        try {
            // Use the database function for concurrent-safe acceptance
            const { data, error } = await this.supabase.rpc('accept_job_cart_concurrent', {
                p_job_cart_id: jobCartId,
                p_service_provider_id: serviceProviderId
            });

            if (error) throw error;

            const result = data;
            
            if (result.success) {
                // Emit real-time event for other service providers
                await this.notifyJobCartAccepted(jobCartId, serviceProviderId);
            }

            return result;
        } catch (error) {
            console.error('Error accepting job cart:', error);
            return {
                success: false,
                message: error.message || 'Failed to accept job cart'
            };
        } finally {
            this.pendingOperations.delete(operationKey);
        }
    }

    /**
     * Decline a job cart with concurrent access control
     * @param {string} jobCartId - The job cart ID
     * @param {string} serviceProviderId - The service provider ID
     * @returns {Promise<Object>} - Result object with success status and message
     */
    async declineJobCart(jobCartId, serviceProviderId) {
        const operationKey = `${jobCartId}-${serviceProviderId}-decline`;
        
        // Prevent duplicate operations
        if (this.pendingOperations.has(operationKey)) {
            return {
                success: false,
                message: 'Operation already in progress'
            };
        }

        this.pendingOperations.set(operationKey, true);

        try {
            // Use the database function for concurrent-safe decline
            const { data, error } = await this.supabase.rpc('decline_job_cart_concurrent', {
                p_job_cart_id: jobCartId,
                p_service_provider_id: serviceProviderId
            });

            if (error) throw error;

            const result = data;
            
            if (result.success) {
                // Emit real-time event for other service providers
                await this.notifyJobCartDeclined(jobCartId, serviceProviderId);
            }

            return result;
        } catch (error) {
            console.error('Error declining job cart:', error);
            return {
                success: false,
                message: error.message || 'Failed to decline job cart'
            };
        } finally {
            this.pendingOperations.delete(operationKey);
        }
    }

    /**
     * Get job carts available for a service provider
     * @param {string} serviceProviderId - The service provider ID
     * @param {string} location - Optional location filter
     * @returns {Promise<Array>} - Array of available job carts
     */
    async getAvailableJobCarts(serviceProviderId, location = null) {
        try {
            let query = this.supabase
                .from('job_cart')
                .select(`
                    job_cart_id,
                    job_cart_item,
                    job_cart_details,
                    job_cart_created_date,
                    job_cart_created_time,
                    job_cart_status,
                    event:event_id (
                        event_id,
                        event_name,
                        event_date,
                        event_location,
                        event_start_time,
                        event_end_time
                    ),
                    acceptance:job_cart_acceptance!left (
                        acceptance_id,
                        acceptance_status,
                        accepted_at,
                        declined_at
                    )
                `)
                .eq('job_cart_status', 'available')
                .is('acceptance.acceptance_id', null); // Only show job carts not yet processed by this provider

            if (location) {
                query = query.ilike('event.event_location', `%${location}%`);
            }

            const { data, error } = await query;

            if (error) throw error;

            // Filter out job carts already accepted/declined by this provider
            return data.filter(jobCart => 
                !jobCart.acceptance || 
                jobCart.acceptance.length === 0 ||
                !jobCart.acceptance.some(acc => acc.service_provider_id === serviceProviderId)
            );
        } catch (error) {
            console.error('Error fetching available job carts:', error);
            return [];
        }
    }

    /**
     * Get accepted job carts for a service provider
     * @param {string} serviceProviderId - The service provider ID
     * @returns {Promise<Array>} - Array of accepted job carts
     */
    async getAcceptedJobCarts(serviceProviderId) {
        try {
            const { data, error } = await this.supabase
                .from('job_cart_acceptance')
                .select(`
                    acceptance_id,
                    acceptance_status,
                    accepted_at,
                    job_cart:job_cart_id (
                        job_cart_id,
                        job_cart_item,
                        job_cart_details,
                        job_cart_status,
                        event:event_id (
                            event_id,
                            event_name,
                            event_date,
                            event_location,
                            event_start_time,
                            event_end_time
                        )
                    )
                `)
                .eq('service_provider_id', serviceProviderId)
                .eq('acceptance_status', 'accepted')
                .order('accepted_at', { ascending: false });

            if (error) throw error;

            return data.map(item => ({
                acceptance_id: item.acceptance_id,
                accepted_at: item.accepted_at,
                ...item.job_cart
            }));
        } catch (error) {
            console.error('Error fetching accepted job carts:', error);
            return [];
        }
    }

    /**
     * Check if a service provider can upload quotation for a job cart
     * @param {string} jobCartId - The job cart ID
     * @param {string} serviceProviderId - The service provider ID
     * @returns {Promise<Object>} - Result object with can_upload and message
     */
    async canUploadQuotation(jobCartId, serviceProviderId) {
        try {
            const { data, error } = await this.supabase
                .from('job_cart_acceptance')
                .select('acceptance_status')
                .eq('job_cart_id', jobCartId)
                .eq('service_provider_id', serviceProviderId)
                .single();

            if (error) {
                if (error.code === 'PGRST116') { // No rows returned
                    return {
                        can_upload: false,
                        message: 'You must accept the job cart before uploading a quotation'
                    };
                }
                throw error;
            }

            if (data.acceptance_status !== 'accepted') {
                return {
                    can_upload: false,
                    message: 'Job cart must be accepted before uploading quotation'
                };
            }

            return {
                can_upload: true,
                message: 'Job cart accepted, quotation upload allowed'
            };
        } catch (error) {
            console.error('Error checking quotation upload permission:', error);
            return {
                can_upload: false,
                message: 'Error verifying job cart status'
            };
        }
    }

    /**
     * Notify other service providers that a job cart was accepted
     * @param {string} jobCartId - The job cart ID
     * @param {string} serviceProviderId - The service provider ID
     */
    async notifyJobCartAccepted(jobCartId, serviceProviderId) {
        try {
            // Update real-time subscriptions
            await this.supabase
                .from('job_cart')
                .update({ job_cart_status: 'in_progress' })
                .eq('job_cart_id', jobCartId);

            // Create notification for other service providers
            const { data: otherProviders, error } = await this.supabase
                .from('service_provider')
                .select('service_provider_id')
                .neq('service_provider_id', serviceProviderId);

            if (error) throw error;

            // Insert notifications (if you have a notifications table)
            // This would be implemented based on your notification system
            console.log(`Job cart ${jobCartId} accepted by provider ${serviceProviderId}`);
        } catch (error) {
            console.error('Error notifying job cart acceptance:', error);
        }
    }

    /**
     * Notify other service providers that a job cart was declined
     * @param {string} jobCartId - The job cart ID
     * @param {string} serviceProviderId - The service provider ID
     */
    async notifyJobCartDeclined(jobCartId, serviceProviderId) {
        try {
            // This could trigger additional logic like notifying other providers
            // or updating job cart priority
            console.log(`Job cart ${jobCartId} declined by provider ${serviceProviderId}`);
        } catch (error) {
            console.error('Error notifying job cart decline:', error);
        }
    }

    /**
     * Get job cart statistics for dashboard
     * @param {string} serviceProviderId - The service provider ID
     * @returns {Promise<Object>} - Statistics object
     */
    async getJobCartStats(serviceProviderId) {
        try {
            const [availableCount, acceptedCount, totalQuotations] = await Promise.all([
                this.supabase
                    .from('job_cart')
                    .select('job_cart_id', { count: 'exact' })
                    .eq('job_cart_status', 'available'),
                
                this.supabase
                    .from('job_cart_acceptance')
                    .select('acceptance_id', { count: 'exact' })
                    .eq('service_provider_id', serviceProviderId)
                    .eq('acceptance_status', 'accepted'),
                
                this.supabase
                    .from('quotation')
                    .select('quotation_id', { count: 'exact' })
                    .eq('service_provider_id', serviceProviderId)
            ]);

            return {
                available_jobs: availableCount.count || 0,
                accepted_jobs: acceptedCount.count || 0,
                total_quotations: totalQuotations.count || 0
            };
        } catch (error) {
            console.error('Error fetching job cart stats:', error);
            return {
                available_jobs: 0,
                accepted_jobs: 0,
                total_quotations: 0
            };
        }
    }
}

// Export for use in other modules
window.JobCartManager = JobCartManager;
