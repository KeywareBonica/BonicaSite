/**
 * Power BI Data API Endpoint
 * Provides live database data for Power BI reports
 */

// Check if we're in a browser environment
if (typeof window !== 'undefined' && window.supabase) {
    class PowerBIDataAPI {
        constructor(supabase) {
            this.supabase = supabase;
            this.cache = new Map();
            this.cacheTimeout = 5 * 60 * 1000; // 5 minutes
        }

        async getData() {
            try {
                // Check cache first
                const cacheKey = 'powerbi_data';
                const cached = this.cache.get(cacheKey);
                if (cached && (Date.now() - cached.timestamp) < this.cacheTimeout) {
                    return cached.data;
                }

                // Fetch fresh data from database
                const data = await this.fetchLiveData();
                
                // Cache the data
                this.cache.set(cacheKey, {
                    data: data,
                    timestamp: Date.now()
                });

                return data;
            } catch (error) {
                console.error('Error fetching Power BI data:', error);
                throw error;
            }
        }

        async fetchLiveData() {
            try {
                // Fetch all relevant data in parallel
                const [
                    clients, 
                    providers, 
                    bookings, 
                    payments, 
                    events, 
                    quotations,
                    jobCarts
                ] = await Promise.all([
                    this.getClients(),
                    this.getServiceProviders(),
                    this.getBookings(),
                    this.getPayments(),
                    this.getEvents(),
                    this.getQuotations(),
                    this.getJobCarts()
                ]);

                // Calculate statistics
                const stats = this.calculateStats({
                    clients,
                    providers,
                    bookings,
                    payments,
                    events,
                    quotations,
                    jobCarts
                });

                return {
                    timestamp: new Date().toISOString(),
                    stats: stats,
                    clients: clients,
                    serviceProviders: providers,
                    events: events,
                    bookings: bookings,
                    payments: payments,
                    quotations: quotations,
                    jobCarts: jobCarts
                };
            } catch (error) {
                console.error('Error fetching live data:', error);
                throw error;
            }
        }

        async getClients() {
            const { data, error } = await this.supabase
                .from('client')
                .select('*')
                .order('created_at', { ascending: false });
            
            if (error) throw error;
            return data || [];
        }

        async getServiceProviders() {
            const { data, error } = await this.supabase
                .from('service_provider')
                .select('*')
                .order('created_at', { ascending: false });
            
            if (error) throw error;
            return data || [];
        }

        async getEvents() {
            const { data, error } = await this.supabase
                .from('event')
                .select(`
                    *,
                    client:client_id (
                        client_name,
                        client_surname,
                        client_email
                    )
                `)
                .order('event_date', { ascending: false });
            
            if (error) throw error;
            return data || [];
        }

        async getBookings() {
            const { data, error } = await this.supabase
                .from('booking')
                .select(`
                    *,
                    client:client_id (
                        client_name,
                        client_surname,
                        client_email
                    ),
                    event:event_id (
                        event_type,
                        event_date,
                        event_location
                    )
                `)
                .order('booking_date', { ascending: false });
            
            if (error) throw error;
            return data || [];
        }

        async getPayments() {
            const { data, error } = await this.supabase
                .from('payment')
                .select(`
                    *,
                    booking:booking_id (
                        booking_date,
                        event:event_id (
                            event_type,
                            event_date
                        )
                    )
                `)
                .order('created_at', { ascending: false });
            
            if (error) throw error;
            return data || [];
        }

        async getQuotations() {
            const { data, error } = await this.supabase
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
                        created_at
                    )
                `)
                .order('quotation_submission_date', { ascending: false });
            
            if (error) throw error;
            return data || [];
        }

        async getJobCarts() {
            const { data, error } = await this.supabase
                .from('job_cart')
                .select(`
                    *,
                    event:event_id (
                        event_type,
                        event_date,
                        client:client_id (
                            client_name,
                            client_surname
                        )
                    ),
                    service:service_id (
                        service_name,
                        service_type
                    )
                `)
                .order('created_at', { ascending: false });
            
            if (error) throw error;
            return data || [];
        }

        calculateStats(data) {
            const { clients, providers, bookings, payments, events, quotations, jobCarts } = data;
            
            const totalRevenue = payments.reduce((sum, payment) => 
                sum + parseFloat(payment.payment_amount || 0), 0);
            
            const averageRating = providers.length > 0 ? 
                providers.reduce((sum, p) => sum + parseFloat(p.service_provider_rating || 0), 0) / providers.length : 0;

            return {
                total_clients: clients.length,
                total_providers: providers.length,
                total_events: events.length,
                total_bookings: bookings.length,
                total_quotations: quotations.length,
                total_job_carts: jobCarts.length,
                total_revenue: totalRevenue,
                average_rating: averageRating,
                pending_bookings: bookings.filter(b => b.booking_status === 'pending').length,
                completed_bookings: bookings.filter(b => b.booking_status === 'completed').length,
                pending_quotations: quotations.filter(q => q.quotation_status === 'pending').length,
                approved_quotations: quotations.filter(q => q.quotation_status === 'approved').length,
                pending_payments: payments.filter(p => p.payment_status === 'pending').length,
                completed_payments: payments.filter(p => p.payment_status === 'completed').length
            };
        }

        clearCache() {
            this.cache.clear();
        }
    }

    // Make it globally available
    window.PowerBIDataAPI = PowerBIDataAPI;

    // Auto-initialize if supabase is available
    if (window.supabase) {
        window.powerBIDataAPI = new PowerBIDataAPI(window.supabase);
        console.log('✅ Power BI Data API initialized');
    }
}

