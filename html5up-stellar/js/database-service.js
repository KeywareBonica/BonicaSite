/**
 * Comprehensive Database Service
 * Handles all database operations for the entire application
 * Replaces all hardcoded data with dynamic database queries
 */

class DatabaseService {
    constructor(supabase) {
        this.supabase = supabase;
        this.cache = new Map();
        this.currentUser = null;
    }

    /**
     * CLIENT OPERATIONS
     */
    
    async getCurrentClient() {
        try {
            const { data: { user }, error: authError } = await supabase.auth.getUser();
            if (authError || !user) return null;

            const { data: client, error } = await this.supabase
                .from('client')
                .select('*')
                .eq('client_email', user.email)
                .single();

            if (error) {
                console.error('Error fetching client:', error);
                return null;
            }

            this.currentUser = client;
            return client;
        } catch (error) {
            console.error('Error in getCurrentClient:', error);
            return null;
        }
    }

    async getAllClients() {
        try {
            const { data: clients, error } = await this.supabase
                .from('client')
                .select('*')
                .order('created_at', { ascending: false });

            if (error) throw error;
            return clients || [];
        } catch (error) {
            console.error('Error fetching all clients:', error);
            return [];
        }
    }

    async getClientById(clientId) {
        try {
            if (this.cache.has(`client_${clientId}`)) {
                return this.cache.get(`client_${clientId}`);
            }

            const { data: client, error } = await this.supabase
                .from('client')
                .select('*')
                .eq('client_id', clientId)
                .single();

            if (error) throw error;

            this.cache.set(`client_${clientId}`, client);
            return client;
        } catch (error) {
            console.error('Error fetching client by ID:', error);
            return null;
        }
    }

    async updateClient(clientId, updates) {
        try {
            const { data, error } = await this.supabase
                .from('client')
                .update(updates)
                .eq('client_id', clientId)
                .select()
                .single();

            if (error) throw error;

            // Update cache
            this.cache.set(`client_${clientId}`, data);
            return data;
        } catch (error) {
            console.error('Error updating client:', error);
            throw error;
        }
    }

    /**
     * SERVICE PROVIDER OPERATIONS
     */

    async getCurrentServiceProvider() {
        try {
            const { data: { user }, error: authError } = await supabase.auth.getUser();
            if (authError || !user) return null;

            const { data: provider, error } = await this.supabase
                .from('service_provider')
                .select('*')
                .eq('service_provider_email', user.email)
                .single();

            if (error) {
                console.error('Error fetching service provider:', error);
                return null;
            }

            this.currentUser = provider;
            return provider;
        } catch (error) {
            console.error('Error in getCurrentServiceProvider:', error);
            return null;
        }
    }

    async getAllServiceProviders() {
        try {
            const { data: providers, error } = await this.supabase
                .from('service_provider')
                .select('*')
                .order('created_at', { ascending: false });

            if (error) throw error;
            return providers || [];
        } catch (error) {
            console.error('Error fetching all service providers:', error);
            return [];
        }
    }

    async getServiceProviderById(providerId) {
        try {
            if (this.cache.has(`provider_${providerId}`)) {
                return this.cache.get(`provider_${providerId}`);
            }

            const { data: provider, error } = await this.supabase
                .from('service_provider')
                .select('*')
                .eq('service_provider_id', providerId)
                .single();

            if (error) throw error;

            this.cache.set(`provider_${providerId}`, provider);
            return provider;
        } catch (error) {
            console.error('Error fetching service provider by ID:', error);
            return null;
        }
    }

    async updateServiceProvider(providerId, updates) {
        try {
            const { data, error } = await this.supabase
                .from('service_provider')
                .update(updates)
                .eq('service_provider_id', providerId)
                .select()
                .single();

            if (error) throw error;

            // Update cache
            this.cache.set(`provider_${providerId}`, data);
            return data;
        } catch (error) {
            console.error('Error updating service provider:', error);
            throw error;
        }
    }

    /**
     * EVENT OPERATIONS
     */

    async getCurrentClientEvents() {
        try {
            const client = await this.getCurrentClient();
            if (!client) return [];

            const { data: events, error } = await this.supabase
                .from('event')
                .select('*')
                .eq('client_id', client.client_id)
                .order('event_date', { ascending: false });

            if (error) throw error;
            return events || [];
        } catch (error) {
            console.error('Error fetching client events:', error);
            return [];
        }
    }

    async getAllEvents() {
        try {
            const { data: events, error } = await this.supabase
                .from('event')
                .select(`
                    *,
                    client:client_id (
                        client_name,
                        client_surname,
                        client_email,
                        client_contact
                    )
                `)
                .order('event_date', { ascending: false });

            if (error) throw error;
            return events || [];
        } catch (error) {
            console.error('Error fetching all events:', error);
            return [];
        }
    }

    async getEventById(eventId) {
        try {
            if (this.cache.has(`event_${eventId}`)) {
                return this.cache.get(`event_${eventId}`);
            }

            const { data: event, error } = await this.supabase
                .from('event')
                .select(`
                    *,
                    client:client_id (
                        client_name,
                        client_surname,
                        client_email,
                        client_contact
                    )
                `)
                .eq('event_id', eventId)
                .single();

            if (error) throw error;

            this.cache.set(`event_${eventId}`, event);
            return event;
        } catch (error) {
            console.error('Error fetching event by ID:', error);
            return null;
        }
    }

    async createEvent(eventData) {
        try {
            const { data, error } = await this.supabase
                .from('event')
                .insert(eventData)
                .select()
                .single();

            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Error creating event:', error);
            throw error;
        }
    }

    async updateEvent(eventId, updates) {
        try {
            const { data, error } = await this.supabase
                .from('event')
                .update(updates)
                .eq('event_id', eventId)
                .select()
                .single();

            if (error) throw error;

            // Update cache
            this.cache.set(`event_${eventId}`, data);
            return data;
        } catch (error) {
            console.error('Error updating event:', error);
            throw error;
        }
    }

    /**
     * BOOKING OPERATIONS
     */

    async getCurrentClientBookings() {
        try {
            const client = await this.getCurrentClient();
            if (!client) return [];

            const { data: bookings, error } = await this.supabase
                .from('booking')
                .select(`
                    *,
                    event:event_id (
                        event_name,
                        event_date,
                        event_location
                    )
                `)
                .eq('client_id', client.client_id)
                .order('booking_date', { ascending: false });

            if (error) throw error;
            return bookings || [];
        } catch (error) {
            console.error('Error fetching client bookings:', error);
            return [];
        }
    }

    async getAllBookings() {
        try {
            const { data: bookings, error } = await this.supabase
                .from('booking')
                .select(`
                    *,
                    client:client_id (
                        client_name,
                        client_surname,
                        client_email,
                        client_contact
                    ),
                    event:event_id (
                        event_name,
                        event_date,
                        event_location
                    )
                `)
                .order('booking_date', { ascending: false });

            if (error) throw error;
            return bookings || [];
        } catch (error) {
            console.error('Error fetching all bookings:', error);
            return [];
        }
    }

    async getBookingById(bookingId) {
        try {
            if (this.cache.has(`booking_${bookingId}`)) {
                return this.cache.get(`booking_${bookingId}`);
            }

            const { data: booking, error } = await this.supabase
                .from('booking')
                .select(`
                    *,
                    client:client_id (
                        client_name,
                        client_surname,
                        client_email,
                        client_contact
                    ),
                    event:event_id (
                        event_name,
                        event_date,
                        event_location,
                        event_start_time,
                        event_end_time
                    )
                `)
                .eq('booking_id', bookingId)
                .single();

            if (error) throw error;

            this.cache.set(`booking_${bookingId}`, booking);
            return booking;
        } catch (error) {
            console.error('Error fetching booking by ID:', error);
            return null;
        }
    }

    async createBooking(bookingData) {
        try {
            const { data, error } = await this.supabase
                .from('booking')
                .insert(bookingData)
                .select()
                .single();

            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Error creating booking:', error);
            throw error;
        }
    }

    async updateBooking(bookingId, updates) {
        try {
            const { data, error } = await this.supabase
                .from('booking')
                .update(updates)
                .eq('booking_id', bookingId)
                .select()
                .single();

            if (error) throw error;

            // Update cache
            this.cache.set(`booking_${bookingId}`, data);
            return data;
        } catch (error) {
            console.error('Error updating booking:', error);
            throw error;
        }
    }

    /**
     * JOB CART OPERATIONS
     */

    async getCurrentClientJobCarts() {
        try {
            const client = await this.getCurrentClient();
            if (!client) return [];

            const { data: jobCarts, error } = await this.supabase
                .from('job_cart')
                .select(`
                    *,
                    event:event_id (
                        event_name,
                        event_date,
                        event_location
                    )
                `)
                .eq('event.client_id', client.client_id)
                .order('job_cart_created_date', { ascending: false });

            if (error) throw error;
            return jobCarts || [];
        } catch (error) {
            console.error('Error fetching client job carts:', error);
            return [];
        }
    }

    async getAllJobCarts() {
        try {
            const { data: jobCarts, error } = await this.supabase
                .from('job_cart')
                .select(`
                    *,
                    event:event_id (
                        event_name,
                        event_date,
                        event_location,
                        client:client_id (
                            client_name,
                            client_surname,
                            client_email
                        )
                    )
                `)
                .order('job_cart_created_date', { ascending: false });

            if (error) throw error;
            return jobCarts || [];
        } catch (error) {
            console.error('Error fetching all job carts:', error);
            return [];
        }
    }

    async getJobCartById(jobCartId) {
        try {
            if (this.cache.has(`jobcart_${jobCartId}`)) {
                return this.cache.get(`jobcart_${jobCartId}`);
            }

            const { data: jobCart, error } = await this.supabase
                .from('job_cart')
                .select(`
                    *,
                    event:event_id (
                        event_name,
                        event_date,
                        event_location,
                        client:client_id (
                            client_name,
                            client_surname,
                            client_email,
                            client_contact
                        )
                    )
                `)
                .eq('job_cart_id', jobCartId)
                .single();

            if (error) throw error;

            this.cache.set(`jobcart_${jobCartId}`, jobCart);
            return jobCart;
        } catch (error) {
            console.error('Error fetching job cart by ID:', error);
            return null;
        }
    }

    async createJobCart(jobCartData) {
        try {
            const { data, error } = await this.supabase
                .from('job_cart')
                .insert(jobCartData)
                .select()
                .single();

            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Error creating job cart:', error);
            throw error;
        }
    }

    async updateJobCart(jobCartId, updates) {
        try {
            const { data, error } = await this.supabase
                .from('job_cart')
                .update(updates)
                .eq('job_cart_id', jobCartId)
                .select()
                .single();

            if (error) throw error;

            // Update cache
            this.cache.set(`jobcart_${jobCartId}`, data);
            return data;
        } catch (error) {
            console.error('Error updating job cart:', error);
            throw error;
        }
    }

    /**
     * QUOTATION OPERATIONS
     */

    async getCurrentClientQuotations() {
        try {
            const client = await this.getCurrentClient();
            if (!client) return [];

            const { data: quotations, error } = await this.supabase
                .from('quotation')
                .select(`
                    *,
                    service_provider:service_provider_id (
                        service_provider_name,
                        service_provider_surname,
                        service_provider_email,
                        service_provider_rating,
                        service_provider_location
                    ),
                    job_cart:job_cart_id (
                        job_cart_item,
                        job_cart_details,
                        event:event_id (
                            event_name,
                            event_date
                        )
                    )
                `)
                .eq('job_cart.event.client_id', client.client_id)
                .order('quotation_submission_date', { ascending: false });

            if (error) throw error;
            return quotations || [];
        } catch (error) {
            console.error('Error fetching client quotations:', error);
            return [];
        }
    }

    async getServiceProviderQuotations(providerId) {
        try {
            const { data: quotations, error } = await this.supabase
                .from('quotation')
                .select(`
                    *,
                    job_cart:job_cart_id (
                        job_cart_item,
                        job_cart_details,
                        event:event_id (
                            event_name,
                            event_date,
                            client:client_id (
                                client_name,
                                client_surname,
                                client_email
                            )
                        )
                    )
                `)
                .eq('service_provider_id', providerId)
                .order('quotation_submission_date', { ascending: false });

            if (error) throw error;
            return quotations || [];
        } catch (error) {
            console.error('Error fetching service provider quotations:', error);
            return [];
        }
    }

    async getAllQuotations() {
        try {
            const { data: quotations, error } = await this.supabase
                .from('quotation')
                .select(`
                    *,
                    service_provider:service_provider_id (
                        service_provider_name,
                        service_provider_surname,
                        service_provider_email,
                        service_provider_rating
                    ),
                    job_cart:job_cart_id (
                        job_cart_item,
                        job_cart_details,
                        event:event_id (
                            event_name,
                            event_date,
                            client:client_id (
                                client_name,
                                client_surname,
                                client_email
                            )
                        )
                    )
                `)
                .order('quotation_submission_date', { ascending: false });

            if (error) throw error;
            return quotations || [];
        } catch (error) {
            console.error('Error fetching all quotations:', error);
            return [];
        }
    }

    async getQuotationById(quotationId) {
        try {
            if (this.cache.has(`quotation_${quotationId}`)) {
                return this.cache.get(`quotation_${quotationId}`);
            }

            const { data: quotation, error } = await this.supabase
                .from('quotation')
                .select(`
                    *,
                    service_provider:service_provider_id (
                        service_provider_name,
                        service_provider_surname,
                        service_provider_email,
                        service_provider_contact,
                        service_provider_rating,
                        service_provider_location
                    ),
                    job_cart:job_cart_id (
                        job_cart_item,
                        job_cart_details,
                        event:event_id (
                            event_name,
                            event_date,
                            event_location,
                            client:client_id (
                                client_name,
                                client_surname,
                                client_email,
                                client_contact
                            )
                        )
                    )
                `)
                .eq('quotation_id', quotationId)
                .single();

            if (error) throw error;

            this.cache.set(`quotation_${quotationId}`, quotation);
            return quotation;
        } catch (error) {
            console.error('Error fetching quotation by ID:', error);
            return null;
        }
    }

    async createQuotation(quotationData) {
        try {
            const { data, error } = await this.supabase
                .from('quotation')
                .insert(quotationData)
                .select()
                .single();

            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Error creating quotation:', error);
            throw error;
        }
    }

    async updateQuotation(quotationId, updates) {
        try {
            const { data, error } = await this.supabase
                .from('quotation')
                .update(updates)
                .eq('quotation_id', quotationId)
                .select()
                .single();

            if (error) throw error;

            // Update cache
            this.cache.set(`quotation_${quotationId}`, data);
            return data;
        } catch (error) {
            console.error('Error updating quotation:', error);
            throw error;
        }
    }

    /**
     * PAYMENT OPERATIONS
     */

    async getCurrentClientPayments() {
        try {
            const client = await this.getCurrentClient();
            if (!client) return [];

            const { data: payments, error } = await this.supabase
                .from('payment')
                .select(`
                    *,
                    booking:booking_id (
                        event:event_id (
                            event_name,
                            event_date
                        )
                    )
                `)
                .eq('client_id', client.client_id)
                .order('payment_date', { ascending: false });

            if (error) throw error;
            return payments || [];
        } catch (error) {
            console.error('Error fetching client payments:', error);
            return [];
        }
    }

    async getAllPayments() {
        try {
            const { data: payments, error } = await this.supabase
                .from('payment')
                .select(`
                    *,
                    client:client_id (
                        client_name,
                        client_surname,
                        client_email
                    ),
                    booking:booking_id (
                        event:event_id (
                            event_name,
                            event_date
                        )
                    )
                `)
                .order('payment_date', { ascending: false });

            if (error) throw error;
            return payments || [];
        } catch (error) {
            console.error('Error fetching all payments:', error);
            return [];
        }
    }

    async createPayment(paymentData) {
        try {
            const { data, error } = await this.supabase
                .from('payment')
                .insert(paymentData)
                .select()
                .single();

            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Error creating payment:', error);
            throw error;
        }
    }

    /**
     * REVIEW OPERATIONS
     */

    async getServiceProviderReviews(providerId) {
        try {
            const { data: reviews, error } = await this.supabase
                .from('review')
                .select(`
                    *,
                    client:client_id (
                        client_name,
                        client_surname
                    ),
                    booking:booking_id (
                        event:event_id (
                            event_name,
                            event_date
                        )
                    )
                `)
                .eq('service_provider_id', providerId)
                .order('review_date', { ascending: false });

            if (error) throw error;
            return reviews || [];
        } catch (error) {
            console.error('Error fetching service provider reviews:', error);
            return [];
        }
    }

    async getAllReviews() {
        try {
            const { data: reviews, error } = await this.supabase
                .from('review')
                .select(`
                    *,
                    client:client_id (
                        client_name,
                        client_surname
                    ),
                    service_provider:service_provider_id (
                        service_provider_name,
                        service_provider_surname
                    ),
                    booking:booking_id (
                        event:event_id (
                            event_name,
                            event_date
                        )
                    )
                `)
                .order('review_date', { ascending: false });

            if (error) throw error;
            return reviews || [];
        } catch (error) {
            console.error('Error fetching all reviews:', error);
            return [];
        }
    }

    async createReview(reviewData) {
        try {
            const { data, error } = await this.supabase
                .from('review')
                .insert(reviewData)
                .select()
                .single();

            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Error creating review:', error);
            throw error;
        }
    }

    /**
     * NOTIFICATION OPERATIONS
     */

    async getCurrentUserNotifications() {
        try {
            const user = await this.getCurrentClient() || await this.getCurrentServiceProvider();
            if (!user) return [];

            const userId = user.client_id || user.service_provider_id;
            const userType = user.client_id ? 'client' : 'service_provider';

            const { data: notifications, error } = await this.supabase
                .from('notification')
                .select('*')
                .eq(`${userType}_id`, userId)
                .order('created_at', { ascending: false })
                .limit(20);

            if (error) throw error;
            return notifications || [];
        } catch (error) {
            console.error('Error fetching user notifications:', error);
            return [];
        }
    }

    async createNotification(notificationData) {
        try {
            const { data, error } = await this.supabase
                .from('notification')
                .insert(notificationData)
                .select()
                .single();

            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Error creating notification:', error);
            throw error;
        }
    }

    async updateNotificationStatus(notificationId, status) {
        try {
            const { data, error } = await this.supabase
                .from('notification')
                .update({ notification_status: status })
                .eq('notification_id', notificationId)
                .select()
                .single();

            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Error updating notification status:', error);
            throw error;
        }
    }

    /**
     * STATISTICS OPERATIONS
     */

    async getDashboardStats() {
        try {
            const [clients, providers, bookings, quotations, payments] = await Promise.all([
                this.getAllClients(),
                this.getAllServiceProviders(),
                this.getAllBookings(),
                this.getAllQuotations(),
                this.getAllPayments()
            ]);

            const totalRevenue = payments.reduce((sum, payment) => sum + parseFloat(payment.payment_amount || 0), 0);
            const averageRating = quotations.length > 0 ? 
                quotations.reduce((sum, q) => sum + parseFloat(q.service_provider?.service_provider_rating || 0), 0) / quotations.length : 0;

            return {
                total_clients: clients.length,
                total_providers: providers.length,
                total_bookings: bookings.length,
                total_quotations: quotations.length,
                total_revenue: totalRevenue,
                average_rating: averageRating,
                pending_bookings: bookings.filter(b => b.booking_status === 'pending').length,
                completed_bookings: bookings.filter(b => b.booking_status === 'completed').length
            };
        } catch (error) {
            console.error('Error fetching dashboard stats:', error);
            return {
                total_clients: 0,
                total_providers: 0,
                total_bookings: 0,
                total_quotations: 0,
                total_revenue: 0,
                average_rating: 0,
                pending_bookings: 0,
                completed_bookings: 0
            };
        }
    }

    /**
     * UTILITY METHODS
     */

    clearCache() {
        this.cache.clear();
        this.currentUser = null;
    }

    async initialize() {
        try {
            // Try to get current user (client or service provider)
            const client = await this.getCurrentClient();
            const provider = await this.getCurrentServiceProvider();
            
            if (client) {
                console.log('✅ Database Service initialized for client:', client.client_name);
            } else if (provider) {
                console.log('✅ Database Service initialized for service provider:', provider.service_provider_name);
            } else {
                console.log('ℹ️ Database Service initialized (no authenticated user)');
            }

            return { client, provider };
        } catch (error) {
            console.error('Error initializing Database Service:', error);
            return { client: null, provider: null };
        }
    }
}

// Export for use in other modules
window.DatabaseService = DatabaseService;
