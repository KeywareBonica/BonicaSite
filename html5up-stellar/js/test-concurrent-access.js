// Test Script for Concurrent Access and Real-time Features
// Run this in browser console to simulate multiple users

class ConcurrentAccessTester {
    constructor() {
        this.testUsers = [
            { type: 'client', email: 'testclient1@example.com', password: 'testpass123' },
            { type: 'client', email: 'testclient2@example.com', password: 'testpass123' },
            { type: 'service_provider', email: 'testprovider1@example.com', password: 'testpass123' },
            { type: 'service_provider', email: 'testprovider2@example.com', password: 'testpass123' },
            { type: 'service_provider', email: 'testprovider3@example.com', password: 'testpass123' }
        ];
        
        this.testResults = [];
    }

    // Create test users if they don't exist
    async createTestUsers() {
        console.log('🧪 Creating test users...');
        
        for (const user of this.testUsers) {
            try {
                const { data, error } = await supabase.auth.signUp({
                    email: user.email,
                    password: user.password
                });

                if (error && !error.message.includes('already registered')) {
                    console.error(`❌ Error creating ${user.email}:`, error);
                } else {
                    console.log(`✅ User ${user.email} ready`);
                }
            } catch (error) {
                console.error(`❌ Error with ${user.email}:`, error);
            }
        }
    }

    // Create test job cart
    async createTestJobCart() {
        console.log('🧪 Creating test job cart...');
        
        try {
            // Get a test client
            const { data: clients } = await supabase
                .from('client')
                .select('client_id')
                .limit(1);

            if (!clients || clients.length === 0) {
                console.error('❌ No clients found. Please create a client first.');
                return null;
            }

            // Create test event
            const { data: event, error: eventError } = await supabase
                .from('event')
                .insert({
                    client_id: clients[0].client_id,
                    event_name: 'Test Wedding',
                    event_date: '2024-12-25',
                    event_location: 'Johannesburg, South Africa',
                    event_start_time: '14:00',
                    event_end_time: '22:00'
                })
                .select('event_id')
                .single();

            if (eventError) throw eventError;

            // Create test job cart
            const { data: jobCart, error: jobCartError } = await supabase
                .from('job_cart')
                .insert({
                    event_id: event.event_id,
                    job_cart_item: 'Photography Services',
                    job_cart_details: 'Full-day wedding photography with 500+ edited photos',
                    job_cart_status: 'available'
                })
                .select('job_cart_id')
                .single();

            if (jobCartError) throw jobCartError;

            console.log(`✅ Test job cart created: ${jobCart.job_cart_id}`);
            return jobCart.job_cart_id;
        } catch (error) {
            console.error('❌ Error creating test job cart:', error);
            return null;
        }
    }

    // Simulate multiple service providers accessing the same job cart
    async simulateConcurrentAccess(jobCartId) {
        console.log('🧪 Simulating concurrent access...');
        
        const providers = this.testUsers.filter(u => u.type === 'service_provider');
        const promises = [];

        providers.forEach((provider, index) => {
            const promise = this.simulateProviderAccess(provider, jobCartId, index);
            promises.push(promise);
        });

        // Execute all provider access attempts simultaneously
        const results = await Promise.all(promises);
        
        console.log('📊 Concurrent Access Results:', results);
        return results;
    }

    // Simulate single provider accessing job cart
    async simulateProviderAccess(provider, jobCartId, delay = 0) {
        return new Promise(async (resolve) => {
            // Add random delay to simulate real-world timing
            setTimeout(async () => {
                try {
                    console.log(`👤 ${provider.email} attempting to access job cart...`);
                    
                    // Simulate the accept job cart call
                    const result = await jobCartManager.acceptJobCart(jobCartId, provider.email);
                    
                    const testResult = {
                        provider: provider.email,
                        success: result.success,
                        message: result.message,
                        timestamp: new Date().toISOString()
                    };
                    
                    console.log(`📋 ${provider.email} result:`, testResult);
                    resolve(testResult);
                    
                } catch (error) {
                    console.error(`❌ Error for ${provider.email}:`, error);
                    resolve({
                        provider: provider.email,
                        success: false,
                        message: error.message,
                        timestamp: new Date().toISOString()
                    });
                }
            }, delay * 1000 + Math.random() * 2000); // Random delay between 0-2 seconds
        });
    }

    // Test real-time notifications
    async testRealTimeNotifications() {
        console.log('🧪 Testing real-time notifications...');
        
        // Set up real-time subscription
        const channel = supabase
            .channel('test-notifications')
            .on('postgres_changes', 
                { 
                    event: 'INSERT', 
                    schema: 'public', 
                    table: 'job_cart_acceptance' 
                }, 
                (payload) => {
                    console.log('🔔 Real-time notification received:', payload);
                    this.showNotification(`Real-time update: ${payload.new.acceptance_status}`, 'success');
                }
            )
            .subscribe();

        console.log('✅ Real-time subscription active');
        return channel;
    }

    // Test customer quotation viewing
    async testCustomerQuotationFlow() {
        console.log('🧪 Testing customer quotation flow...');
        
        try {
            // Create a quotation for testing
            const { data: providers } = await supabase
                .from('service_provider')
                .select('service_provider_id')
                .limit(1);

            if (!providers || providers.length === 0) {
                console.error('❌ No service providers found');
                return;
            }

            const { data: jobCarts } = await supabase
                .from('job_cart')
                .select('job_cart_id')
                .limit(1);

            if (!jobCarts || jobCarts.length === 0) {
                console.error('❌ No job carts found');
                return;
            }

            // Create test quotation
            const { data: quotation, error } = await supabase
                .from('quotation')
                .insert({
                    service_provider_id: providers[0].service_provider_id,
                    job_cart_id: jobCarts[0].job_cart_id,
                    quotation_price: 2500.00,
                    quotation_details: 'Test quotation for concurrent access testing',
                    quotation_file_name: 'test-quotation.pdf',
                    quotation_status: 'pending'
                })
                .select('quotation_id')
                .single();

            if (error) throw error;

            console.log('✅ Test quotation created:', quotation.quotation_id);
            
            // Simulate customer viewing quotations
            setTimeout(() => {
                this.simulateCustomerViewingQuotations();
            }, 2000);

        } catch (error) {
            console.error('❌ Error testing customer flow:', error);
        }
    }

    // Simulate customer viewing quotations
    simulateCustomerViewingQuotations() {
        console.log('👥 Simulating customer viewing quotations...');
        
        // Check if quotation page exists
        if (window.location.pathname.includes('quotation.html')) {
            console.log('✅ Customer is on quotation page');
            
            // Simulate loading quotations
            setTimeout(() => {
                this.showNotification('Customer can now see uploaded quotations', 'info');
            }, 1000);
        } else {
            console.log('ℹ️ Navigate to quotation.html to test customer view');
        }
    }

    // Show notification
    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `test-notification test-notification-${type}`;
        notification.textContent = message;
        
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 15px 20px;
            border-radius: 5px;
            color: white;
            font-weight: 500;
            z-index: 9999;
            max-width: 400px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            animation: slideIn 0.3s ease;
        `;
        
        switch (type) {
            case 'success':
                notification.style.backgroundColor = '#10b981';
                break;
            case 'error':
                notification.style.backgroundColor = '#ef4444';
                break;
            case 'warning':
                notification.style.backgroundColor = '#f59e0b';
                break;
            default:
                notification.style.backgroundColor = '#3b82f6';
        }
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 5000);
    }

    // Run complete test suite
    async runFullTest() {
        console.log('🚀 Starting Concurrent Access Test Suite...');
        
        try {
            // Step 1: Create test users
            await this.createTestUsers();
            
            // Step 2: Create test job cart
            const jobCartId = await this.createTestJobCart();
            if (!jobCartId) return;
            
            // Step 3: Set up real-time notifications
            await this.testRealTimeNotifications();
            
            // Step 4: Simulate concurrent access
            const results = await this.simulateConcurrentAccess(jobCartId);
            
            // Step 5: Test customer quotation flow
            await this.testCustomerQuotationFlow();
            
            // Step 6: Generate test report
            this.generateTestReport(results);
            
        } catch (error) {
            console.error('❌ Test suite failed:', error);
        }
    }

    // Generate test report
    generateTestReport(results) {
        console.log('📊 CONCURRENT ACCESS TEST REPORT');
        console.log('================================');
        
        const successful = results.filter(r => r.success).length;
        const failed = results.filter(r => !r.success).length;
        
        console.log(`✅ Successful accesses: ${successful}`);
        console.log(`❌ Failed accesses: ${failed}`);
        console.log(`📈 Success rate: ${(successful / results.length * 100).toFixed(1)}%`);
        
        console.log('\nDetailed Results:');
        results.forEach((result, index) => {
            console.log(`${index + 1}. ${result.provider}: ${result.success ? '✅' : '❌'} - ${result.message}`);
        });
        
        // Test passed if only one provider succeeded (expected behavior)
        if (successful === 1) {
            console.log('\n🎉 TEST PASSED: Concurrent access control working correctly!');
        } else if (successful > 1) {
            console.log('\n⚠️ TEST WARNING: Multiple providers accepted the same job cart');
        } else {
            console.log('\n❌ TEST FAILED: No providers could access the job cart');
        }
    }
}

// Usage instructions
console.log(`
🧪 CONCURRENT ACCESS TESTER LOADED
================================

To run tests:

1. Basic test:
   const tester = new ConcurrentAccessTester();
   await tester.runFullTest();

2. Individual tests:
   await tester.createTestUsers();
   await tester.simulateConcurrentAccess('your-job-cart-id');
   await tester.testRealTimeNotifications();

3. Manual testing:
   - Open multiple browser windows
   - Login as different service providers
   - Try to accept the same job cart simultaneously
   - Watch for real-time updates

4. Network simulation:
   - Open DevTools → Network tab
   - Set throttling to "Slow 3G"
   - Test concurrent access with network delays
`);

// Make tester available globally
window.ConcurrentAccessTester = ConcurrentAccessTester;
