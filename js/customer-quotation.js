// Customer Quotation Management System
// Handles viewing and selecting quotations from service providers

// Supabase configuration
const SUPABASE_URL = "https://spudtrptbyvwyhvistdf.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwdWR0cnB0Ynl2d3lodmlzdGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2OTk4NjgsImV4cCI6MjA3MTI3NTg2OH0.GBo-RtgbRZCmhSAZi0c5oXynMiJNeyrs0nLsk3CaV8A";
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

let selectedQuotations = {}; // Store multiple quotations: {service_id: quotation_id}
let clientId = null;
let allQuotations = []; // Store all quotations

// Initialize the quotation system
document.addEventListener('DOMContentLoaded', async function() {
    try {
        // No need to clear localStorage here - bookings.html handles this
        console.log('📋 Loading quotations with existing localStorage data...');

        // Check authentication using the actual login system
        const storedClientId = localStorage.getItem('clientId');
        const storedUserName = localStorage.getItem('userName');
        const storedUserType = localStorage.getItem('userType');
        
        if (!storedClientId || storedUserType !== 'client') {
            console.error("Authentication required - no client data found");
            showMessage("Please log in as a client to view quotations", "error");
            // Redirect to login page
            setTimeout(() => {
                window.location.href = 'Login.html';
            }, 2000);
            return;
        } else {
            clientId = storedClientId;
            console.log("User authenticated:", storedUserName);
            console.log("Using client ID:", clientId);
        }

        // Get stored service IDs from localStorage (set by bookings.html)
        const storedServiceIds = JSON.parse(localStorage.getItem('quotationServiceIds') || '[]');
        console.log('📋 Using stored service IDs:', storedServiceIds);
        console.log('🔍 All localStorage keys:', Object.keys(localStorage));
        console.log('🔍 quotationServiceIds raw:', localStorage.getItem('quotationServiceIds'));
        
        // Debug: Check what's in jobCartDetails
        const jobCartDetails = JSON.parse(localStorage.getItem('jobCartDetails') || '[]');
        console.log('🔍 jobCartDetails:', jobCartDetails);
        if (jobCartDetails.length > 0) {
            console.log('🔍 First job cart service_id:', jobCartDetails[0]?.service_id);
            console.log('🔍 All service_ids in jobCartDetails:', jobCartDetails.map(cart => cart.service_id));
        }

        await loadClientQuotations();
        setupRealtimeSubscriptions();
        setupContinueButton();
        
    } catch (error) {
        console.error("Error initializing quotation system:", error);
        showMessage("Error loading quotations", "error");
    }
});


// Load quotations for the logged-in client
async function loadClientQuotations() {
    try {
        showLoading(true);
        
        // NEW APPROACH: Fetch quotations directly from quotation table using service_id
        console.log('🔄 Fetching quotations from quotation table...');
        await loadQuotationsFromDatabase();
        
    } catch (error) {
        console.error("Error loading quotations:", error);
        showMessage("Error loading quotations", "error");
    } finally {
        showLoading(false);
    }
}

// NEW FUNCTION: Load quotations directly from quotation table
async function loadQuotationsFromDatabase() {
    try {
        // Get stored service IDs from localStorage (set by bookings.html)
        let serviceIds = JSON.parse(localStorage.getItem('quotationServiceIds') || '[]');
        console.log('📋 Using stored service IDs for quotation search:', serviceIds);
        console.log('📋 Service IDs type:', typeof serviceIds, 'Length:', serviceIds?.length);

        // Always use jobCartDetails as the source of truth for service IDs
        const jobCartDetails = JSON.parse(localStorage.getItem('jobCartDetails') || '[]');
        if (jobCartDetails.length > 0) {
            const correctServiceIds = jobCartDetails.map(cart => cart.service_id).filter(Boolean);
            console.log('📋 Using correct service IDs from jobCartDetails:', correctServiceIds);
            
            // Update quotationServiceIds with correct IDs
            localStorage.setItem('quotationServiceIds', JSON.stringify(correctServiceIds));
            serviceIds = correctServiceIds;
        }

        if (!serviceIds || serviceIds.length === 0) {
            console.log('No service IDs found in any storage location');
            console.log('🔍 Debug info - Client ID used:', clientId);
            showMessage('No services selected. Please go back to the booking process and select services first.', 'warning');
            return;
        }

        // Fetch quotations from quotation table using service_id
        console.log('🔍 About to query quotations with service IDs:', serviceIds);
        console.log('🔍 Query will search for quotation_status = "confirmed"');
        
        const { data: quotations, error: quotationError } = await supabase
            .from('quotation')
            .select(`
                quotation_id,
                service_id,
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
                    service_provider_email,
                    service_provider_rating,
                    service_provider_location
                ),
                service:service_id (
                    service_id,
                    service_name,
                    service_type
                )
            `)
            .in('service_id', serviceIds)
            .eq('quotation_status', 'confirmed')
            .order('quotation_submission_date', { ascending: false });
            
        console.log('🔍 Quotation query completed. Error:', quotationError);

        if (quotationError) throw quotationError;

        console.log('📊 Found quotations:', quotations?.length || 0);
        console.log('📋 Quotations data:', quotations);

        if (!quotations || quotations.length === 0) {
            console.log('No quotations found in database');
            console.log('🔍 Debug info - Service IDs we searched for:', serviceIds);
            showMessage('No quotations available for your selected services yet. Please check back later or contact support.', 'warning');
            return;
        }

        // Store all quotations for filtering
        allQuotations = quotations;

        // Group quotations by service
        const quotationsByService = {};
        quotations.forEach(quotation => {
            const serviceName = quotation.service?.service_name || 'Unknown Service';
            if (!quotationsByService[serviceName]) {
                quotationsByService[serviceName] = {
                    service_name: serviceName,
                    service_id: quotation.service_id,
                    quotations: []
                };
            }
            quotationsByService[serviceName].quotations.push(quotation);
        });

        // Filter to only show services that were selected during booking
        const selectedServiceIds = JSON.parse(localStorage.getItem('quotationServiceIds') || '[]');
        console.log('🎯 Filtering quotations for selected services:', selectedServiceIds);
        
        // Convert to array format expected by displayQuotations, filtered by selected services
        const jobCartsWithQuotations = Object.values(quotationsByService)
            .filter(serviceGroup => selectedServiceIds.includes(serviceGroup.service_id))
            .map(serviceGroup => ({
                job_cart_id: `service-${serviceGroup.service_id}`,
                job_cart_item: serviceGroup.service_name,
                job_cart_details: `Available quotations for ${serviceGroup.service_name} services`,
                quotations: serviceGroup.quotations.map(q => ({
                    quotation_id: q.quotation_id,
                    quotation_price: q.quotation_price,
                    quotation_details: q.quotation_details,
                    quotation_file_path: q.quotation_file_path,
                    quotation_file_name: q.quotation_file_name,
                    quotation_submission_date: q.quotation_submission_date,
                    quotation_submission_time: q.quotation_submission_time,
                    quotation_status: q.quotation_status,
                    service_id: q.service_id, // Include service_id in quotation data
                    service_provider: {
                        service_provider_id: q.service_provider?.service_provider_id,
                        service_provider_name: q.service_provider?.service_provider_name || 'Unknown',
                        service_provider_surname: q.service_provider?.service_provider_surname || '',
                        service_provider_rating: q.service_provider?.service_provider_rating || 4.5,
                        service_provider_location: q.service_provider?.service_provider_location || 'Johannesburg'
                    }
                }))
            }));
            
        console.log('📋 Filtered quotations for selected services:', jobCartsWithQuotations.length, 'service groups');

        displayQuotations(jobCartsWithQuotations);
        
    } catch (error) {
        console.error("Error loading quotations from database:", error);
        showMessage("Error loading quotations from database", "error");
    }
}

// COMMENTED OUT: Load quotations that were generated in the booking process
// This function is no longer used since we're fetching directly from quotation table
/*
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
*/

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
        <div class="quotation-card" data-quotation-id="${quotation.quotation_id}" data-service-id="${quotation.service_id}">
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

// Select a quotation for a specific service
function selectQuotation(quotationId) {
    console.log('🎯 Selecting quotation:', quotationId);
    
    // Get the service ID from the quotation card
    const selectedCard = document.querySelector(`[data-quotation-id="${quotationId}"]`);
    if (!selectedCard) {
        console.error('Quotation card not found for ID:', quotationId);
        return;
    }
    
    const serviceId = selectedCard.getAttribute('data-service-id');
    if (!serviceId) {
        console.error('No service ID found for quotation:', quotationId);
        return;
    }
    
    console.log('📋 Service ID found:', serviceId);
    
    // Remove selection from other quotations in the same service group
    const serviceGroup = selectedCard.closest('.service-group');
    if (serviceGroup) {
        serviceGroup.querySelectorAll('.quotation-card').forEach(card => {
            card.classList.remove('selected');
            // Enable all cards first
            card.style.opacity = '1';
            card.style.pointerEvents = 'auto';
            const selectBtn = card.querySelector('.btn-select');
            if (selectBtn) {
                selectBtn.disabled = false;
                selectBtn.textContent = 'Select This Quote';
            }
        });
    }
    
    // Select the current quotation
    selectedCard.classList.add('selected');
    
    // Disable other quotations in the same service group
    if (serviceGroup) {
        serviceGroup.querySelectorAll('.quotation-card:not(.selected)').forEach(card => {
            card.style.opacity = '0.6';
            card.style.pointerEvents = 'none';
            const selectBtn = card.querySelector('.btn-select');
            if (selectBtn) {
                selectBtn.disabled = true;
                selectBtn.textContent = 'Selected Another Quote';
            }
        });
    }
    
    // Store the selection: {service_id: quotation_id}
    selectedQuotations[serviceId] = quotationId;
    
    console.log('📋 Selected quotation for service:', serviceId, '→', quotationId);
    console.log('📋 All selected quotations:', selectedQuotations);
    
    // Store in localStorage for the summary page
    localStorage.setItem('selectedQuotations', JSON.stringify(selectedQuotations));
    
    // Show quotation details
    showQuotationDetails(quotationId);
    
    // Check if all services have quotations selected
    checkAllServicesSelected();
}

// Make selectQuotation globally accessible
window.selectQuotation = selectQuotation;

// Set up the continue button click handler (always available)
function setupContinueButton() {
    const continueBtn = document.getElementById('continueToSummaryBtn');
    if (continueBtn) {
        continueBtn.onclick = () => {
            const selectedCount = Object.keys(selectedQuotations).length;
            
            if (selectedCount === 0) {
                showMessage('Please select at least one quotation before continuing.', 'warning');
                return;
            }
            
            // Store selected quotations data for summary page
            const selectedQuotationData = [];
            const serviceIds = Object.keys(selectedQuotations);
            
            serviceIds.forEach(serviceId => {
                const quotationId = selectedQuotations[serviceId];
                const quotationCard = document.querySelector(`[data-quotation-id="${quotationId}"]`);
                if (quotationCard) {
                    const serviceGroup = quotationCard.closest('.service-group');
                    const serviceName = serviceGroup ? serviceGroup.querySelector('.service-title')?.textContent : 'Unknown Service';
                    const providerName = quotationCard.querySelector('h4')?.textContent || 'Unknown Provider';
                    const priceElement = quotationCard.querySelector('.amount');
                    const price = priceElement ? priceElement.textContent : '0';
                    const detailsElement = quotationCard.querySelector('.quotation-description p');
                    const details = detailsElement ? detailsElement.textContent : 'No details available';
                    
                    selectedQuotationData.push({
                        serviceId: serviceId,
                        serviceName: serviceName,
                        quotationId: quotationId,
                        providerName: providerName,
                        price: price,
                        details: details
                    });
                }
            });
            
            localStorage.setItem('selectedQuotationData', JSON.stringify(selectedQuotationData));
            window.location.href = 'summary.html';
        };
    }
}

// Check if all services have quotations selected (for feedback only)
function checkAllServicesSelected() {
    const storedServiceIds = JSON.parse(localStorage.getItem('quotationServiceIds') || '[]');
    const allSelected = storedServiceIds.length > 0 && storedServiceIds.every(serviceId => selectedQuotations[serviceId]);
    const hasAnySelections = Object.keys(selectedQuotations).length > 0;
    
    if (hasAnySelections) {
        showMessage('Quotation selected! You can continue to the summary.', 'success');
    }
}

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

// View quotation file from URL (NEW FUNCTION)
function viewQuotationFileFromUrl(fileUrl) {
    try {
        if (fileUrl) {
            // If it's already a full URL, open it directly
            if (fileUrl.startsWith('http')) {
                window.open(fileUrl, '_blank');
            } else {
                // If it's a file path, create a signed URL
                viewQuotationFile(fileUrl);
            }
        } else {
            showMessage("No file available for this quotation", "warning");
        }
    } catch (error) {
        console.error("Error viewing file from URL:", error);
        showMessage("Error viewing file", "error");
    }
}

// View quotation file (UPDATED FUNCTION)
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

// Sample quotation functions removed - system now only uses real database quotations

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
