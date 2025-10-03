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
            console.error("User not logged in:", authError);
            showMessage("Please log in to view quotations", "error");
            return;
        }

        clientId = user.id;
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
        
        const { data: jobCarts, error } = await supabase
            .from('job_cart')
            .select(`
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
            .eq('event.client_id', clientId)
            .eq('job_cart_status', 'in_progress');

        if (error) throw error;

        const jobCartsWithQuotations = jobCarts.filter(cart => 
            cart.quotations && cart.quotations.length > 0
        );

        if (jobCartsWithQuotations.length === 0) {
            showNoQuotations();
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
            <h3>${jobCart.job_cart_item}</h3>
            <p class="job-cart-details">${jobCart.job_cart_details}</p>
            <div class="quotations-grid" data-job-cart-id="${jobCart.job_cart_id}">
                ${jobCart.quotations.map(quotation => createQuotationCard(quotation)).join('')}
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
    showQuotationDetails(quotationId);
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

// Event listeners
document.getElementById('accept-quotation')?.addEventListener('click', acceptQuotation);
document.getElementById('reject-quotation')?.addEventListener('click', rejectQuotation);
