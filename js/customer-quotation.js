// Customer Quotation Management System
// Handles viewing and selecting quotations from service providers

// Supabase configuration
const SUPABASE_URL = "https://spudtrptbyvwyhvistdf.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwdWR0cnB0Ynl2d3lodmlzdGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2OTk4NjgsImV4cCI6MjA3MTI3NTg2OH0.GBo-RtgbRZCmhSAZi0c5oXynMiJNeyrs0nLsk3CaV8A";
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

let selectedQuotation = null;
let clientId = null;

// Initialize the quotation system
document.addEventListener('DOMContentLoaded', async function() {
    try {
        // Check authentication
        const { data: { user }, error: authError } = await supabase.auth.getUser();
        if (authError || !user) {
            console.warn("User not logged in, using test mode:", authError);
            // For testing purposes, use a test client ID
            clientId = 'test-client-id';
            showMessage("Running in test mode - showing sample quotations", "warning");
        } else {
            clientId = user.id;
            console.log("User authenticated:", user.email);
        }

        await loadClientQuotations();
        setupRealtimeSubscriptions();
        
    } catch (error) {
        console.error("Error initializing quotation system:", error);
        showMessage("Error loading quotations", "error");
    }
});

// Load quotations for the logged-in client
async function loadClientQuotations() {
    try {
        showLoading(true);
        
        // First, check if we have quotations from the booking process
        const createdJobCarts = localStorage.getItem('createdJobCarts');
        if (createdJobCarts) {
            console.log('📦 Found job carts from booking process, loading those quotations...');
            await loadBookingsQuotations();
            return;
        }
        
        // Otherwise, try to load from database
        const { data: jobCarts, error } = await supabase
            .from('job_cart')
            .select(`
                job_cart_id,
                job_cart_item,
                job_cart_details,
                job_cart_status,
                client_id,
                event:event_id (
                    event_id,
                    event_name,
                    event_date,
                    event_location,
                    event_start_time,
                    event_end_time
                ),
                quotations:quotation (
                    quotation_id,
                    quotation_price,
                    quotation_details,
                    quotation_file_path,
                    quotation_file_name,
                    quotation_submission_date,
                    quotation_submission_time,
                    quotation_status,
                    service_provider:service_provider_id (
                        service_provider_id,
                        service_provider_name,
                        service_provider_surname,
                        service_provider_rating,
                        service_provider_location
                    )
                )
            `)
            .eq('client_id', clientId)
            .in('job_cart_status', ['pending', 'in_progress', 'available']);

        if (error) throw error;

        const jobCartsWithQuotations = jobCarts.filter(cart => 
            cart.quotations && cart.quotations.length > 0
        );

        if (jobCartsWithQuotations.length === 0) {
            // If no real quotations, show sample quotations for testing
            console.log('No real quotations found, showing sample quotations...');
            showSampleQuotations();
            return;
        }

        displayQuotations(jobCartsWithQuotations);
        
    } catch (error) {
        console.error("Error loading quotations:", error);
        showMessage("Error loading quotations", "error");
    } finally {
        showLoading(false);
    }
}

// Load quotations that were generated in the booking process
async function loadBookingsQuotations() {
    try {
        const createdJobCarts = localStorage.getItem('createdJobCarts');
        if (!createdJobCarts) {
            console.log('ℹ️ No job carts in localStorage, showing sample quotations...');
            showSampleQuotations();
            return;
        }
        
        const jobCartIds = JSON.parse(createdJobCarts);
        console.log('📋 Loading quotations for job carts:', jobCartIds);
        
        const quotationsList = document.getElementById('quotations-list');
        const quotationsContainer = document.getElementById('quotations-container');
        const quotationCount = document.getElementById('quotation-count');
        
        quotationsList.innerHTML = '';
        
        let hasQuotations = false;
        let totalQuotations = 0;
        
        // Load quotations for each job cart
        for (const jobCartId of jobCartIds) {
            const { data: quotations, error } = await supabase
                .from('quotation')
                .select(`
                    quotation_id,
                    quotation_price,
                    quotation_details,
                    quotation_file_path,
                    quotation_file_name,
                    quotation_submission_date,
                    quotation_submission_time,
                    quotation_status,
                    job_cart:job_cart_id (
                        job_cart_item,
                        job_cart_details
                    ),
                    service_provider:service_provider_id (
                        service_provider_id,
                        service_provider_name,
                        service_provider_surname,
                        service_provider_rating,
                        service_provider_location
                    )
                `)
                .eq('job_cart_id', jobCartId)
                .eq('quotation_status', 'pending');

            if (error) {
                console.error('Error loading quotations for job cart:', jobCartId, error);
                continue;
            }

            if (quotations && quotations.length > 0) {
                hasQuotations = true;
                totalQuotations += quotations.length;
                
                // Create job cart section
                const jobCartSection = document.createElement('div');
                jobCartSection.className = 'job-cart-section';
                jobCartSection.innerHTML = `
                    <div class="service-header">
                        <h3><i class="fas fa-cog me-2"></i>${quotations[0].job_cart.job_cart_item}</h3>
                        <p class="job-cart-details">${quotations[0].job_cart.job_cart_details}</p>
                        <div class="service-info">
                            <span class="service-badge">${quotations.length} quotation${quotations.length !== 1 ? 's' : ''} available</span>
                            <span class="selection-note">Select one quotation for this service</span>
                        </div>
                    </div>
                    <div class="quotations-grid" data-job-cart-id="${jobCartId}" data-service="${quotations[0].job_cart.job_cart_item}">
                        ${quotations.map((quotation, index) => createQuotationCard(quotation, quotations[0].job_cart.job_cart_item, index)).join('')}
                    </div>
                `;
                
                quotationsList.appendChild(jobCartSection);
            }
        }
        
        if (hasQuotations) {
            quotationCount.textContent = `${totalQuotations} quotation${totalQuotations !== 1 ? 's' : ''} available`;
            quotationsContainer.style.display = 'block';
            showMessage("Quotations loaded successfully from booking process!", "success");
        } else {
            // Fallback to sample quotations
            console.log('No quotations found in database, showing sample quotations...');
            showSampleQuotations();
        }
        
    } catch (error) {
        console.error("Error loading bookings quotations:", error);
        // Fallback to sample quotations
        showSampleQuotations();
    }
}

// Display quotations in the UI
function displayQuotations(jobCartsWithQuotations) {
    const quotationsList = document.getElementById('quotations-list');
    const quotationsContainer = document.getElementById('quotations-container');
    const quotationCount = document.getElementById('quotation-count');
    
    quotationsList.innerHTML = '';
    
    let totalQuotations = 0;
    
    jobCartsWithQuotations.forEach(jobCart => {
        totalQuotations += jobCart.quotations.length;
        
        const jobCartSection = document.createElement('div');
        jobCartSection.className = 'job-cart-section';
        jobCartSection.innerHTML = `
            <div class="service-header">
                <h3><i class="fas fa-cog me-2"></i>${jobCart.job_cart_item}</h3>
                <p class="job-cart-details">${jobCart.job_cart_details}</p>
                <div class="service-info">
                    <span class="service-badge">${jobCart.quotations.length} quotation${jobCart.quotations.length !== 1 ? 's' : ''} available</span>
                    <span class="selection-note">Select one quotation for this service</span>
                </div>
            </div>
            <div class="quotations-grid" data-job-cart-id="${jobCart.job_cart_id}" data-service="${jobCart.job_cart_item}">
                ${jobCart.quotations.map((quotation, index) => createQuotationCard(quotation, jobCart.job_cart_item, index)).join('')}
            </div>
        `;
        
        quotationsList.appendChild(jobCartSection);
    });
    
    quotationCount.textContent = `${totalQuotations} quotation${totalQuotations !== 1 ? 's' : ''} available`;
    quotationsContainer.style.display = 'block';
}

// Create quotation card element
function createQuotationCard(quotation) {
    const provider = quotation.service_provider;
    const providerName = `${provider.service_provider_name} ${provider.service_provider_surname}`;
    
    return `
        <div class="quotation-card" data-quotation-id="${quotation.quotation_id}">
            <div class="quotation-header">
                <h4>${providerName}</h4>
                <div class="rating">
                    <i class="fas fa-star"></i>
                    <span>${provider.service_provider_rating || 'N/A'}</span>
                </div>
            </div>
            
            <div class="quotation-details">
                <div class="price">
                    <span class="currency">R</span>
                    <span class="amount">${quotation.quotation_price.toLocaleString()}</span>
                </div>
                
                <div class="provider-info">
                    <p><i class="fas fa-map-marker-alt"></i> ${provider.service_provider_location || 'N/A'}</p>
                    <p><i class="fas fa-calendar"></i> Submitted: ${new Date(quotation.quotation_submission_date).toLocaleDateString()}</p>
                </div>
            </div>
            
            <div class="quotation-description">
                <p>${quotation.quotation_details}</p>
            </div>
            
            <div class="quotation-actions">
                <button class="btn-select" onclick="selectQuotation('${quotation.quotation_id}')">
                    Select This Quote
                </button>
                <button class="btn-view-file" onclick="viewQuotationFile('${quotation.quotation_file_path}')">
                    View File
                </button>
            </div>
        </div>
    `;
}

// Select a quotation
function selectQuotation(quotationId) {
    document.querySelectorAll('.quotation-card').forEach(card => {
        card.classList.remove('selected');
    });
    
    const selectedCard = document.querySelector(`[data-quotation-id="${quotationId}"]`);
    selectedCard.classList.add('selected');
    
    selectedQuotation = quotationId;
    
    // For sample quotations, show a simple details view
    if (quotationId.startsWith('sample-quote-')) {
        showSampleQuotationDetails(quotationId);
    } else {
        showQuotationDetails(quotationId);
    }
}

// Make selectQuotation globally accessible
window.selectQuotation = selectQuotation;

// Show quotation details
async function showQuotationDetails(quotationId) {
    try {
        const { data: quotation, error } = await supabase
            .from('quotation')
            .select(`
                *,
                service_provider:service_provider_id (
                    service_provider_name,
                    service_provider_surname,
                    service_provider_rating,
                    service_provider_location,
                    service_provider_contact
                ),
                job_cart:job_cart_id (
                    job_cart_item,
                    job_cart_details
                )
            `)
            .eq('quotation_id', quotationId)
            .single();

        if (error) throw error;

        const detailsContent = document.getElementById('selected-quotation-content');
        const detailsSection = document.getElementById('quotation-details');
        
        detailsContent.innerHTML = `
            <div class="quotation-detail-card">
                <h4>${quotation.job_cart.job_cart_item}</h4>
                <p class="quotation-detail-description">${quotation.quotation_details}</p>
                
                <div class="quotation-detail-info">
                    <div class="price-section">
                        <h5>Total Price</h5>
                        <div class="price-large">R ${quotation.quotation_price.toLocaleString()}</div>
                    </div>
                    
                    <div class="provider-section">
                        <h5>Service Provider</h5>
                        <p><strong>${quotation.service_provider.service_provider_name} ${quotation.service_provider.service_provider_surname}</strong></p>
                        <p><i class="fas fa-star"></i> Rating: ${quotation.service_provider.service_provider_rating || 'N/A'}</p>
                        <p><i class="fas fa-map-marker-alt"></i> ${quotation.service_provider.service_provider_location || 'N/A'}</p>
                        <p><i class="fas fa-phone"></i> ${quotation.service_provider.service_provider_contact || 'N/A'}</p>
                    </div>
                    
                    <div class="submission-section">
                        <h5>Submission Details</h5>
                        <p><i class="fas fa-calendar"></i> Submitted: ${new Date(quotation.quotation_submission_date).toLocaleDateString()}</p>
                        <p><i class="fas fa-clock"></i> Time: ${quotation.quotation_submission_time}</p>
                        <p><i class="fas fa-file"></i> File: ${quotation.quotation_file_name}</p>
                    </div>
                </div>
            </div>
        `;
        
        detailsSection.style.display = 'block';
        detailsSection.scrollIntoView({ behavior: 'smooth' });
        
    } catch (error) {
        console.error("Error loading quotation details:", error);
        showMessage("Error loading quotation details", "error");
    }
}

// Accept quotation
async function acceptQuotation() {
    if (!selectedQuotation) {
        showMessage("Please select a quotation first", "error");
        return;
    }

    try {
        const { error } = await supabase
            .from('quotation')
            .update({ quotation_status: 'accepted' })
            .eq('quotation_id', selectedQuotation);

        if (error) throw error;

        showMessage("Quotation accepted successfully! Redirecting to payment...", "success");
        
        // Calculate total and store for payment page
        await calculateAndStorePaymentTotal();
        
        // Redirect to payment page after a short delay
        setTimeout(() => {
            window.location.href = 'payment.html';
        }, 2000);
        
    } catch (error) {
        console.error("Error accepting quotation:", error);
        showMessage("Error accepting quotation", "error");
    }
}

// Reject quotation
async function rejectQuotation() {
    if (!selectedQuotation) {
        showMessage("Please select a quotation first", "error");
        return;
    }

    if (!confirm("Are you sure you want to reject this quotation?")) {
        return;
    }

    try {
        const { error } = await supabase
            .from('quotation')
            .update({ quotation_status: 'rejected' })
            .eq('quotation_id', selectedQuotation);

        if (error) throw error;

        showMessage("Quotation rejected", "info");
        
        const quotationCard = document.querySelector(`[data-quotation-id="${selectedQuotation}"]`);
        if (quotationCard) {
            quotationCard.remove();
        }
        
        document.getElementById('quotation-details').style.display = 'none';
        selectedQuotation = null;
        
    } catch (error) {
        console.error("Error rejecting quotation:", error);
        showMessage("Error rejecting quotation", "error");
    }
}

// View quotation file
async function viewQuotationFile(filePath) {
    try {
        const { data } = await supabase.storage
            .from('quotations')
            .createSignedUrl(filePath, 3600);

        if (data?.signedUrl) {
            window.open(data.signedUrl, '_blank');
        } else {
            showMessage("Error generating file link", "error");
        }
    } catch (error) {
        console.error("Error viewing file:", error);
        showMessage("Error viewing file", "error");
    }
}

// Check for new quotations (refresh functionality)
async function checkForQuotations() {
    await loadClientQuotations();
}

// Setup real-time subscriptions
function setupRealtimeSubscriptions() {
    supabase
        .channel('quotation-changes')
        .on('postgres_changes', 
            { 
                event: 'INSERT', 
                schema: 'public', 
                table: 'quotation' 
            }, 
            (payload) => {
                console.log('New quotation received:', payload);
                showMessage("New quotation available!", "success");
                loadClientQuotations();
            }
        )
        .subscribe();
}

// Show loading state
function showLoading(show) {
    const loadingIndicator = document.getElementById('loading-indicator');
    loadingIndicator.style.display = show ? 'block' : 'none';
}

// Show no quotations message
function showNoQuotations() {
    document.getElementById('no-quotations').style.display = 'block';
}

// Show sample quotations for testing
function showSampleQuotations() {
    console.log('🎭 Showing sample quotations...');
    
    const quotationsList = document.getElementById('quotations-list');
    const quotationsContainer = document.getElementById('quotations-container');
    const quotationCount = document.getElementById('quotation-count');
    
    quotationsList.innerHTML = '';
    
    // Sample job cart with quotations
    const sampleJobCarts = [
        {
            job_cart_id: 'sample-1',
            job_cart_item: 'Photography & Videography',
            job_cart_details: 'Professional photography and videography services for your special event',
            quotations: [
                {
                    quotation_id: 'sample-quote-1',
                    quotation_price: 2500,
                    quotation_details: 'Full-day photography coverage with 500+ edited photos and 2-hour highlight video',
                    quotation_submission_date: new Date().toISOString().split('T')[0],
                    quotation_submission_time: '10:30:00',
                    quotation_status: 'pending',
                    service_provider: {
                        service_provider_name: 'Sarah',
                        service_provider_surname: 'Johnson',
                        service_provider_rating: 4.8,
                        service_provider_location: 'Johannesburg'
                    }
                },
                {
                    quotation_id: 'sample-quote-2',
                    quotation_price: 3200,
                    quotation_details: 'Premium photography package with drone footage and same-day preview',
                    quotation_submission_date: new Date().toISOString().split('T')[0],
                    quotation_submission_time: '11:15:00',
                    quotation_status: 'pending',
                    service_provider: {
                        service_provider_name: 'Mike',
                        service_provider_surname: 'Chen',
                        service_provider_rating: 4.9,
                        service_provider_location: 'Sandton'
                    }
                },
                {
                    quotation_id: 'sample-quote-3',
                    quotation_price: 1800,
                    quotation_details: 'Essential photography package with 300+ photos and basic video',
                    quotation_submission_date: new Date().toISOString().split('T')[0],
                    quotation_submission_time: '12:00:00',
                    quotation_status: 'pending',
                    service_provider: {
                        service_provider_name: 'Lisa',
                        service_provider_surname: 'Williams',
                        service_provider_rating: 4.7,
                        service_provider_location: 'Pretoria'
                    }
                }
            ]
        },
        {
            job_cart_id: 'sample-2',
            job_cart_item: 'Catering Services',
            job_cart_details: 'Delicious catering for your special event',
            quotations: [
                {
                    quotation_id: 'sample-quote-4',
                    quotation_price: 1500,
                    quotation_details: 'Buffet-style catering for 50 guests with vegetarian options',
                    quotation_submission_date: new Date().toISOString().split('T')[0],
                    quotation_submission_time: '14:30:00',
                    quotation_status: 'pending',
                    service_provider: {
                        service_provider_name: 'Chef',
                        service_provider_surname: 'Martinez',
                        service_provider_rating: 4.6,
                        service_provider_location: 'Johannesburg'
                    }
                },
                {
                    quotation_id: 'sample-quote-5',
                    quotation_price: 2200,
                    quotation_details: 'Premium plated service with 3-course meal and professional waitstaff',
                    quotation_submission_date: new Date().toISOString().split('T')[0],
                    quotation_submission_time: '15:45:00',
                    quotation_status: 'pending',
                    service_provider: {
                        service_provider_name: 'Emma',
                        service_provider_surname: 'Thompson',
                        service_provider_rating: 4.9,
                        service_provider_location: 'Sandton'
                    }
                }
            ]
        }
    ];
    
    let totalQuotations = 0;
    
    sampleJobCarts.forEach(jobCart => {
        totalQuotations += jobCart.quotations.length;
        
        const jobCartSection = document.createElement('div');
        jobCartSection.className = 'job-cart-section';
        jobCartSection.innerHTML = `
            <div class="service-header">
                <h3><i class="fas fa-cog me-2"></i>${jobCart.job_cart_item}</h3>
                <p class="job-cart-details">${jobCart.job_cart_details}</p>
                <div class="service-info">
                    <span class="service-badge">${jobCart.quotations.length} quotation${jobCart.quotations.length !== 1 ? 's' : ''} available</span>
                    <span class="selection-note">Select one quotation for this service</span>
                </div>
            </div>
            <div class="quotations-grid" data-job-cart-id="${jobCart.job_cart_id}" data-service="${jobCart.job_cart_item}">
                ${jobCart.quotations.map((quotation, index) => createQuotationCard(quotation, jobCart.job_cart_item, index)).join('')}
            </div>
        `;
        
        quotationsList.appendChild(jobCartSection);
    });
    
    quotationCount.textContent = `${totalQuotations} sample quotation${totalQuotations !== 1 ? 's' : ''} available (for testing)`;
    quotationsContainer.style.display = 'block';
    
    // Add sample data indicator
    const sampleIndicator = document.createElement('div');
    sampleIndicator.className = 'sample-data-indicator';
    sampleIndicator.innerHTML = `
        <div class="alert alert-info">
            <i class="fas fa-info-circle"></i>
            <strong>Sample Data:</strong> These are sample quotations for testing purposes. In a real scenario, these would be actual quotations from service providers.
        </div>
    `;
    quotationsContainer.insertBefore(sampleIndicator, quotationsContainer.firstChild);
    
    showMessage("Sample quotations loaded successfully!", "success");
}

// Show sample quotation details
function showSampleQuotationDetails(quotationId) {
    console.log('🎭 Showing sample quotation details for:', quotationId);
    
    // Sample quotation data
    const sampleQuotations = {
        'sample-quote-1': {
            quotation_id: 'sample-quote-1',
            quotation_price: 2500,
            quotation_details: 'Full-day photography coverage with 500+ edited photos and 2-hour highlight video',
            service_provider: {
                service_provider_name: 'Sarah',
                service_provider_surname: 'Johnson',
                service_provider_rating: 4.8,
                service_provider_location: 'Johannesburg'
            },
            job_cart: {
                job_cart_item: 'Photography & Videography'
            }
        },
        'sample-quote-2': {
            quotation_id: 'sample-quote-2',
            quotation_price: 3200,
            quotation_details: 'Premium photography package with drone footage and same-day preview',
            service_provider: {
                service_provider_name: 'Mike',
                service_provider_surname: 'Chen',
                service_provider_rating: 4.9,
                service_provider_location: 'Sandton'
            },
            job_cart: {
                job_cart_item: 'Photography & Videography'
            }
        },
        'sample-quote-3': {
            quotation_id: 'sample-quote-3',
            quotation_price: 1800,
            quotation_details: 'Essential photography package with 300+ photos and basic video',
            service_provider: {
                service_provider_name: 'Lisa',
                service_provider_surname: 'Williams',
                service_provider_rating: 4.7,
                service_provider_location: 'Pretoria'
            },
            job_cart: {
                job_cart_item: 'Photography & Videography'
            }
        },
        'sample-quote-4': {
            quotation_id: 'sample-quote-4',
            quotation_price: 1500,
            quotation_details: 'Buffet-style catering for 50 guests with vegetarian options',
            service_provider: {
                service_provider_name: 'Chef',
                service_provider_surname: 'Martinez',
                service_provider_rating: 4.6,
                service_provider_location: 'Johannesburg'
            },
            job_cart: {
                job_cart_item: 'Catering Services'
            }
        },
        'sample-quote-5': {
            quotation_id: 'sample-quote-5',
            quotation_price: 2200,
            quotation_details: 'Premium plated service with 3-course meal and professional waitstaff',
            service_provider: {
                service_provider_name: 'Emma',
                service_provider_surname: 'Thompson',
                service_provider_rating: 4.9,
                service_provider_location: 'Sandton'
            },
            job_cart: {
                job_cart_item: 'Catering Services'
            }
        }
    };
    
    const quotation = sampleQuotations[quotationId];
    if (!quotation) {
        console.error('Sample quotation not found:', quotationId);
        return;
    }
    
    const detailsContent = document.getElementById('selected-quotation-content');
    const detailsSection = document.getElementById('quotation-details');
    
    detailsContent.innerHTML = `
        <div class="quotation-detail-card">
            <div class="sample-data-badge">
                <i class="fas fa-flask"></i> Sample Data
            </div>
            <h4>${quotation.job_cart.job_cart_item}</h4>
            <p class="quotation-detail-description">${quotation.quotation_details}</p>
            
            <div class="quotation-detail-info">
                <div class="price-section">
                    <h5>Total Price</h5>
                    <div class="price-large">R ${quotation.quotation_price.toLocaleString()}</div>
                </div>
                
                <div class="provider-section">
                    <h5>Service Provider</h5>
                    <p><strong>${quotation.service_provider.service_provider_name} ${quotation.service_provider.service_provider_surname}</strong></p>
                    <p><i class="fas fa-star"></i> Rating: ${quotation.service_provider.service_provider_rating}</p>
                    <p><i class="fas fa-map-marker-alt"></i> ${quotation.service_provider.service_provider_location}</p>
                </div>
                
                <div class="submission-section">
                    <h5>Submission Details</h5>
                    <p><i class="fas fa-calendar"></i> Submitted: ${new Date().toLocaleDateString()}</p>
                    <p><i class="fas fa-clock"></i> Time: ${new Date().toLocaleTimeString()}</p>
                </div>
            </div>
        </div>
    `;
    
    detailsSection.style.display = 'block';
    detailsSection.scrollIntoView({ behavior: 'smooth' });
}

// Show message to user
function showMessage(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 15px 20px;
        border-radius: 5px;
        color: white;
        font-weight: 500;
        z-index: 1000;
        max-width: 400px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
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

// Calculate and store payment total for payment page
async function calculateAndStorePaymentTotal() {
    try {
        const { data: acceptedQuotations, error } = await supabase
            .from('quotation')
            .select('quotation_price')
            .eq('quotation_status', 'accepted')
            .in('job_cart_id', await getClientJobCartIds());

        if (error) throw error;

        const subtotal = acceptedQuotations.reduce((sum, q) => sum + parseFloat(q.quotation_price), 0);
        const serviceFee = subtotal * 0.15;
        const grandTotal = subtotal + serviceFee;

        // Store payment details for payment page
        localStorage.setItem('paymentDetails', JSON.stringify({
            subtotal: subtotal,
            serviceFee: serviceFee,
            grandTotal: grandTotal,
            quotationCount: acceptedQuotations.length,
            timestamp: new Date().toISOString()
        }));

        console.log('💰 Payment details stored:', { subtotal, serviceFee, grandTotal });

    } catch (error) {
        console.error("Error calculating payment total:", error);
        showMessage("Error calculating payment total", "error");
    }
}

// Get client's job cart IDs
async function getClientJobCartIds() {
    const { data: jobCarts, error } = await supabase
        .from('job_cart')
        .select('job_cart_id')
        .eq('client_id', clientId);

    if (error) throw error;
    return jobCarts.map(cart => cart.job_cart_id);
}

// Event listeners
document.getElementById('accept-quotation')?.addEventListener('click', acceptQuotation);
document.getElementById('reject-quotation')?.addEventListener('click', rejectQuotation);
