// Quotation Filtering System
// This file provides functions to filter quotations by location and price range

/**
 * Filter quotations by event location and price range
 * @param {string} eventLocation - The event location to filter by
 * @param {number} minPrice - Minimum price in the range
 * @param {number} maxPrice - Maximum price in the range
 * @param {Array} serviceIds - Optional array of service IDs to filter by
 * @returns {Promise<Array>} Filtered quotations array
 */
async function getFilteredQuotations(eventLocation, minPrice = 0, maxPrice = 999999, serviceIds = null) {
    try {
        const { data, error } = await supabase.rpc('get_filtered_quotations', {
            p_event_location: eventLocation,
            p_min_price: minPrice,
            p_max_price: maxPrice,
            p_service_ids: serviceIds
        });

        if (error) throw error;
        return data || [];
    } catch (error) {
        console.error('Error filtering quotations:', error);
        throw error;
    }
}

/**
 * Get quotations using the view with location information
 * @param {string} eventLocation - The event location to filter by
 * @param {number} minPrice - Minimum price in the range
 * @param {number} maxPrice - Maximum price in the range
 * @returns {Promise<Array>} Filtered quotations array
 */
async function getQuotationsWithLocation(eventLocation, minPrice = 0, maxPrice = 999999) {
    try {
        let query = supabase
            .from('quotation_with_location')
            .select('*')
            .eq('quotation_status', 'confirmed')
            .gte('quotation_price', minPrice)
            .lte('quotation_price', maxPrice)
            .gte('quotation_submission_date', '2025-10-10')
            .lte('quotation_submission_date', '2025-10-12');

        // Add location filtering
        if (eventLocation) {
            query = query.or(`service_provider_location.ilike.%${eventLocation}%,event_location.ilike.%${eventLocation}%`);
        }

        const { data, error } = await query.order('service_name', { ascending: true })
                                          .order('quotation_price', { ascending: true });

        if (error) throw error;

        // Group by service and limit to 3 per service
        const groupedQuotations = {};
        data.forEach(quotation => {
            if (!groupedQuotations[quotation.service_name]) {
                groupedQuotations[quotation.service_name] = [];
            }
            if (groupedQuotations[quotation.service_name].length < 3) {
                groupedQuotations[quotation.service_name].push(quotation);
            }
        });

        // Flatten back to array
        return Object.values(groupedQuotations).flat();
    } catch (error) {
        console.error('Error getting quotations with location:', error);
        throw error;
    }
}

/**
 * Display filtered quotations in the UI
 * @param {string} eventLocation - The event location
 * @param {number} minPrice - Minimum price
 * @param {number} maxPrice - Maximum price
 * @param {string} containerId - ID of the container to display results
 */
async function displayFilteredQuotations(eventLocation, minPrice, maxPrice, containerId = 'quotations-container') {
    try {
        const container = document.getElementById(containerId);
        if (!container) {
            console.error('Container not found:', containerId);
            return;
        }

        // Show loading state
        container.innerHTML = `
            <div class="text-center py-4">
                <i class="fas fa-spinner fa-spin fa-2x text-muted"></i>
                <p class="text-muted mt-2">Filtering quotations...</p>
            </div>
        `;

        // Get filtered quotations
        const quotations = await getQuotationsWithLocation(eventLocation, minPrice, maxPrice);

        if (quotations.length === 0) {
            container.innerHTML = `
                <div class="text-center py-5">
                    <i class="fas fa-search fa-3x text-muted mb-3"></i>
                    <h5 class="text-muted">No Quotations Found</h5>
                    <p class="text-muted">No quotations match your criteria for location "${eventLocation}" and price range R${minPrice} - R${maxPrice}</p>
                    <button class="btn btn-outline-primary" onclick="adjustFilters()">
                        <i class="fas fa-adjust me-2"></i>Adjust Filters
                    </button>
                </div>
            `;
            return;
        }

        // Group quotations by service
        const groupedQuotations = {};
        quotations.forEach(quotation => {
            if (!groupedQuotations[quotation.service_name]) {
                groupedQuotations[quotation.service_name] = [];
            }
            groupedQuotations[quotation.service_name].push(quotation);
        });

        // Display grouped quotations
        let html = `
            <div class="mb-4">
                <h4>Filtered Quotations</h4>
                <p class="text-muted">
                    Found ${quotations.length} quotations for location "${eventLocation}" 
                    with price range R${minPrice} - R${maxPrice}
                </p>
            </div>
        `;

        Object.entries(groupedQuotations).forEach(([serviceName, serviceQuotations]) => {
            html += `
                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="mb-0">
                            <i class="fas fa-tag me-2"></i>${serviceName}
                            <span class="badge bg-primary ms-2">${serviceQuotations.length} quotations</span>
                        </h5>
                    </div>
                    <div class="card-body">
                        <div class="row">
            `;

            serviceQuotations.forEach(quotation => {
                html += `
                    <div class="col-md-4 mb-3">
                        <div class="card h-100">
                            <div class="card-body">
                                <h6 class="card-title">${quotation.service_provider_name}</h6>
                                <p class="card-text">
                                    <strong>Location:</strong> ${quotation.service_provider_location}<br>
                                    <strong>Price:</strong> R${quotation.quotation_price.toLocaleString()}<br>
                                    <strong>Rating:</strong> ${quotation.service_provider_rating}/5.0<br>
                                    <strong>Event:</strong> ${quotation.event_type}
                                </p>
                                <p class="text-muted small">${quotation.quotation_details}</p>
                                <div class="btn-group w-100">
                                    ${quotation.quotation_file_path ? `
                                        <button class="btn btn-outline-info btn-sm" onclick="previewQuotationFile('${quotation.quotation_file_path}', '${quotation.quotation_file_name}')">
                                            <i class="fas fa-eye me-1"></i>Preview
                                        </button>
                                        <button class="btn btn-outline-success btn-sm" onclick="downloadQuotationFile('${quotation.quotation_file_path}', '${quotation.quotation_file_name}')">
                                            <i class="fas fa-download me-1"></i>Download
                                        </button>
                                    ` : `
                                        <button class="btn btn-outline-secondary btn-sm" disabled>
                                            <i class="fas fa-file me-1"></i>No File
                                        </button>
                                    `}
                                    <button class="btn btn-primary btn-sm" onclick="selectQuotation('${quotation.quotation_id}')">
                                        <i class="fas fa-check me-1"></i>Select
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                `;
            });

            html += `
                        </div>
                    </div>
                </div>
            `;
        });

        container.innerHTML = html;

    } catch (error) {
        console.error('Error displaying filtered quotations:', error);
        container.innerHTML = `
            <div class="alert alert-danger">
                <i class="fas fa-exclamation-triangle me-2"></i>
                Error loading quotations: ${error.message}
            </div>
        `;
    }
}

/**
 * Preview quotation file
 * @param {string} filePath - Path to the quotation file
 * @param {string} fileName - Name of the file
 */
async function previewQuotationFile(filePath, fileName) {
    try {
        showNotification('Loading preview...', 'info');
        
        // For demo purposes, we'll use the actual PDF URL
        const pdfUrl = filePath.startsWith('http') ? filePath : `https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf`;
        
        // Open in new tab for preview
        window.open(pdfUrl, '_blank');

    } catch (error) {
        console.error('Error previewing file:', error);
        showNotification('Error previewing file: ' + error.message, 'error');
    }
}

/**
 * Download quotation file
 * @param {string} filePath - Path to the quotation file
 * @param {string} fileName - Name of the file
 */
async function downloadQuotationFile(filePath, fileName) {
    try {
        showNotification('Preparing download...', 'info');
        
        // For demo purposes, we'll use the actual PDF URL
        const pdfUrl = filePath.startsWith('http') ? filePath : `https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf`;
        
        // Create download link
        const link = document.createElement('a');
        link.href = pdfUrl;
        link.download = fileName || 'quotation.pdf';
        link.target = '_blank';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        showNotification('Download started!', 'success');

    } catch (error) {
        console.error('Error downloading file:', error);
        showNotification('Error downloading file: ' + error.message, 'error');
    }
}

/**
 * Select a quotation
 * @param {string} quotationId - ID of the quotation to select
 */
function selectQuotation(quotationId) {
    // Store selected quotation
    localStorage.setItem('selectedQuotationId', quotationId);
    
    showNotification('Quotation selected! Proceeding to booking...', 'success');
    
    // Redirect to booking confirmation or next step
    setTimeout(() => {
        window.location.href = 'confirmation.html';
    }, 1500);
}

/**
 * Adjust filters (placeholder function)
 */
function adjustFilters() {
    // This would open a modal or redirect to filter adjustment
    showNotification('Opening filter options...', 'info');
}

/**
 * Show notification
 * @param {string} message - Message to display
 * @param {string} type - Type of notification (success, error, info, warning)
 */
function showNotification(message, type = 'info') {
    // Create a simple notification
    const notification = document.createElement('div');
    notification.className = `alert alert-${type} alert-dismissible fade show position-fixed`;
    notification.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
    notification.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(notification);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.remove();
        }
    }, 5000);
}

// Example usage in HTML:
/*
// Filter quotations for Johannesburg events with price range R1000-R3000
displayFilteredQuotations('Johannesburg', 1000, 3000, 'quotations-container');

// Filter quotations for Cape Town events with any price
displayFilteredQuotations('Cape Town', 0, 999999, 'quotations-container');

// Filter quotations for specific services in Durban
const photographyServiceId = '81c4b860-1c88-4503-bbe8-a03ab14e771c';
const cateringServiceId = 'd4e5f6g7-h8i9-0123-def0-456789012345';
getFilteredQuotations('Durban', 500, 2000, [photographyServiceId, cateringServiceId])
    .then(quotations => {
        console.log('Filtered quotations:', quotations);
    });
*/
