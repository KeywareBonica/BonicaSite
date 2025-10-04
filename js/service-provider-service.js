/**
 * Service Provider Database Service
 * Handles all service provider data operations with Supabase
 * Ensures all service provider information is fetched from database
 */

class ServiceProviderService {
    constructor(supabase) {
        this.supabase = supabase;
        this.currentProvider = null;
        this.providersCache = new Map();
    }

    /**
     * Get service provider by ID
     * @param {string} providerId - Service provider ID
     * @returns {Promise<Object|null>} Service provider data or null
     */
    async getServiceProviderById(providerId) {
        try {
            if (this.providersCache.has(providerId)) {
                return this.providersCache.get(providerId);
            }

            // Try different column name combinations to handle schema variations
            let provider = null;
            let error = null;

            // Use the correct column name: service_provider_contactno
            const result = await this.supabase
                .from('service_provider')
                .select(`
                    service_provider_id,
                    service_provider_name,
                    service_provider_surname,
                    service_provider_email,
                    service_provider_password,
                    service_provider_contactno,
                    service_provider_location,
                    service_provider_availability_date,
                    service_provider_slots,
                    service_provider_base_rate,
                    service_provider_overtime_rate,
                    service_provider_caption,
                    service_provider_rating,
                    service_provider_description,
                    service_provider_service_type,
                    service_provider_verification,
                    service_id,
                    created_at
                `)
                .eq('service_provider_id', providerId)
                .single();
            
            provider = result.data;
            error = result.error;

            if (error) {
                throw error;
            }

            this.providersCache.set(providerId, provider);
            return provider;
        } catch (error) {
            console.error('Error in getServiceProviderById:', error);
            return null;
        }
    }

    /**
     * Get current logged-in service provider
     * @returns {Promise<Object|null>} Service provider data or null
     */
    async getCurrentServiceProvider() {
        try {
            const { data: { user }, error: authError } = await supabase.auth.getUser();
            if (authError || !user) {
                console.error('No authenticated user:', authError);
                return null;
            }

            // Get service provider data from database
            const { data: provider, error } = await this.supabase
                .from('service_provider')
                .select(`
                    service_provider_id,
                    service_provider_name,
                    service_provider_surname,
                    service_provider_email,
                    service_provider_contactno,
                    service_provider_location,
                    service_provider_availability_date,
                    service_provider_slots,
                    service_provider_base_rate,
                    service_provider_overtime_rate,
                    service_provider_caption,
                    service_provider_rating,
                    service_provider_description,
                    service_provider_service_type,
                    service_provider_verification,
                    service_id,
                    created_at
                `)
                .eq('service_provider_email', user.email)
                .single();

            if (error) {
                console.error('Error fetching service provider:', error);
                return null;
            }

            this.currentProvider = provider;
            return provider;
        } catch (error) {
            console.error('Error in getCurrentServiceProvider:', error);
            return null;
        }
    }

    /**
     * Get all service providers (for admin dashboard)
     * @returns {Promise<Array>} Array of service providers
     */
    async getAllServiceProviders() {
        try {
            const { data: providers, error } = await this.supabase
                .from('service_provider')
                .select(`
                    service_provider_id,
                    service_provider_name,
                    service_provider_surname,
                    service_provider_email,
                    service_provider_contact,
                    service_provider_location,
                    service_provider_service_type,
                    service_provider_rating,
                    service_provider_base_rate,
                    service_provider_verification,
                    created_at
                `)
                .order('created_at', { ascending: false });

            if (error) throw error;

            return providers || [];
        } catch (error) {
            console.error('Error fetching all service providers:', error);
            return [];
        }
    }

    /**
     * Get service provider by ID
     * @param {string} providerId - Service provider ID
     * @returns {Promise<Object|null>} Service provider data or null
     */
    async getServiceProviderById(providerId) {
        try {
            // Check cache first
            if (this.providersCache.has(providerId)) {
                return this.providersCache.get(providerId);
            }

            const { data: provider, error } = await this.supabase
                .from('service_provider')
                .select('*')
                .eq('service_provider_id', providerId)
                .single();

            if (error) {
                console.error('Error fetching service provider by ID:', error);
                return null;
            }

            // Cache the result
            this.providersCache.set(providerId, provider);
            return provider;
        } catch (error) {
            console.error('Error in getServiceProviderById:', error);
            return null;
        }
    }

    /**
     * Update service provider profile
     * @param {Object} updates - Fields to update
     * @returns {Promise<Object>} Updated provider data
     */
    async updateServiceProviderProfile(updates) {
        try {
            if (!this.currentProvider) {
                throw new Error('No current service provider found');
            }

            const { data, error } = await this.supabase
                .from('service_provider')
                .update(updates)
                .eq('service_provider_id', this.currentProvider.service_provider_id)
                .select()
                .single();

            if (error) throw error;

            // Update cache and current provider
            this.currentProvider = data;
            this.providersCache.set(data.service_provider_id, data);

            return data;
        } catch (error) {
            console.error('Error updating service provider profile:', error);
            throw error;
        }
    }

    /**
     * Get service providers by location
     * @param {string} location - Location to filter by
     * @returns {Promise<Array>} Array of service providers in location
     */
    async getServiceProvidersByLocation(location) {
        try {
            const { data: providers, error } = await this.supabase
                .from('service_provider')
                .select(`
                    service_provider_id,
                    service_provider_name,
                    service_provider_surname,
                    service_provider_email,
                    service_provider_location,
                    service_provider_service_type,
                    service_provider_rating,
                    service_provider_base_rate
                `)
                .ilike('service_provider_location', `%${location}%`)
                .eq('service_provider_verification', true)
                .order('service_provider_rating', { ascending: false });

            if (error) throw error;

            return providers || [];
        } catch (error) {
            console.error('Error fetching service providers by location:', error);
            return [];
        }
    }

    /**
     * Get service providers by service type
     * @param {string} serviceType - Service type to filter by
     * @returns {Promise<Array>} Array of service providers for service type
     */
    async getServiceProvidersByServiceType(serviceType) {
        try {
            const { data: providers, error } = await this.supabase
                .from('service_provider')
                .select(`
                    service_provider_id,
                    service_provider_name,
                    service_provider_surname,
                    service_provider_email,
                    service_provider_location,
                    service_provider_service_type,
                    service_provider_rating,
                    service_provider_base_rate
                `)
                .ilike('service_provider_service_type', `%${serviceType}%`)
                .eq('service_provider_verification', true)
                .order('service_provider_rating', { ascending: false });

            if (error) throw error;

            return providers || [];
        } catch (error) {
            console.error('Error fetching service providers by service type:', error);
            return [];
        }
    }

    /**
     * Get client information by ID
     * @param {string} clientId - Client ID
     * @returns {Promise<Object|null>} Client data or null
     */
    async getClientById(clientId) {
        try {
            const { data: client, error } = await this.supabase
                .from('client')
                .select(`
                    client_id,
                    client_name,
                    client_surname,
                    client_email,
                    client_contact,
                    client_location
                `)
                .eq('client_id', clientId)
                .single();

            if (error) {
                console.error('Error fetching client:', error);
                return null;
            }

            return client;
        } catch (error) {
            console.error('Error in getClientById:', error);
            return null;
        }
    }

    /**
     * Get all clients (for service provider to see their clients)
     * @returns {Promise<Array>} Array of clients
     */
    async getAllClients() {
        try {
            const { data: clients, error } = await this.supabase
                .from('client')
                .select(`
                    client_id,
                    client_name,
                    client_surname,
                    client_email,
                    client_contact,
                    client_location,
                    created_at
                `)
                .order('created_at', { ascending: false });

            if (error) throw error;

            return clients || [];
        } catch (error) {
            console.error('Error fetching all clients:', error);
            return [];
        }
    }

    /**
     * Get client information for a specific job cart
     * @param {string} jobCartId - Job cart ID
     * @returns {Promise<Object|null>} Client data or null
     */
    async getClientByJobCart(jobCartId) {
        try {
            const { data: clientData, error } = await this.supabase
                .from('job_cart')
                .select(`
                    event:event_id (
                        client:client_id (
                            client_id,
                            client_name,
                            client_surname,
                            client_email,
                            client_contact,
                            client_location
                        )
                    )
                `)
                .eq('job_cart_id', jobCartId)
                .single();

            if (error) {
                console.error('Error fetching client by job cart:', error);
                return null;
            }

            return clientData?.event?.client || null;
        } catch (error) {
            console.error('Error in getClientByJobCart:', error);
            return null;
        }
    }

    /**
     * Get notifications for current service provider
     * @returns {Promise<Array>} Array of notifications
     */
    async getServiceProviderNotifications() {
        try {
            if (!this.currentProvider) {
                return [];
            }

            const { data: notifications, error } = await this.supabase
                .from('notification')
                .select(`
                    notification_id,
                    notification_title,
                    notification_message,
                    notification_type,
                    notification_status,
                    created_at
                `)
                .eq('service_provider_id', this.currentProvider.service_provider_id)
                .order('created_at', { ascending: false })
                .limit(10);

            if (error) throw error;

            return notifications || [];
        } catch (error) {
            console.error('Error fetching notifications:', error);
            return [];
        }
    }

    /**
     * Update notification status
     * @param {string} notificationId - Notification ID
     * @param {string} status - New status
     * @returns {Promise<boolean>} Success status
     */
    async updateNotificationStatus(notificationId, status) {
        try {
            const { error } = await this.supabase
                .from('notification')
                .update({ notification_status: status })
                .eq('notification_id', notificationId);

            if (error) throw error;

            return true;
        } catch (error) {
            console.error('Error updating notification status:', error);
            return false;
        }
    }

    /**
     * Get service provider statistics
     * @returns {Promise<Object>} Statistics object
     */
    async getServiceProviderStats() {
        try {
            if (!this.currentProvider) {
                return {
                    active_jobs: 0,
                    pending_quotes: 0,
                    upcoming_events: 0,
                    rating: 0,
                    total_earnings: 0
                };
            }

            const providerId = this.currentProvider.service_provider_id;

            // Get accepted job carts
            const { data: acceptedJobs, error: acceptedError } = await this.supabase
                .from('job_cart_acceptance')
                .select('acceptance_id', { count: 'exact' })
                .eq('service_provider_id', providerId)
                .eq('acceptance_status', 'accepted');

            if (acceptedError) throw acceptedError;

            // Get pending quotations
            const { data: pendingQuotes, error: quotesError } = await this.supabase
                .from('quotation')
                .select('quotation_id', { count: 'exact' })
                .eq('service_provider_id', providerId)
                .eq('quotation_status', 'pending');

            if (quotesError) throw quotesError;

            // Get upcoming events
            const { data: upcomingEvents, error: eventsError } = await this.supabase
                .from('job_cart_acceptance')
                .select(`
                    job_cart:job_cart_id (
                        event:event_id (
                            event_date
                        )
                    )
                `)
                .eq('service_provider_id', providerId)
                .eq('acceptance_status', 'accepted');

            if (eventsError) throw eventsError;

            // Count upcoming events (next 7 days)
            const today = new Date();
            const nextWeek = new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000);
            
            const upcomingCount = upcomingEvents?.filter(event => {
                const eventDate = new Date(event.job_cart.event.event_date);
                return eventDate >= today && eventDate <= nextWeek;
            }).length || 0;

            return {
                active_jobs: acceptedJobs?.count || 0,
                pending_quotes: pendingQuotes?.count || 0,
                upcoming_events: upcomingCount,
                rating: this.currentProvider.service_provider_rating || 0,
                total_earnings: 0 // Calculate from completed jobs
            };
        } catch (error) {
            console.error('Error fetching service provider stats:', error);
            return {
                active_jobs: 0,
                pending_quotes: 0,
                upcoming_events: 0,
                rating: 0,
                total_earnings: 0
            };
        }
    }

    /**
     * Clear cache
     */
    clearCache() {
        this.providersCache.clear();
        this.currentProvider = null;
    }

    /**
     * Initialize service provider data
     * @returns {Promise<Object|null>} Current service provider or null
     */
    async initialize() {
        try {
            const provider = await this.getCurrentServiceProvider();
            if (provider) {
                console.log('✅ Service Provider Service initialized:', provider.service_provider_name);
            } else {
                console.log('❌ No service provider found or not authenticated');
            }
            return provider;
        } catch (error) {
            console.error('Error initializing Service Provider Service:', error);
            return null;
        }
    }
}

// Export for use in other modules
window.ServiceProviderService = ServiceProviderService;
