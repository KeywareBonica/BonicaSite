/**
 * Enhanced Real-Time Quotation System
 * Provides comprehensive real-time features for quotations
 */

class EnhancedQuotationRealtime {
    constructor(supabaseClient) {
        this.supabase = supabaseClient;
        this.subscriptions = new Map();
        this.quotationCounts = new Map();
        this.statusCallbacks = new Map();
        this.isConnected = false;
    }

    /**
     * Initialize real-time quotation system
     */
    async initialize() {
        console.log('🔄 Initializing Enhanced Quotation Real-Time System...');
        
        try {
            // Subscribe to quotation changes
            await this.subscribeToQuotations();
            
            // Subscribe to job cart changes (affects quotation availability)
            await this.subscribeToJobCarts();
            
            // Subscribe to service provider changes (affects quotation providers)
            await this.subscribeToServiceProviders();
            
            this.isConnected = true;
            console.log('✅ Enhanced Quotation Real-Time System initialized');
            
            // Start periodic status updates
            this.startPeriodicUpdates();
            
        } catch (error) {
            console.error('❌ Failed to initialize Enhanced Quotation Real-Time System:', error);
            throw error;
        }
    }

    /**
     * Subscribe to quotation table changes
     */
    async subscribeToQuotations() {
        const subscription = this.supabase
            .channel('quotation-changes')
            .on(
                'postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'quotation'
                },
                (payload) => {
                    this.handleQuotationChange(payload);
                }
            )
            .subscribe();

        this.subscriptions.set('quotations', subscription);
        console.log('📡 Subscribed to quotation changes');
    }

    /**
     * Subscribe to job cart changes
     */
    async subscribeToJobCarts() {
        const subscription = this.supabase
            .channel('job-cart-changes')
            .on(
                'postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'job_cart'
                },
                (payload) => {
                    this.handleJobCartChange(payload);
                }
            )
            .subscribe();

        this.subscriptions.set('job_carts', subscription);
        console.log('📡 Subscribed to job cart changes');
    }

    /**
     * Subscribe to service provider changes
     */
    async subscribeToServiceProviders() {
        const subscription = this.supabase
            .channel('service-provider-changes')
            .on(
                'postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'service_provider'
                },
                (payload) => {
                    this.handleServiceProviderChange(payload);
                }
            )
            .subscribe();

        this.subscriptions.set('service_providers', subscription);
        console.log('📡 Subscribed to service provider changes');
    }

    /**
     * Handle quotation changes
     */
    handleQuotationChange(payload) {
        const { eventType, new: newRecord, old: oldRecord } = payload;
        
        console.log('📊 Quotation change detected:', eventType, newRecord);

        switch (eventType) {
            case 'INSERT':
                this.handleNewQuotation(newRecord);
                break;
            case 'UPDATE':
                this.handleQuotationUpdate(newRecord, oldRecord);
                break;
            case 'DELETE':
                this.handleQuotationDelete(oldRecord);
                break;
        }

        // Update quotation counts
        this.updateQuotationCounts();
        
        // Notify all registered callbacks
        this.notifyStatusCallbacks('quotation', { eventType, newRecord, oldRecord });
    }

    /**
     * Handle new quotation
     */
    handleNewQuotation(quotation) {
        console.log('🆕 New quotation received:', quotation);
        
        // Show notification
        this.showQuotationNotification('new', quotation);
        
        // Update UI
        this.addQuotationToUI(quotation);
        
        // Update counters
        this.incrementQuotationCount(quotation.job_cart_id);
        
        // Play notification sound
        this.playNotificationSound('new_quotation');
        
        // Update progress indicators
        this.updateProgressIndicators();
    }

    /**
     * Handle quotation update
     */
    handleQuotationUpdate(newRecord, oldRecord) {
        console.log('🔄 Quotation updated:', newRecord);
        
        // Check for status changes
        if (newRecord.quotation_status !== oldRecord.quotation_status) {
            this.showQuotationNotification('status_change', newRecord, oldRecord);
            this.playNotificationSound('status_change');
        }
        
        // Check for price changes
        if (newRecord.quotation_price !== oldRecord.quotation_price) {
            this.showQuotationNotification('price_change', newRecord, oldRecord);
        }
        
        // Update UI
        this.updateQuotationInUI(newRecord);
        
        // Update progress indicators
        this.updateProgressIndicators();
    }

    /**
     * Handle quotation deletion
     */
    handleQuotationDelete(quotation) {
        console.log('🗑️ Quotation deleted:', quotation);
        
        // Show notification
        this.showQuotationNotification('deleted', quotation);
        
        // Remove from UI
        this.removeQuotationFromUI(quotation.quotation_id);
        
        // Update counters
        this.decrementQuotationCount(quotation.job_cart_id);
        
        // Update progress indicators
        this.updateProgressIndicators();
    }

    /**
     * Handle job cart changes
     */
    handleJobCartChange(payload) {
        const { eventType, new: newRecord, old: oldRecord } = payload;
        
        console.log('📦 Job cart change detected:', eventType, newRecord);

        switch (eventType) {
            case 'INSERT':
                this.handleNewJobCart(newRecord);
                break;
            case 'UPDATE':
                this.handleJobCartUpdate(newRecord, oldRecord);
                break;
            case 'DELETE':
                this.handleJobCartDelete(oldRecord);
                break;
        }
    }

    /**
     * Handle new job cart
     */
    handleNewJobCart(jobCart) {
        console.log('🆕 New job cart created:', jobCart);
        
        // Initialize quotation count for this job cart
        this.quotationCounts.set(jobCart.job_cart_id, 0);
        
        // Show notification to service providers
        this.showJobCartNotification('new', jobCart);
        
        // Update progress indicators
        this.updateProgressIndicators();
    }

    /**
     * Handle job cart update
     */
    handleJobCartUpdate(newRecord, oldRecord) {
        console.log('🔄 Job cart updated:', newRecord);
        
        // Check for status changes
        if (newRecord.job_cart_status !== oldRecord.job_cart_status) {
            this.showJobCartNotification('status_change', newRecord, oldRecord);
        }
    }

    /**
     * Handle job cart deletion
     */
    handleJobCartDelete(jobCart) {
        console.log('🗑️ Job cart deleted:', jobCart);
        
        // Remove quotation count
        this.quotationCounts.delete(jobCart.job_cart_id);
        
        // Update progress indicators
        this.updateProgressIndicators();
    }

    /**
     * Handle service provider changes
     */
    handleServiceProviderChange(payload) {
        const { eventType, new: newRecord, old: oldRecord } = payload;
        
        console.log('👤 Service provider change detected:', eventType, newRecord);

        switch (eventType) {
            case 'UPDATE':
                // Update provider info in quotation displays
                this.updateProviderInfo(newRecord);
                break;
        }
    }

    /**
     * Show quotation notification
     */
    showQuotationNotification(type, quotation, oldQuotation = null) {
        const notification = this.createNotificationElement(type, quotation, oldQuotation);
        
        // Add to notification container
        const container = document.getElementById('quotation-notifications') || this.createNotificationContainer();
        container.appendChild(notification);
        
        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 5000);
        
        // Animate in
        setTimeout(() => {
            notification.classList.add('show');
        }, 100);
    }

    /**
     * Create notification element
     */
    createNotificationElement(type, quotation, oldQuotation = null) {
        const notification = document.createElement('div');
        notification.className = `quotation-notification ${type}`;
        
        let message = '';
        let icon = '';
        
        switch (type) {
            case 'new':
                message = `New quotation received for ${quotation.job_cart_id}`;
                icon = '💰';
                break;
            case 'status_change':
                message = `Quotation status changed to ${quotation.quotation_status}`;
                icon = '🔄';
                break;
            case 'price_change':
                message = `Quotation price updated to R${quotation.quotation_price}`;
                icon = '💵';
                break;
            case 'deleted':
                message = 'A quotation was removed';
                icon = '🗑️';
                break;
        }
        
        notification.innerHTML = `
            <div class="notification-content">
                <span class="notification-icon">${icon}</span>
                <span class="notification-message">${message}</span>
                <button class="notification-close" onclick="this.parentNode.parentNode.remove()">×</button>
            </div>
        `;
        
        return notification;
    }

    /**
     * Create notification container
     */
    createNotificationContainer() {
        const container = document.createElement('div');
        container.id = 'quotation-notifications';
        container.className = 'quotation-notifications-container';
        document.body.appendChild(container);
        return container;
    }

    /**
     * Show job cart notification
     */
    showJobCartNotification(type, jobCart, oldJobCart = null) {
        console.log(`📦 Job cart notification (${type}):`, jobCart);
        
        // This would typically show notifications to service providers
        // For now, just log the event
    }

    /**
     * Add quotation to UI
     */
    addQuotationToUI(quotation) {
        // Find the quotations list container
        const quotationsList = document.getElementById('quotations-list');
        if (!quotationsList) return;
        
        // Create quotation element
        const quotationElement = this.createQuotationElement(quotation);
        
        // Add with animation
        quotationElement.classList.add('new-quotation');
        quotationsList.appendChild(quotationElement);
        
        // Remove animation class after animation completes
        setTimeout(() => {
            quotationElement.classList.remove('new-quotation');
        }, 1000);
    }

    /**
     * Update quotation in UI
     */
    updateQuotationInUI(quotation) {
        const quotationElement = document.querySelector(`[data-quotation-id="${quotation.quotation_id}"]`);
        if (!quotationElement) return;
        
        // Update content
        this.updateQuotationElement(quotationElement, quotation);
        
        // Add update animation
        quotationElement.classList.add('updated-quotation');
        setTimeout(() => {
            quotationElement.classList.remove('updated-quotation');
        }, 1000);
    }

    /**
     * Remove quotation from UI
     */
    removeQuotationFromUI(quotationId) {
        const quotationElement = document.querySelector(`[data-quotation-id="${quotationId}"]`);
        if (!quotationElement) return;
        
        // Add removal animation
        quotationElement.classList.add('removing-quotation');
        
        setTimeout(() => {
            if (quotationElement.parentNode) {
                quotationElement.parentNode.removeChild(quotationElement);
            }
        }, 500);
    }

    /**
     * Create quotation element
     */
    createQuotationElement(quotation) {
        const element = document.createElement('div');
        element.className = 'quotation-card';
        element.setAttribute('data-quotation-id', quotation.quotation_id);
        
        element.innerHTML = `
            <div class="quotation-header">
                <h4>Quotation #${quotation.quotation_id.slice(-8)}</h4>
                <span class="quotation-status status-${quotation.quotation_status}">
                    ${quotation.quotation_status}
                </span>
            </div>
            <div class="quotation-content">
                <div class="quotation-price">
                    <strong>R${quotation.quotation_price}</strong>
                </div>
                <div class="quotation-details">
                    ${quotation.quotation_details || 'No details provided'}
                </div>
                <div class="quotation-meta">
                    <small>Submitted: ${new Date(quotation.created_at).toLocaleString()}</small>
                </div>
            </div>
        `;
        
        return element;
    }

    /**
     * Update quotation element
     */
    updateQuotationElement(element, quotation) {
        const statusElement = element.querySelector('.quotation-status');
        const priceElement = element.querySelector('.quotation-price strong');
        const detailsElement = element.querySelector('.quotation-details');
        
        if (statusElement) {
            statusElement.className = `quotation-status status-${quotation.quotation_status}`;
            statusElement.textContent = quotation.quotation_status;
        }
        
        if (priceElement) {
            priceElement.textContent = `R${quotation.quotation_price}`;
        }
        
        if (detailsElement) {
            detailsElement.textContent = quotation.quotation_details || 'No details provided';
        }
    }

    /**
     * Update quotation counts
     */
    updateQuotationCounts() {
        // Update global quotation counter
        const totalQuotations = Array.from(this.quotationCounts.values()).reduce((sum, count) => sum + count, 0);
        
        const counterElement = document.getElementById('quotation-counter');
        if (counterElement) {
            counterElement.textContent = totalQuotations;
            counterElement.classList.add('updated');
            setTimeout(() => counterElement.classList.remove('updated'), 1000);
        }
        
        // Update individual job cart counters
        this.quotationCounts.forEach((count, jobCartId) => {
            const counterElement = document.querySelector(`[data-job-cart-id="${jobCartId}"] .quotation-count`);
            if (counterElement) {
                counterElement.textContent = count;
            }
        });
    }

    /**
     * Increment quotation count for job cart
     */
    incrementQuotationCount(jobCartId) {
        const currentCount = this.quotationCounts.get(jobCartId) || 0;
        this.quotationCounts.set(jobCartId, currentCount + 1);
    }

    /**
     * Decrement quotation count for job cart
     */
    decrementQuotationCount(jobCartId) {
        const currentCount = this.quotationCounts.get(jobCartId) || 0;
        if (currentCount > 0) {
            this.quotationCounts.set(jobCartId, currentCount - 1);
        }
    }

    /**
     * Update progress indicators
     */
    updateProgressIndicators() {
        // Update quotation progress bars
        this.quotationCounts.forEach((count, jobCartId) => {
            const progressElement = document.querySelector(`[data-job-cart-id="${jobCartId}"] .progress-bar`);
            if (progressElement) {
                // Calculate progress based on expected quotations (assume 3 per job cart)
                const progress = Math.min((count / 3) * 100, 100);
                progressElement.style.width = `${progress}%`;
                
                // Update progress text
                const progressText = progressElement.parentNode.querySelector('.progress-text');
                if (progressText) {
                    progressText.textContent = `${count}/3 quotations`;
                }
            }
        });
    }

    /**
     * Play notification sound
     */
    playNotificationSound(type) {
        // Create audio context for notification sounds
        if (!this.audioContext) {
            this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
        }
        
        const oscillator = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(this.audioContext.destination);
        
        // Different sounds for different events
        switch (type) {
            case 'new_quotation':
                oscillator.frequency.setValueAtTime(800, this.audioContext.currentTime);
                oscillator.frequency.exponentialRampToValueAtTime(1200, this.audioContext.currentTime + 0.1);
                break;
            case 'status_change':
                oscillator.frequency.setValueAtTime(600, this.audioContext.currentTime);
                oscillator.frequency.exponentialRampToValueAtTime(800, this.audioContext.currentTime + 0.05);
                break;
        }
        
        gainNode.gain.setValueAtTime(0.3, this.audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.2);
        
        oscillator.start(this.audioContext.currentTime);
        oscillator.stop(this.audioContext.currentTime + 0.2);
    }

    /**
     * Start periodic updates
     */
    startPeriodicUpdates() {
        // Update quotation counts every 30 seconds
        setInterval(() => {
            this.refreshQuotationCounts();
        }, 30000);
        
        // Update connection status every 10 seconds
        setInterval(() => {
            this.checkConnectionStatus();
        }, 10000);
    }

    /**
     * Refresh quotation counts from database
     */
    async refreshQuotationCounts() {
        try {
            const { data, error } = await this.supabase
                .from('quotation')
                .select('job_cart_id')
                .eq('quotation_status', 'pending');
            
            if (error) throw error;
            
            // Reset counts
            this.quotationCounts.clear();
            
            // Count quotations per job cart
            data.forEach(quotation => {
                const currentCount = this.quotationCounts.get(quotation.job_cart_id) || 0;
                this.quotationCounts.set(quotation.job_cart_id, currentCount + 1);
            });
            
            this.updateQuotationCounts();
            
        } catch (error) {
            console.error('❌ Failed to refresh quotation counts:', error);
        }
    }

    /**
     * Check connection status
     */
    checkConnectionStatus() {
        const statusElement = document.getElementById('realtime-status');
        if (statusElement) {
            if (this.isConnected) {
                statusElement.className = 'realtime-status connected';
                statusElement.textContent = '🟢 Real-time Connected';
            } else {
                statusElement.className = 'realtime-status disconnected';
                statusElement.textContent = '🔴 Real-time Disconnected';
            }
        }
    }

    /**
     * Register status callback
     */
    registerStatusCallback(callback) {
        const id = Date.now().toString();
        this.statusCallbacks.set(id, callback);
        return id;
    }

    /**
     * Unregister status callback
     */
    unregisterStatusCallback(id) {
        this.statusCallbacks.delete(id);
    }

    /**
     * Notify status callbacks
     */
    notifyStatusCallbacks(type, data) {
        this.statusCallbacks.forEach(callback => {
            try {
                callback(type, data);
            } catch (error) {
                console.error('❌ Error in status callback:', error);
            }
        });
    }

    /**
     * Update provider info
     */
    updateProviderInfo(provider) {
        // Update provider information in quotation displays
        const providerElements = document.querySelectorAll(`[data-provider-id="${provider.service_provider_id}"]`);
        providerElements.forEach(element => {
            const nameElement = element.querySelector('.provider-name');
            const ratingElement = element.querySelector('.provider-rating');
            
            if (nameElement) {
                nameElement.textContent = `${provider.service_provider_name} ${provider.service_provider_surname}`;
            }
            
            if (ratingElement && provider.service_provider_rating) {
                ratingElement.textContent = `⭐ ${provider.service_provider_rating}`;
            }
        });
    }

    /**
     * Disconnect all subscriptions
     */
    disconnect() {
        this.subscriptions.forEach(subscription => {
            this.supabase.removeChannel(subscription);
        });
        this.subscriptions.clear();
        this.isConnected = false;
        console.log('🔌 Disconnected from Enhanced Quotation Real-Time System');
    }
}

// Export for use in other modules
window.EnhancedQuotationRealtime = EnhancedQuotationRealtime;
















