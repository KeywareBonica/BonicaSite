/**
 * Integration Script for Dual Workflow System
 * This script ensures all components work together seamlessly
 */

class DualWorkflowIntegration {
    constructor() {
        this.services = {
            supabase: null,
            database: null,
            realtime: null,
            jobCartManager: null,
            notificationSystem: null
        };
        this.isInitialized = false;
    }

    /**
     * Initialize all services for dual workflow
     */
    async initialize() {
        try {
            console.log('🚀 Initializing Dual Workflow System...');
            
            // Initialize Supabase
            await this.initializeSupabase();
            
            // Initialize Database Service
            await this.initializeDatabaseService();
            
            // Initialize Real-time Service
            await this.initializeRealtimeService();
            
            // Initialize Job Cart Manager
            await this.initializeJobCartManager();
            
            // Initialize Notification System
            await this.initializeNotificationSystem();
            
            // Set up cross-service integrations
            await this.setupIntegrations();
            
            this.isInitialized = true;
            console.log('✅ Dual Workflow System fully initialized!');
            
            // Dispatch initialization event
            window.dispatchEvent(new CustomEvent('dualWorkflowInitialized', {
                detail: { services: this.services }
            }));
            
        } catch (error) {
            console.error('❌ Failed to initialize Dual Workflow System:', error);
            throw error;
        }
    }

    /**
     * Initialize Supabase client
     */
    async initializeSupabase() {
        try {
            if (!window.supabase) {
                throw new Error('Supabase client not available');
            }
            this.services.supabase = window.supabase;
            console.log('✅ Supabase client initialized');
        } catch (error) {
            console.error('❌ Supabase initialization failed:', error);
            throw error;
        }
    }

    /**
     * Initialize Database Service
     */
    async initializeDatabaseService() {
        try {
            if (!window.DatabaseService) {
                throw new Error('DatabaseService not available');
            }
            
            this.services.database = new DatabaseService(this.services.supabase);
            await this.services.database.initialize();
            console.log('✅ Database Service initialized');
        } catch (error) {
            console.error('❌ Database Service initialization failed:', error);
            throw error;
        }
    }

    /**
     * Initialize Real-time Service
     */
    async initializeRealtimeService() {
        try {
            if (!window.RealtimeService) {
                throw new Error('RealtimeService not available');
            }
            
            this.services.realtime = new RealtimeService();
            await this.services.realtime.initialize(this.services.supabase);
            console.log('✅ Real-time Service initialized');
        } catch (error) {
            console.error('❌ Real-time Service initialization failed:', error);
            throw error;
        }
    }

    /**
     * Initialize Job Cart Manager
     */
    async initializeJobCartManager() {
        try {
            if (!window.JobCartManager) {
                throw new Error('JobCartManager not available');
            }
            
            this.services.jobCartManager = new JobCartManager(
                this.services.supabase,
                this.services.database
            );
            console.log('✅ Job Cart Manager initialized');
        } catch (error) {
            console.error('❌ Job Cart Manager initialization failed:', error);
            throw error;
        }
    }

    /**
     * Initialize Notification System
     */
    async initializeNotificationSystem() {
        try {
            if (!window.NotificationSystem) {
                throw new Error('NotificationSystem not available');
            }
            
            this.services.notificationSystem = new NotificationSystem(
                this.services.supabase,
                this.services.realtime
            );
            await this.services.notificationSystem.initialize();
            console.log('✅ Notification System initialized');
        } catch (error) {
            console.error('❌ Notification System initialization failed:', error);
            throw error;
        }
    }

    /**
     * Set up integrations between services
     */
    async setupIntegrations() {
        try {
            // Set up job cart notifications
            this.setupJobCartNotifications();
            
            // Set up quotation notifications
            this.setupQuotationNotifications();
            
            // Set up booking notifications
            this.setupBookingNotifications();
            
            // Set up real-time UI updates
            this.setupRealTimeUIUpdates();
            
            console.log('✅ Service integrations configured');
        } catch (error) {
            console.error('❌ Service integration setup failed:', error);
            throw error;
        }
    }

    /**
     * Set up job cart notifications
     */
    setupJobCartNotifications() {
        // Listen for new job carts
        this.services.realtime.subscribeToTable('job_cart', {
            event: 'INSERT'
        }, async (payload) => {
            console.log('🛒 New job cart detected:', payload);
            
            // Notify relevant service providers
            await this.services.notificationSystem.checkAndNotifyJobCart(payload.new);
        });
    }

    /**
     * Set up quotation notifications
     */
    setupQuotationNotifications() {
        // Listen for new quotations
        this.services.realtime.subscribeToTable('quotation', {
            event: 'INSERT'
        }, async (payload) => {
            console.log('💰 New quotation detected:', payload);
            
            // Notify client of new quotation
            await this.services.notificationSystem.notifyClientOfNewQuotation(payload.new);
        });
    }

    /**
     * Set up booking notifications
     */
    setupBookingNotifications() {
        // Listen for booking updates
        this.services.realtime.subscribeToTable('booking', {
            event: 'UPDATE'
        }, async (payload) => {
            console.log('📅 Booking update detected:', payload);
            
            // Handle booking status changes
            this.services.notificationSystem.handleBookingStatusChange(
                payload.new, 
                payload.old
            );
        });
    }

    /**
     * Set up real-time UI updates
     */
    setupRealTimeUIUpdates() {
        // Register callbacks for UI updates
        this.services.notificationSystem.on('new_notification', (notification) => {
            this.updateNotificationUI(notification);
        });

        this.services.notificationSystem.on('job_cart_update', (payload) => {
            this.updateJobCartUI(payload);
        });

        this.services.notificationSystem.on('quotation_update', (payload) => {
            this.updateQuotationUI(payload);
        });
    }

    /**
     * Update notification UI
     */
    updateNotificationUI(notification) {
        // Dispatch custom event for UI updates
        window.dispatchEvent(new CustomEvent('notificationReceived', {
            detail: { notification }
        }));
    }

    /**
     * Update job cart UI
     */
    updateJobCartUI(payload) {
        // Dispatch custom event for job cart updates
        window.dispatchEvent(new CustomEvent('jobCartUpdated', {
            detail: { payload }
        }));
    }

    /**
     * Update quotation UI
     */
    updateQuotationUI(payload) {
        // Dispatch custom event for quotation updates
        window.dispatchEvent(new CustomEvent('quotationUpdated', {
            detail: { payload }
        }));
    }

    /**
     * Get service instance
     */
    getService(serviceName) {
        return this.services[serviceName];
    }

    /**
     * Check if system is initialized
     */
    isReady() {
        return this.isInitialized;
    }

    /**
     * Get system status
     */
    getStatus() {
        return {
            initialized: this.isInitialized,
            services: Object.keys(this.services).reduce((acc, key) => {
                acc[key] = this.services[key] !== null;
                return acc;
            }, {})
        };
    }

    /**
     * Cleanup all services
     */
    cleanup() {
        try {
            // Cleanup notification system
            if (this.services.notificationSystem) {
                this.services.notificationSystem.cleanup();
            }

            // Cleanup real-time service
            if (this.services.realtime) {
                this.services.realtime.cleanup();
            }

            // Reset state
            this.services = {
                supabase: null,
                database: null,
                realtime: null,
                jobCartManager: null,
                notificationSystem: null
            };
            this.isInitialized = false;

            console.log('🧹 Dual Workflow System cleaned up');
        } catch (error) {
            console.error('❌ Cleanup failed:', error);
        }
    }
}

// Global instance
window.dualWorkflowIntegration = new DualWorkflowIntegration();

// Auto-initialize when all required scripts are loaded
document.addEventListener('DOMContentLoaded', async function() {
    // Wait for all scripts to load
    setTimeout(async () => {
        try {
            await window.dualWorkflowIntegration.initialize();
        } catch (error) {
            console.error('❌ Auto-initialization failed:', error);
        }
    }, 2000); // Wait 2 seconds for all scripts to load
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = DualWorkflowIntegration;
}
